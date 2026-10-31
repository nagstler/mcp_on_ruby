# frozen_string_literal: true

RSpec.describe McpOnRuby::Configuration do
  subject(:config) { described_class.new }

  it "has safe defaults" do
    expect(config).to have_attributes(
      allow_writes: true, tools: [], allowed_hosts: [], allowed_origins: [],
      warden_scope: :user, max_request_bytes: 4 * 1024 * 1024
    )
  end

  it "derives the server name from the Rails application" do
    expect(config.server_name).to eq("dummy")
  end

  it "prefers an explicit server name" do
    config.server_name = "acme"
    expect(config.server_name).to eq("acme")
  end

  it "names tools after the controller path and action" do
    expect(config.tool_name.call("admin/orders", "index")).to eq("admin_orders_index")
  end

  it "accepts a custom tool naming callable" do
    config.tool_name = ->(path, action) { "#{action}_#{path}" }
    expect(config.tool_name.call("orders", "show")).to eq("show_orders")
  end

  it "rejects a tool naming value that is not callable" do
    expect { config.tool_name = "orders" }.to raise_error(ArgumentError, /respond to #call/)
  end
end
