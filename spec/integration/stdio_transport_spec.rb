# frozen_string_literal: true

require "open3"

RSpec.describe "MCP over stdio" do
  let(:dummy_root) { File.expand_path("../dummy", __dir__) }

  def run_stdio(messages, env = {})
    input = messages.map { |message| JSON.generate(message) }.join("\n") << "\n"
    stdout, stderr, status = Open3.capture3(
      { "RAILS_ENV" => "test" }.merge(env), "bin/rails", "mcp:stdio", stdin_data: input, chdir: dummy_root
    )
    raise "mcp:stdio failed: #{stderr}" unless status.success?

    [stdout.lines.map { |line| JSON.parse(line) }, stderr]
  end

  def initialize_message
    { jsonrpc: "2.0", id: 0, method: "initialize",
      params: { protocolVersion: "2025-11-25", capabilities: {}, clientInfo: { name: "rspec", version: "1" } } }
  end

  def call_message(id, name, arguments = {})
    { jsonrpc: "2.0", id:, method: "tools/call", params: { name:, arguments: } }
  end

  it "acts as the configured stdio user and keeps app output off the protocol stream" do
    responses, stderr = run_stdio(
      [initialize_message, { jsonrpc: "2.0", method: "notifications/initialized" },
       call_message(1, "profiles_show"), call_message(2, "pages_noisy")],
      "MCP_USER" => "bob@example.com"
    )

    expect(responses.map { _1["id"] }).to eq([0, 1, 2])
    expect(responses[0].dig("result", "instructions")).to eq("Tools for the dummy shop.")
    expect(responses[1].dig("result", "structuredContent")).to eq("email" => "bob@example.com", "via_mcp" => true)
    expect(responses[2].dig("result", "structuredContent")).to eq("quiet" => true)
    expect(stderr).to include("noise from puts", "noise from $stdout", "noise from STDOUT")
  end

  it "sends configured headers for token-authenticated apps" do
    responses, = run_stdio([initialize_message, call_message(1, "orders_index")], "MCP_TOKEN" => "bob-token")

    expect(responses.last.dig("result", "structuredContent").pluck("id")).to eq([3])
  end

  it "warns when no identity is configured" do
    responses, stderr = run_stdio([initialize_message, call_message(1, "orders_index")])

    expect(stderr).to include("No stdio identity configured")
    expect(responses.last.dig("result", "isError")).to be(true)
  end
end
