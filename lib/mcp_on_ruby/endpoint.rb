# frozen_string_literal: true

module McpOnRuby
  # The Rack app behind `mount McpOnRuby::Engine, at: "/mcp"`.
  #
  # Each request gets its own stateless Streamable HTTP transport and server, so tools run as the
  # caller whose credentials arrived with that request, and any process can serve any request.
  class Endpoint
    def initialize(factory: nil, configuration: nil)
      @factory = factory
      @configuration = configuration
    end

    def call(env)
      server = factory.build(CallContext.http(env))
      transport(server, Rack::Request.new(env)).call(env)
    end

    private

    def factory
      @factory || McpOnRuby.server_factory
    end

    def configuration
      @configuration || McpOnRuby.configuration
    end

    # Rails' host authorization has already accepted this request's Host, so the transport only needs
    # to enforce the Origin check that protects local servers from malicious web pages.
    def transport(server, request)
      MCP::Server::Transports::StreamableHTTPTransport.new(
        server,
        stateless: true,
        enable_json_response: true,
        serve_subscriptions_listen: false,
        allowed_hosts: [request.host, request.host_with_port].uniq,
        allowed_origins: configuration.allowed_origins,
        max_request_bytes: configuration.max_request_bytes
      )
    end
  end
end
