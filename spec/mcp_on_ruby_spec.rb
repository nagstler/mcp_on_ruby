# frozen_string_literal: true

RSpec.describe McpOnRuby do
  after { described_class.reset_configuration! }

  it "has a version number" do
    expect(McpOnRuby::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end

  it "loads the official MCP SDK" do
    expect(defined?(MCP::Server)).to eq("constant")
  end

  it "yields the configuration" do
    described_class.configure { |config| config.instructions = "Be careful." }
    expect(described_class.configuration.instructions).to eq("Be careful.")
  end

  it "resets the configuration" do
    described_class.configure { |config| config.allow_writes = false }
    described_class.reset_configuration!
    expect(described_class.configuration.allow_writes).to be(true)
  end
end
