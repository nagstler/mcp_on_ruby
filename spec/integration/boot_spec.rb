# frozen_string_literal: true

require "open3"

RSpec.describe "Booting an eager-loaded app" do
  def boot(script, env = {})
    Open3.capture3(
      { "RAILS_ENV" => "test", "EAGER_LOAD" => "1" }.merge(env),
      "bin/rails", "runner", script,
      chdir: File.expand_path("../dummy", __dir__)
    )
  end

  it "resolves every declared tool against the routes at boot" do
    stdout, stderr, status = boot("puts McpOnRuby.registry.tools.size")

    expect(status).to be_success, stderr
    expect(stdout.strip.to_i).to eq(McpOnRuby.registry.tools.size)
  end

  it "refuses to boot when a declaration has no route" do
    # The script never touches the registry, so a failure can only come from boot itself.
    stdout, stderr, status = boot("puts :booted", "MCP_BROKEN_DECLARATION" => "1")

    expect(status).not_to be_success
    expect(stdout).not_to include("booted")
    expect(stderr).to include("McpOnRuby::ConfigurationError")
      .and include("MisconfiguredController declares mcp_tool :archive, but no route points to")
  end
end
