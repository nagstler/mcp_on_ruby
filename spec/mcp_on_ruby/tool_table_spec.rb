# frozen_string_literal: true

RSpec.describe McpOnRuby::ToolTable do
  let(:specs) { McpOnRuby.registry.tools.select { %w[orders_index orders_create].include?(_1.name) } }

  it "renders aligned columns" do
    expect(described_class.render(specs)).to eq(<<~TABLE)
      TOOL           ACTION                   VERB  PATH     ACCESS
      orders_create  OrdersController#create  POST  /orders  write
      orders_index   OrdersController#index   GET   /orders  read-only
    TABLE
  end

  it "marks write tools as disabled when writes are off" do
    configuration = McpOnRuby::Configuration.new.tap { _1.allow_writes = false }

    expect(described_class.render(specs, configuration:)).to include("write (disabled)")
  end

  it "explains what to do when nothing is exposed" do
    expect(described_class.render([])).to include("Add `mcp_tool` declarations")
  end
end
