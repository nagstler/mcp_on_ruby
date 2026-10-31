# frozen_string_literal: true

module McpOnRuby
  # Serves the app's tools over stdio for local agents (Claude Code, Claude Desktop, Cursor, …).
  #
  # Started by `bin/rails mcp:stdio`. Protocol frames go to the original stdout; anything else the
  # app prints, including loggers attached to STDOUT, is redirected to stderr so it cannot corrupt
  # the stream.
  module Stdio
    # The SDK's stdio transport, writing frames to a dedicated IO instead of $stdout.
    class Transport < MCP::Server::Transports::StdioTransport
      def initialize(server, output:)
        super(server)
        @output = output
      end

      def send_response(message)
        @output.puts(message.is_a?(String) ? message : JSON.generate(message))
        @output.flush
      end
    end

    module_function

    def run(configuration: McpOnRuby.configuration, factory: McpOnRuby.server_factory)
      output = $stdout.dup
      $stdout.reopen($stderr)

      context = CallContext.stdio(configuration)
      warn_without_identity(context)
      factory.served_specs # fail fast on invalid declarations
      Transport.new(factory.build(context), output:).open
    end

    def warn_without_identity(context)
      return if context.user || context.headers.any?

      warn "[mcp_on_ruby] No stdio identity configured; tools run unauthenticated. " \
           "Set config.stdio_user or config.stdio_headers in config/initializers/mcp_on_ruby.rb."
    end
  end
end
