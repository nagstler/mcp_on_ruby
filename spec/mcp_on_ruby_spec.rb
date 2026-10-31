# frozen_string_literal: true

RSpec.describe McpOnRuby do
  it "has a version number" do
    expect(McpOnRuby::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end

  it "loads the official MCP SDK" do
    expect(defined?(MCP::Server)).to eq("constant")
  end
end
