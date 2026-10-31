# frozen_string_literal: true

RSpec.describe McpOnRuby::Registry do
  subject(:registry) { described_class.new(routes:, configuration:, root: fixtures_root) }

  # Only the "declarations without a route" example scans a directory for controllers.
  let(:fixtures_root) { File.expand_path("../fixtures/none", __dir__) }
  let(:configuration) do
    McpOnRuby::Configuration.new.tap do |config|
      config.tool_name = ->(path, action) { "#{path.delete_prefix("registry_fixtures/").tr("/", "_")}_#{action}" }
    end
  end
  let(:routes) { draw { resources :widgets } }

  def draw(&block)
    ActionDispatch::Routing::RouteSet.new.tap do |set|
      set.draw { scope(module: "registry_fixtures") { instance_exec(&block) } }
    end
  end

  def tool(name)
    registry.find(name) || raise("no tool #{name}")
  end

  it "exposes declared actions that have routes, sorted by name" do
    expect(registry.tools.map(&:name)).to eq(%w[widgets_create widgets_destroy widgets_index widgets_show
                                                widgets_update])
  end

  it "records the verb, path and controller for each tool" do
    expect(tool("widgets_show")).to have_attributes(
      controller: RegistryFixtures::WidgetsController, action: "show", verb: "GET", path: "/widgets/:id",
      path_params: ["id"]
    )
  end

  it "prefers PATCH for actions routed with both PATCH and PUT" do
    expect(tool("widgets_update").verb).to eq("PATCH")
  end

  it "adds path params to the input schema as required" do
    expect(tool("widgets_show").input_schema).to eq(
      type: "object",
      properties: { "id" => { type: %w[string integer], description: "The :id segment of /widgets/:id" } },
      required: ["id"]
    )
  end

  it "keeps declared params alongside path params" do
    schema = tool("widgets_create").input_schema

    expect(schema[:properties].keys).to eq(["name"])
    expect(schema[:required]).to eq(["name"])
  end

  it "omits required when nothing is required" do
    expect(tool("widgets_index").input_schema).to eq(type: "object", properties: { "q" => { type: "string" } })
  end

  describe "annotations" do
    it "marks GET tools as read-only" do
      expect(tool("widgets_index").annotations).to eq(
        open_world_hint: false, read_only_hint: true, destructive_hint: false, idempotent_hint: true
      )
    end

    it "marks POST tools as additive writes" do
      expect(tool("widgets_create").annotations).to include(read_only_hint: false, destructive_hint: false,
                                                            idempotent_hint: false)
    end

    it "marks PATCH tools as destructive and idempotent" do
      expect(tool("widgets_update").annotations).to include(destructive_hint: true, idempotent_hint: true)
    end

    it "applies declared overrides last" do
      expect(tool("widgets_destroy").annotations).to include(destructive_hint: false, read_only_hint: false)
    end
  end

  it "names namespaced controllers after their path" do
    registry = described_class.new(routes: draw { namespace(:admin) { resources :widgets, only: :index } },
                                   configuration:, root: fixtures_root)

    expect(registry.tools.map(&:name)).to eq(["admin_widgets_index"])
  end

  it "uses the configured tool naming" do
    configuration.tool_name = ->(path, action) { "#{action}.#{path.tr("/", ".")}" }

    expect(registry.tools.map(&:name)).to include("index.registry_fixtures.widgets")
  end

  it "serves inherited declarations from routed subclasses" do
    registry = described_class.new(routes: draw { resources :things, only: :index }, configuration:,
                                   root: fixtures_root)

    expect(registry.tools.map { [_1.name, _1.controller] }).to eq([["things_index", RegistryFixtures::ThingsController]])
  end

  it "rejects write routes declared without write: true" do
    registry = described_class.new(routes: draw { resources :gadgets, only: :create }, configuration:,
                                   root: fixtures_root)

    expect { registry.tools }.to raise_error(McpOnRuby::ConfigurationError, /routed as POST; add `write: true`/)
  end

  it "rejects duplicate tool names" do
    registry = described_class.new(routes: draw do
      resources :widgets, only: :index
      get "search", to: "search#query"
    end, configuration:, root: fixtures_root)

    expect { registry.tools }.to raise_error(McpOnRuby::ConfigurationError, /"widgets_index" is used by/)
  end

  it "rejects declarations without a route" do
    # Stays loaded afterwards; other registries never scan this directory.
    require_relative "../fixtures/unrouted/unrouted_controller"
    registry = described_class.new(routes:, configuration:, root: File.expand_path("../fixtures/unrouted", __dir__))

    expect { registry.tools }.to raise_error(McpOnRuby::ConfigurationError, /no route points to .*Unrouted.*#archive/)
  end

  it "ignores routes to controllers without declarations" do
    registry = described_class.new(routes: ActionDispatch::Routing::RouteSet.new.tap do |set|
      set.draw do
        get "up", to: proc { [200, {}, ["ok"]] }
        get "missing", to: "nonexistent#index"
      end
    end, configuration:, root: fixtures_root)

    expect(registry.tools).to eq([])
  end

  it "caches tools until reset" do
    first = registry.tools
    expect(registry.tools).to be(first)

    registry.reset!
    expect(registry.tools).not_to be(first)
  end

  it "builds MCP tool classes that forward calls to a handler" do
    handler = ->(spec, arguments, _context) { MCP::Tool::Response.new([{ type: "text", text: "#{spec.name} q=#{arguments[:q]}" }]) }
    mcp_tool = tool("widgets_index").to_mcp_tool(handler)

    expect(mcp_tool.to_h).to include(name: "widgets_index", description: "List widgets")
    expect(mcp_tool.call(q: "a", server_context: nil).content).to eq([{ type: "text", text: "widgets_index q=a" }])
  end
end
