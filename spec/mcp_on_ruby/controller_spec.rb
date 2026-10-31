# frozen_string_literal: true

RSpec.describe McpOnRuby::Controller do
  let(:base_controller) do
    Class.new(ActionController::Base) do
      mcp_tool :index, description: "List widgets", params: { q: :string }
    end
  end

  it "is available in ActionController::Base and ActionController::API" do
    expect(ActionController::Base).to include(described_class)
    expect(ActionController::API).to include(described_class)
  end

  it "records declarations by action name" do
    declaration = base_controller.mcp_declarations.fetch("index")

    expect(declaration).to have_attributes(action: "index", description: "List widgets", write?: false)
    expect(declaration.input_schema[:properties]).to eq("q" => { type: "string" })
  end

  it "accepts a block for nested params" do
    controller = Class.new(ActionController::API) do
      mcp_tool :create, description: "Create a widget", write: true do
        param :widget, required: true do
          param :name, type: :string, required: true
        end
      end
    end

    expect(controller.mcp_declarations["create"].input_schema[:required]).to eq(["widget"])
  end

  it "inherits declarations without leaking subclass declarations upward" do
    child = Class.new(base_controller) { mcp_tool :show, description: "Show a widget" }

    expect(child.mcp_declarations.keys).to eq(%w[index show])
    expect(base_controller.mcp_declarations.keys).to eq(["index"])
  end

  it "lets a subclass redeclare an inherited action" do
    child = Class.new(base_controller) { mcp_tool :index, description: "Search widgets" }

    expect(child.mcp_declarations["index"].description).to eq("Search widgets")
  end

  it "requires a description" do
    expect { Class.new(ActionController::Base) { mcp_tool :index, description: " " } }
      .to raise_error(ArgumentError, /needs a description/)
  end

  it "keeps explicit names, titles and annotation overrides" do
    controller = Class.new(ActionController::Base) do
      mcp_tool :index, description: "List", name: "list_widgets", title: "List widgets",
                       annotations: { "open_world_hint" => true }
    end

    expect(controller.mcp_declarations["index"]).to have_attributes(
      name: "list_widgets", title: "List widgets", annotations: { open_world_hint: true }
    )
  end

  describe "#mcp_request?" do
    let(:controller) { base_controller.new }

    it "is false for regular requests" do
      controller.request = ActionDispatch::TestRequest.create
      expect(controller.mcp_request?).to be(false)
      expect(controller.mcp_tool_name).to be_nil
    end

    it "exposes the stdio user" do
      controller.request = ActionDispatch::TestRequest.create(McpOnRuby::USER_ENV_KEY => :alice)
      expect(controller.mcp_user).to eq(:alice)
    end

    it "is true for requests dispatched by a tool call" do
      controller.request = ActionDispatch::TestRequest.create(McpOnRuby::TOOL_ENV_KEY => "widgets_index")
      expect(controller.mcp_request?).to be(true)
      expect(controller.mcp_tool_name).to eq("widgets_index")
    end
  end
end
