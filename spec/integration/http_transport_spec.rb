# frozen_string_literal: true

RSpec.describe "MCP over Streamable HTTP" do
  it "initializes with the app's server name and the tools capability" do
    result = mcp_initialize.fetch("result")

    expect(result["serverInfo"]).to include("name" => "dummy")
    expect(result["capabilities"]).to have_key("tools")
  end

  it "sends configured instructions and version" do
    McpOnRuby.configure do |config|
      config.instructions = "Amounts are in cents."
      config.server_version = "3.2.1"
    end

    result = mcp_initialize.fetch("result")

    expect(result["instructions"]).to eq("Amounts are in cents.")
    expect(result["serverInfo"]["version"]).to eq("3.2.1")
  end

  it "lists exposed controller actions with schemas and annotations" do
    tools = mcp_request("tools/list").dig("result", "tools").index_by { _1["name"] }

    expect(tools.keys).to include("orders_index", "orders_show", "orders_create", "profiles_show")
    expect(tools["orders_show"]["inputSchema"]).to include("required" => ["id"])
    expect(tools["orders_index"]["annotations"]).to include("readOnlyHint" => true)
    expect(tools["orders_destroy"]["annotations"]).to include("destructiveHint" => true)
  end

  it "calls a tool as the user whose token came with the request" do
    result = mcp_call_tool("orders_index").fetch("result")

    expect(result["isError"]).to be(false)
    expect(result["structuredContent"].pluck("id")).to eq([1, 2])
    expect(mcp_call_tool("orders_index", {}, token: "bob-token").dig("result", "structuredContent").pluck("id"))
      .to eq([3])
  end

  it "returns authorization failures as tool errors" do
    result = mcp_call_tool("orders_show", { id: 3 }).fetch("result")

    expect(result["isError"]).to be(true)
    expect(result.dig("content", 0, "text")).to start_with("Not permitted (403)")
  end

  it "rejects arguments that do not match the schema before the controller runs" do
    result = mcp_call_tool("orders_index", { status: "lost" }).fetch("result")

    expect(result["isError"]).to be(true)
    expect(result.dig("content", 0, "text")).to include("Invalid arguments")
  end

  it "reports missing required arguments" do
    result = mcp_call_tool("orders_show").fetch("result")

    expect(result.dig("content", 0, "text")).to eq("Missing required arguments: id")
  end

  it "performs writes" do
    result = mcp_call_tool("orders_create", { order: { sku: "MUG-9", quantity: 2 } }).fetch("result")

    expect(result["structuredContent"]).to include("sku" => "MUG-9")
    expect(Order.all.map(&:sku)).to include("MUG-9")
  end

  it "hides and refuses write tools when writes are disabled" do
    McpOnRuby.configure { |config| config.allow_writes = false }

    names = mcp_request("tools/list").dig("result", "tools").pluck("name")

    expect(names).to include("orders_index")
    expect(names).not_to include("orders_create", "orders_update", "orders_destroy")
    expect(mcp_call_tool("orders_destroy", { id: 1 })["error"]).to include("data" => "Tool not found: orders_destroy")
    expect(Order.find(1)).not_to be_nil
  end

  it "serves extra MCP::Tool classes alongside controller tools" do
    ping = MCP::Tool.define(name: "ping", description: "Health check") { |**| MCP::Tool::Response.new([{ type: "text", text: "pong" }]) }
    McpOnRuby.configure { |config| config.tools = [ping] }

    expect(mcp_call_tool("ping").dig("result", "content", 0, "text")).to eq("pong")
  end

  it "rejects cross-origin browser requests" do
    response = mcp_post({ jsonrpc: "2.0", id: 1, method: "tools/list" },
                        headers: { "HTTP_ORIGIN" => "https://evil.example" })

    expect(response.status).to eq(403)
  end

  it "accepts allow-listed origins" do
    McpOnRuby.configure { |config| config.allowed_origins = ["https://app.example.com"] }

    response = mcp_post({ jsonrpc: "2.0", id: 1, method: "tools/list" },
                        headers: { "HTTP_ORIGIN" => "https://app.example.com" })

    expect(response.status).to eq(200)
  end

  it "rejects oversized requests" do
    McpOnRuby.configure { |config| config.max_request_bytes = 64 }

    expect(mcp_post({ jsonrpc: "2.0", id: 1, method: "tools/list", params: { pad: "x" * 100 } }).status).to eq(413)
  end

  describe "protocol edges" do
    it "accepts notifications without a response body" do
      expect(mcp_post({ jsonrpc: "2.0", method: "notifications/initialized" }).status).to eq(202)
    end

    it "rejects non-JSON content types" do
      response = mcp_post({ jsonrpc: "2.0", id: 1, method: "tools/list" }, headers: { "CONTENT_TYPE" => "text/plain" })

      expect(response.status).to eq(415)
    end

    it "answers malformed JSON with a parse error" do
      response = Rack::MockRequest.new(Rails.application).post(
        "/mcp", "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/json, text/event-stream",
                "HTTP_HOST" => "www.example.com", input: "{not json"
      )

      expect(response.status).to eq(400)
      expect(JSON.parse(response.body).dig("error", "code")).to eq(-32_700)
    end

    it "has no server-sent event stream to open" do
      response = Rack::MockRequest.new(Rails.application).get(
        "/mcp", "HTTP_HOST" => "www.example.com", "HTTP_ACCEPT" => "text/event-stream"
      )

      expect(response.status).to eq(405)
    end

    it "lets Rails host authorization reject unknown hosts" do
      expect(mcp_post({ jsonrpc: "2.0", id: 1, method: "tools/list" },
                      headers: { "HTTP_HOST" => "evil.example" }).status)
        .to eq(403)
    end
  end

  it "lists tools under a custom naming scheme" do
    McpOnRuby.configure { |config| config.tool_name = ->(path, action) { "#{action}_#{path.tr("/", "_")}" } }
    McpOnRuby.registry.reset!

    names = mcp_request("tools/list").dig("result", "tools").pluck("name")

    expect(names).to include("index_orders", "index_admin_reports")
    expect(mcp_call_tool("show_orders", { id: 1 }).dig("result", "structuredContent", "sku")).to eq("BOOK-1")
  end
end
