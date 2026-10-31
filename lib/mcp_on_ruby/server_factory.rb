# frozen_string_literal: true

module McpOnRuby
  # Builds the official MCP::Server for one caller, serving the registry's tools.
  class ServerFactory
    CONTEXT_KEY = :mcp_on_ruby

    def initialize(registry: nil, configuration: nil, dispatcher: nil)
      @registry = registry
      @configuration = configuration
      @dispatcher = dispatcher
      @mutex = Mutex.new
    end

    # @param context [McpOnRuby::CallContext] who is calling; tools dispatch as this caller
    # @return [MCP::Server]
    def build(context)
      options = {
        name: configuration.server_name,
        instructions: configuration.instructions,
        tools: mcp_tools + Array(configuration.tools),
        server_context: { CONTEXT_KEY => context }
      }
      options[:version] = configuration.server_version if configuration.server_version
      MCP::Server.new(**options.compact)
    end

    # The tool specs currently served, honoring `allow_writes`.
    def served_specs
      specs = registry.tools
      configuration.allow_writes ? specs : specs.reject(&:write?)
    end

    private

    def registry
      @registry || McpOnRuby.registry
    end

    def configuration
      @configuration || McpOnRuby.configuration
    end

    def dispatcher
      @dispatcher ||= Dispatcher.new
    end

    # Tool classes are rebuilt only when the registry is (on boot and code reload).
    def mcp_tools
      specs = served_specs
      @mutex.synchronize do
        @cache = [specs, specs.map { |spec| spec.to_mcp_tool(handler) }] unless @cache&.first.equal?(specs)
        @cache.last
      end
    end

    def handler
      @handler ||= lambda do |spec, arguments, server_context|
        context = server_context && server_context[CONTEXT_KEY]
        raise Error, "tool #{spec.name} was called without a McpOnRuby::CallContext" unless context

        dispatcher.call(spec, arguments, context)
      end
    end
  end
end
