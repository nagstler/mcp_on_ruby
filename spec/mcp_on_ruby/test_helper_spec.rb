# frozen_string_literal: true

require "mcp_on_ruby/rspec"

RSpec.describe McpOnRuby::TestHelper do
  let(:alice_token) { { "Authorization" => "Bearer alice-token" } }

  it "is included in example groups by mcp_on_ruby/rspec" do
    expect(self).to respond_to(:mcp_call)
  end

  it "calls tools with request headers" do
    result = mcp_call(:orders_index, { status: "paid" }, headers: alice_token)

    expect(result).to be_success
    expect(result.structured.pluck("sku")).to eq(["PEN-2"])
    expect(result.status).to be_nil
  end

  it "signs in a user through Warden" do
    result = mcp_call(:profiles_show, as: User.find_by(id: 2))

    expect(result.structured).to include("email" => "bob@example.com")
  end

  it "reports authorization failures with their status" do
    result = mcp_call(:orders_show, { id: 3 }, headers: alice_token)

    expect(result).to be_error
    expect(result.status).to eq(403)
    expect(result.text).to start_with("Not permitted (403)")
  end

  it "reports protocol errors such as unknown tools" do
    result = mcp_call(:orders_ship)

    expect(result).to be_error
    expect(result.protocol_error).to eq("Tool not found: orders_ship")
  end

  it "reports schema violations as protocol errors" do
    result = mcp_call(:orders_index, { status: "lost" }, headers: alice_token)

    expect(result).to be_error
    expect(result.text).to include("Invalid arguments")
  end

  it "lists visible tools" do
    McpOnRuby.configure { |config| config.allow_writes = false }

    expect(mcp_tools).to include("orders_index")
    expect(mcp_tools).not_to include("orders_create")
  end

  it "has a readable inspect" do
    expect(mcp_call(:pages_text).inspect).to eq('#<McpOnRuby::TestHelper::Result success "pong">')
  end
end
