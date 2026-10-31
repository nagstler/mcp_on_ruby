# frozen_string_literal: true

RSpec.describe McpOnRuby::CallContext do
  it "builds an HTTP context from the request env" do
    env = { "HTTP_AUTHORIZATION" => "Bearer x" }

    expect(described_class.http(env)).to have_attributes(transport: :http, origin_env: env, user: nil, headers: {})
  end

  it "resolves the stdio identity from the configuration once" do
    calls = 0
    configuration = McpOnRuby::Configuration.new.tap do |config|
      config.stdio_user = lambda do
        calls += 1
        :alice
      end
      config.stdio_headers = -> { { "Authorization" => "Bearer t" } }
    end

    context = described_class.stdio(configuration)

    expect(context).to have_attributes(transport: :stdio, user: :alice, headers: { "Authorization" => "Bearer t" })
    expect(calls).to eq(1)
  end

  it "has no identity when none is configured" do
    expect(described_class.stdio(McpOnRuby::Configuration.new)).to have_attributes(user: nil, headers: {})
  end
end
