# frozen_string_literal: true

RSpec.describe McpOnRuby::ServerFactory do
  subject(:factory) { described_class.new }

  let(:context) { McpOnRuby::CallContext.new(transport: :stdio) }

  def tool_classes(server)
    server.tools.values
  end

  it "reuses tool classes until the registry is reset" do
    first = tool_classes(factory.build(context))

    expect(tool_classes(factory.build(context))).to eq(first)

    McpOnRuby.registry.reset!
    expect(tool_classes(factory.build(context)).first).not_to equal(first.first)
  end

  it "passes the call context to tools through the server context" do
    server = factory.build(context)

    expect(server.server_context).to eq(mcp_on_ruby: context)
  end

  it "refuses to dispatch without a call context" do
    tool = tool_classes(factory.build(context)).find { _1.name_value == "orders_index" }

    expect { tool.call(server_context: nil) }.to raise_error(McpOnRuby::Error, /without a McpOnRuby::CallContext/)
  end
end
