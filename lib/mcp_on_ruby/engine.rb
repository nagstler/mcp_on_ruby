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

    # Fail at boot, not on the first agent request, when declarations do not match routes.
    config.after_initialize do |app|
      McpOnRuby::WardenHook.install!
      McpOnRuby.registry.tools if app.config.eager_load
    end
  end
end
