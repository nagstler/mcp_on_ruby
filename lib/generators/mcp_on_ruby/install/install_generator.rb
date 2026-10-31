# frozen_string_literal: true

require "rails/generators"

module McpOnRuby
  module Generators
    # rails generate mcp_on_ruby:install
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Adds the MCP on Ruby initializer and mounts the MCP endpoint at /mcp."

      class_option :path, type: :string, default: "/mcp", desc: "Where to mount the MCP endpoint"

      def create_initializer
        template "initializer.rb", "config/initializers/mcp_on_ruby.rb"
      end

      def mount_engine
        route %(mount McpOnRuby::Engine, at: "#{options[:path]}")
      end

      def show_next_steps
        say <<~MESSAGE

          MCP on Ruby is installed. Next:

            1. Expose actions:   bin/rails generate mcp_on_ruby:expose orders index show
            2. Review them:      bin/rails mcp:tools
            3. Check the setup:  bin/rails mcp:doctor
            4. Connect an agent: claude mcp add my-app -- bin/rails mcp:stdio

        MESSAGE
      end
    end
  end
end
