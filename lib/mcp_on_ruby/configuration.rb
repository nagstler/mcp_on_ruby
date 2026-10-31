# frozen_string_literal: true

module McpOnRuby
  # Settings for the MCP endpoint, set in config/initializers/mcp_on_ruby.rb:
  #
  #   McpOnRuby.configure do |config|
  #     config.server_name  = "my-app"
  #     config.instructions = "Tools for managing orders."
  #   end
  class Configuration
    DEFAULT_TOOL_NAME = ->(controller_path, action) { "#{controller_path.tr("/", "_")}_#{action}" }

    # Name reported to MCP clients. Defaults to the Rails application name.
    attr_writer :server_name

    # Version reported to MCP clients.
    attr_accessor :server_version

    # Server-level guidance sent to agents when they connect.
    attr_accessor :instructions

    # Callable returning the user that `bin/rails mcp:stdio` sessions act as (Warden/Devise apps).
    attr_accessor :stdio_user

    # Callable returning extra request headers for `bin/rails mcp:stdio` sessions (token-based apps).
    attr_accessor :stdio_headers

    # Warden scope used to sign in `stdio_user`.
    attr_accessor :warden_scope

    # Set to false to hide and refuse every tool declared with `write: true`.
    attr_accessor :allow_writes

    # Additional MCP::Tool classes served alongside controller tools.
    attr_accessor :tools

    # Browser origins allowed to call the HTTP endpoint.
    attr_accessor :allowed_origins

    # Maximum size of an MCP request body, in bytes.
    attr_accessor :max_request_bytes

    # Builds a tool's default name from its controller path and action.
    attr_reader :tool_name

    def initialize
      @server_name = nil
      @server_version = nil
      @instructions = nil
      @stdio_user = nil
      @stdio_headers = nil
      @warden_scope = :user
      @allow_writes = true
      @tools = []
      @allowed_origins = []
      @max_request_bytes = 4 * 1024 * 1024
      @tool_name = DEFAULT_TOOL_NAME
    end

    def tool_name=(callable)
      raise ArgumentError, "tool_name must respond to #call" unless callable.respond_to?(:call)

      @tool_name = callable
    end

    def server_name
      @server_name || default_server_name
    end

    private

    def default_server_name
      return "rails-app" unless defined?(Rails) && Rails.application

      Rails.application.class.module_parent_name.underscore.dasherize
    end
  end
end
