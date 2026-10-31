# frozen_string_literal: true

require "rack/mock"

module McpOnRuby
  # Runs a tool call as an in-process request through the full Rails stack:
  # middleware, routes, filters, and the controller action itself.
  class Dispatcher
    # Headers copied from the MCP client's HTTP request so the app sees the same caller.
    FORWARDED_HEADERS = %w[
      HTTP_AUTHORIZATION HTTP_COOKIE HTTP_USER_AGENT HTTP_ACCEPT_LANGUAGE HTTP_X_REQUEST_ID
      HTTP_X_FORWARDED_FOR HTTP_X_FORWARDED_PROTO HTTP_X_FORWARDED_HOST REMOTE_ADDR
    ].freeze

    EVENT = "tool_call.mcp_on_ruby"

    def initialize(app: nil)
      @app = app
    end

    # @return [MCP::Tool::Response]
    def call(spec, arguments, context)
      payload = { tool: spec.name, controller: spec.controller.name, action: spec.action,
                  transport: context.transport }

      ActiveSupport::Notifications.instrument(EVENT, payload) do
        status, response = dispatch(spec, arguments, context)
        payload[:status] = status
        payload[:error] = response.error?
        response
      end
    end

    private

    def app
      @app || Rails.application
    end

    def dispatch(spec, arguments, context)
      status, headers, body = app.call(build_env(spec, arguments, context))
      [status, Result.from_rack(status, headers, body)]
    rescue StandardError => e
      Rails.error.report(e, handled: true, context: { mcp_tool: spec.name })
      [500, Result.internal_error]
    end

    def build_env(spec, arguments, context)
      arguments = arguments.deep_stringify_keys
      path_values = spec.path_params.to_h { |param| [param.to_sym, arguments.delete(param)] }
      read = ToolSpec::READ_VERBS.include?(spec.verb)
      path = path_for(spec, path_values.merge(read ? arguments.symbolize_keys : {}))

      host = host(context)
      env = Rack::MockRequest.env_for(
        "#{scheme(context)}://#{host}#{path}",
        method: spec.verb,
        input: read ? "" : JSON.generate(arguments),
        "CONTENT_TYPE" => "application/json",
        "HTTP_ACCEPT" => "application/json",
        "HTTP_HOST" => host
      )
      apply_identity(env, context)
      env[TOOL_ENV_KEY] = spec.name
      env
    end

    def path_for(spec, params)
      app.routes.path_for(controller: spec.controller_path, action: spec.action, **params)
    end

    def apply_identity(env, context)
      context.origin_env&.slice(*FORWARDED_HEADERS)&.each { |key, value| env[key] = value }
      context.headers.each { |name, value| env[rack_header(name)] = value.to_s }
      env[USER_ENV_KEY] = context.user if context.user
    end

    def rack_header(name)
      "HTTP_#{name.to_s.upcase.tr("-", "_")}"
    end

    def host(context)
      context.origin_env&.fetch("HTTP_HOST", nil) || local_host
    end

    # Host for stdio sessions: one the app's host authorization already accepts.
    def local_host
      app.routes.default_url_options[:host] ||
        app.config.hosts.find { |host| host.is_a?(String) && !host.start_with?(".") } ||
        "localhost"
    end

    def scheme(context)
      context.origin_env&.fetch("rack.url_scheme", nil) || "http"
    end
  end
end
