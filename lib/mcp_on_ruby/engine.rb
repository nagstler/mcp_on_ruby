# frozen_string_literal: true

require "rails/engine"

module McpOnRuby
  # Mount in config/routes.rb:
  #
  #   mount McpOnRuby::Engine, at: "/mcp"
  class Engine < ::Rails::Engine
    isolate_namespace McpOnRuby

    initializer "mcp_on_ruby.controller" do
      ActiveSupport.on_load(:action_controller) do
        include McpOnRuby::Controller
      end
    end

    # Controllers and routes can change on reload; resolve tools again on next use.
    config.to_prepare do
      McpOnRuby.registry.reset!
    end

    config.after_initialize do
      McpOnRuby::WardenHook.install!
    end

    # Fail at boot, not on the first agent request, when declarations do not match routes.
    # Rails runs after_initialize before it loads routes, so validate once routes are loaded,
    # which happens during boot (after eager loading) when eager_load is on.
    initializer "mcp_on_ruby.validate_declarations" do |app|
      app.config.after_routes_loaded { McpOnRuby.registry.tools } if app.config.eager_load
    end
  end
end
