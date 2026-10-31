# frozen_string_literal: true

require "mcp"
require "active_support"
require "active_support/core_ext"
require "mcp_on_ruby/version"

# MCP on Ruby exposes Rails controller actions as Model Context Protocol tools.
module McpOnRuby
  class Error < StandardError; end

  # Raised when tool declarations cannot be served, for example a typo in an action name.
  class ConfigurationError < Error; end

  # Rack env key set on requests dispatched by an MCP tool call; holds the tool name.
  TOOL_ENV_KEY = "mcp_on_ruby.tool"

  # Rack env key holding the user a local (stdio) session acts as.
  USER_ENV_KEY = "mcp_on_ruby.user"

  autoload :CallContext, "mcp_on_ruby/call_context"
  autoload :Configuration, "mcp_on_ruby/configuration"
  autoload :Controller, "mcp_on_ruby/controller"
  autoload :Declaration, "mcp_on_ruby/declaration"
  autoload :Dispatcher, "mcp_on_ruby/dispatcher"
  autoload :Endpoint, "mcp_on_ruby/endpoint"
  autoload :Registry, "mcp_on_ruby/registry"
  autoload :Result, "mcp_on_ruby/result"
  autoload :Schema, "mcp_on_ruby/schema"
  autoload :ServerFactory, "mcp_on_ruby/server_factory"
  autoload :ToolSpec, "mcp_on_ruby/tool_spec"
  autoload :WardenHook, "mcp_on_ruby/warden_hook"

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    # The tools exposed by the running application.
    def registry
      @registry ||= Registry.new
    end

    # Builds MCP servers for HTTP requests and stdio sessions.
    def server_factory
      @server_factory ||= ServerFactory.new
    end

    def configure
      yield configuration
    end

    # Restores the default configuration. Intended for tests.
    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

require "mcp_on_ruby/engine" if defined?(Rails::Engine)
