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
  end
end
