# frozen_string_literal: true

# Speaks MCP's Streamable HTTP transport to the dummy app, the way a real client does.
module McpHttp
  PROTOCOL_VERSION = "2025-11-25"

  def mcp_post(message, token: "alice-token", headers: {})
    env = {
      "CONTENT_TYPE" => "application/json",
      "HTTP_ACCEPT" => "application/json, text/event-stream",
      "HTTP_HOST" => "www.example.com",
      "HTTP_MCP_PROTOCOL_VERSION" => PROTOCOL_VERSION,
      method: "POST",
      input: JSON.generate(message)
    }
    env["HTTP_AUTHORIZATION"] = "Bearer #{token}" if token
    Rack::MockRequest.new(Rails.application).request("POST", "/mcp", env.merge(headers))
  end

  def mcp_request(method, params = {}, **)
    response = mcp_post({ jsonrpc: "2.0", id: 1, method:, params: }, **)
    JSON.parse(response.body)
  end

  def mcp_initialize(**)
    mcp_request(
      "initialize",
      { protocolVersion: PROTOCOL_VERSION, capabilities: {}, clientInfo: { name: "rspec", version: "1.0" } },
      **
    )
  end

  def mcp_call_tool(name, arguments = {}, **)
    mcp_request("tools/call", { name:, arguments: }, **)
  end
end

RSpec.configure do |config|
  config.include McpHttp
end
