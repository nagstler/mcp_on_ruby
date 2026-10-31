# frozen_string_literal: true

RSpec.describe McpOnRuby::Engine do
  it "resolves tools again after a code reload" do
    before_reload = McpOnRuby.registry.tools

    Rails.application.reloader.prepare!

    expect(McpOnRuby.registry.tools).not_to equal(before_reload)
    expect(McpOnRuby.registry.tools.map(&:name)).to eq(before_reload.map(&:name))
  end

  it "serves the endpoint at the mount path" do
    route = Rails.application.routes.routes.find { |candidate| candidate.app.app == described_class }

    expect(route.path.spec.to_s).to eq("/mcp")
  end
end
