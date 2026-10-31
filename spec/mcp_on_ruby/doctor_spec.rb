# frozen_string_literal: true

RSpec.describe McpOnRuby::Doctor do
  let(:configuration) { McpOnRuby::Configuration.new }

  def doctor(**options)
    described_class.new(configuration:, **options).run
  end

  it "passes a correctly configured app and reports what it found" do
    configuration.stdio_user = -> {}
    result = doctor

    expect(result).to be_ok
    expect(result.report).to include("OK    Engine mounted at /mcp", "11 tools exposed (8 read-only, 3 write)",
                                     "stdio sessions have an identity (stdio_user)")
  end

  it "warns when stdio has no identity" do
    expect(doctor.report).to include("WARN  No stdio identity")
  end

  it "fails when declarations are invalid" do
    registry = instance_double(McpOnRuby::Registry)
    allow(registry).to receive(:tools).and_raise(McpOnRuby::ConfigurationError, "OrdersController#ship has no route")

    result = doctor(registry:)

    expect(result).not_to be_ok
    expect(result.report).to include("FAIL  OrdersController#ship has no route")
  end

  it "warns when no tools are exposed" do
    registry = instance_double(McpOnRuby::Registry, tools: [])

    expect(doctor(registry:).report).to include("WARN  No tools are exposed yet")
  end

  it "warns when the engine is not mounted" do
    app = instance_double(Rails::Application, routes: ActionDispatch::Routing::RouteSet.new)

    expect(doctor(app:, registry: instance_double(McpOnRuby::Registry, tools: [])).report)
      .to include("WARN  Engine is not mounted")
  end

  it "warns about CSRF for write tools on session controllers" do
    controller = Class.new(ActionController::Base) do
      def self.name = "SessionOrdersController"
      protect_from_forgery with: :exception
    end
    spec = instance_double(McpOnRuby::ToolSpec, write?: true, controller:)
    registry = instance_double(McpOnRuby::Registry, tools: [spec])
    allow(controller).to receive(:allow_forgery_protection).and_return(true)

    expect(doctor(registry:).report).to include("WARN  Write tools on SessionOrdersController run with CSRF protection")
  end
end
