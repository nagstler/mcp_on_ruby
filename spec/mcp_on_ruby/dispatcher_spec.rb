# frozen_string_literal: true

RSpec.describe McpOnRuby::Dispatcher do
  subject(:dispatcher) { described_class.new }

  let(:alice) { McpOnRuby::CallContext.http("HTTP_AUTHORIZATION" => "Bearer alice-token", "HTTP_HOST" => "www.example.com") }
  let(:anonymous) { McpOnRuby::CallContext.http("HTTP_HOST" => "www.example.com") }

  def call(tool, arguments = {}, context = alice)
    dispatcher.call(McpOnRuby.registry.find(tool), arguments, context)
  end

  def text(response)
    response.content.first[:text]
  end

  describe "read tools" do
    it "runs the controller as the forwarded user and returns structured JSON" do
      response = call("orders_index")

      expect(response.error?).to be(false)
      expect(response.structured_content.pluck("id")).to eq([1, 2])
      expect(JSON.parse(text(response))).to eq(response.structured_content)
    end

    it "sends arguments as query params" do
      response = call("orders_index", { status: "paid" })

      expect(response.structured_content.pluck("sku")).to eq(["PEN-2"])
    end

    it "fills path params from arguments" do
      expect(call("orders_show", { id: 2 }).structured_content).to include("sku" => "PEN-2")
    end
  end

  describe "write tools" do
    it "sends arguments as a JSON body" do
      response = call("orders_create", { order: { sku: "MUG-9", quantity: 2 } })

      expect(response.structured_content).to include("sku" => "MUG-9", "quantity" => 2, "user_id" => 1)
      expect(Order.all.last.sku).to eq("MUG-9")
    end

    it "combines path params and body params" do
      call("orders_update", { id: 1, status: "paid" })

      expect(Order.find(1).status).to eq("paid")
    end

    it "reports empty successful responses" do
      response = call("orders_destroy", { id: 1 })

      expect(text(response)).to eq("Success (204), no content")
      expect(Order.find(1)).to be_nil
    end
  end

  describe "CSRF protection" do
    it "lets dispatched writes through controllers that verify authenticity tokens" do
      response = call("notes_create", { body: "hello" })

      expect(response.error?).to be(false)
      expect(response.structured_content).to eq("body" => "hello")
    end

    it "still protects the same action from regular requests" do
      response = Rack::MockRequest.new(Rails.application).post(
        "/notes", "HTTP_HOST" => "www.example.com", "CONTENT_TYPE" => "application/json", input: "{}"
      )

      expect(response.status).to eq(422)
    end
  end

  describe "errors from the app" do
    it "maps 401 to a not-authenticated tool error" do
      response = call("orders_index", {}, anonymous)

      expect(response.error?).to be(true)
      expect(text(response)).to eq('Not authenticated (401): {"error":"unauthenticated"}')
      expect(response.structured_content).to eq("status" => 401, "body" => { "error" => "unauthenticated" })
    end

    it "maps 403 from the app's own authorization" do
      expect(text(call("orders_show", { id: 3 }))).to start_with("Not permitted (403)")
    end

    it "maps 404" do
      expect(text(call("orders_show", { id: 99 }))).to start_with("Not found (404)")
    end

    it "passes validation messages through so the agent can correct itself" do
      response = call("orders_create", { order: { sku: "", quantity: 0 } })

      expect(text(response)).to eq(
        'Unprocessable (422): {"errors":["sku can\'t be blank","quantity must be greater than 0"]}'
      )
    end

    it "does not follow redirects" do
      expect(text(call("pages_moved")))
        .to eq("Redirected to http://www.example.com/elsewhere; redirects are not followed")
    end

    it "rejects HTML responses" do
      response = call("pages_html")

      expect(response.error?).to be(true)
      expect(text(response)).to eq("The action responded with HTML; render JSON for MCP tools")
    end

    it "returns plain text as text" do
      expect(text(call("pages_text"))).to eq("pong")
    end

    it "hides exception details and reports them to Rails.error" do
      reported = []
      subscriber = Class.new { define_method(:report) { |error, **| reported << error } }.new
      Rails.error.subscribe(subscriber)

      response = call("pages_crash")

      expect(text(response)).to eq("Internal server error (500)")
      expect(reported.map(&:message)).to eq(["boom"])
    ensure
      Rails.error.unsubscribe(subscriber) if Rails.error.respond_to?(:unsubscribe)
    end
  end

  it "turns exceptions raised outside the app's exception handling into a generic error" do
    allow(Rails.application).to receive(:call).and_raise(RuntimeError, "database is down")

    response = call("orders_index")

    expect(response.error?).to be(true)
    expect(text(response)).to eq("Internal server error (500)")
  end

  describe "identity" do
    it "marks the request as an MCP request for the controller" do
      context = McpOnRuby::CallContext.new(transport: :stdio, user: User.find_by(id: 1))

      expect(call("profiles_show", {},
                  context).structured_content).to eq("email" => "alice@example.com", "via_mcp" => true)
    end

    it "signs in the stdio user through Warden without a session" do
      context = McpOnRuby::CallContext.new(transport: :stdio, user: User.find_by(id: 2))

      expect(call("profiles_show", {}, context).structured_content["email"]).to eq("bob@example.com")
    end

    it "sends configured headers for stdio sessions" do
      context = McpOnRuby::CallContext.new(transport: :stdio, headers: { "Authorization" => "Bearer bob-token" })

      expect(call("orders_index", {}, context).structured_content.pluck("id")).to eq([3])
    end

    it "ignores user headers that try to impersonate the stdio user" do
      context = McpOnRuby::CallContext.http("HTTP_MCP_ON_RUBY_USER" => "alice", "HTTP_HOST" => "www.example.com")

      expect(text(call("profiles_show", {}, context))).to start_with("Not authenticated (401)")
    end
  end

  it "instruments each call" do
    events = []
    callback = ->(*args) { events << ActiveSupport::Notifications::Event.new(*args) }

    ActiveSupport::Notifications.subscribed(callback, "tool_call.mcp_on_ruby") { call("orders_show", { id: 3 }) }

    expect(events.first.payload).to include(tool: "orders_show", controller: "OrdersController", action: "show",
                                            transport: :http, status: 403, error: true)
  end
end
