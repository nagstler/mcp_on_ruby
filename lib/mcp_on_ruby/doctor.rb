# frozen_string_literal: true

module McpOnRuby
  # Checks an app's MCP setup for `bin/rails mcp:doctor`.
  class Doctor
    Check = Struct.new(:status, :message)

    attr_reader :checks

    def initialize(app: Rails.application, registry: McpOnRuby.registry, configuration: McpOnRuby.configuration)
      @app = app
      @registry = registry
      @configuration = configuration
      @checks = []
    end

    def run
      check_mount
      specs = check_registry
      check_csrf(specs) if specs
      check_stdio_identity
      self
    end

    def ok?
      checks.none? { |check| check.status == :fail }
    end

    def report
      checks.map { |check| "#{check.status.to_s.upcase.ljust(4)}  #{check.message}" }.join("\n") << "\n"
    end

    private

    def pass(message) = checks << Check.new(:ok, message)
    def warn(message) = checks << Check.new(:warn, message)
    def fail(message) = checks << Check.new(:fail, message)

    def check_mount
      route = @app.routes.routes.find { |candidate| candidate.app.app == McpOnRuby::Engine }
      if route
        pass("Engine mounted at #{route.path.spec.to_s.delete_suffix("(.:format)")}")
      else
        warn('Engine is not mounted; add `mount McpOnRuby::Engine, at: "/mcp"` to config/routes.rb for HTTP clients')
      end
    end

    def check_registry
      specs = @registry.tools
      if specs.empty?
        warn("No tools are exposed yet; add `mcp_tool` declarations to your controllers")
      else
        writes = specs.count(&:write?)
        pass("#{specs.size} tools exposed (#{specs.size - writes} read-only, #{writes} write)")
      end
      specs
    rescue ConfigurationError => e
      fail(e.message)
      nil
    end

    def check_csrf(specs)
      controllers = specs.select(&:write?).map(&:controller).uniq.select { |controller| csrf_protected?(controller) }
      return if controllers.empty?

      warn("Write tools on #{controllers.map(&:name).join(", ")} run with CSRF protection. Token-authenticated " \
           "requests are unaffected; for cookie sessions add `skip_forgery_protection if: :mcp_request?`")
    end

    def csrf_protected?(controller)
      controller < ActionController::Base && controller.allow_forgery_protection &&
        controller._process_action_callbacks.any? { |callback| callback.filter == :verify_authenticity_token }
    end

    def check_stdio_identity
      if @configuration.stdio_user || @configuration.stdio_headers
        pass("stdio sessions have an identity (#{@configuration.stdio_user ? "stdio_user" : "stdio_headers"})")
      else
        warn("No stdio identity: set config.stdio_user or config.stdio_headers to use `bin/rails mcp:stdio`")
      end
    end
  end
end
