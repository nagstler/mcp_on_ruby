# frozen_string_literal: true

module McpOnRuby
  # Who is calling and over which transport. Passed to tools through the MCP server context.
  class CallContext
    attr_reader :transport, :origin_env, :user, :headers

    # A call that arrived over HTTP; the client's credentials are forwarded from its request.
    def self.http(env)
      new(transport: :http, origin_env: env)
    end

    # A call from a local stdio session, acting as the configured user and headers.
    def self.stdio(configuration = McpOnRuby.configuration)
      new(
        transport: :stdio,
        user: configuration.stdio_user&.call,
        headers: configuration.stdio_headers&.call || {}
      )
    end

    def initialize(transport:, origin_env: nil, user: nil, headers: {})
      @transport = transport
      @origin_env = origin_env
      @user = user
      @headers = headers.to_h
    end
  end
end
