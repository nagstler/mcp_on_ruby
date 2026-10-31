# frozen_string_literal: true

require "rails/generators"

module McpOnRuby
  module Generators
    # rails generate mcp_on_ruby:expose orders index show
    class ExposeGenerator < Rails::Generators::Base
      WRITE_ACTIONS = %w[create update destroy].freeze

      desc "Adds mcp_tool declarations for existing controller actions."

      argument :controller, type: :string, banner: "CONTROLLER", desc: "Controller path, e.g. orders or admin/orders"
      argument :actions, type: :array, banner: "ACTION ACTION", desc: "Actions to expose"

      def add_declarations
        unless File.exist?(File.join(destination_root, controller_file))
          raise Thor::Error, "#{controller_file} does not exist"
        end

        pending = actions.reject { |action| declared?(action) }
        return say_status(:identical, controller_file, :blue) if pending.empty?

        indent = "#{class_indent}  "
        inject_into_file controller_file, pending.map { |action| "#{indent}#{declaration(action)}\n" }.join,
                         after: class_line_pattern
      end

      private

      def controller_file
        "app/controllers/#{controller.underscore.delete_suffix("_controller")}_controller.rb"
      end

      def controller_class
        "#{controller.underscore.delete_suffix("_controller").camelize}Controller"
      end

      # Matches `class ReportsController` as well as `class Admin::ReportsController`.
      def class_line_pattern
        /^(?<indent>[ \t]*)class (?:\w+::)*#{controller_class.demodulize}\b.*\n/
      end

      def class_indent
        class_line = class_line_pattern.match(source)
        raise Thor::Error, "#{controller_class} not found in #{controller_file}" unless class_line

        class_line[:indent]
      end

      def source
        File.read(File.join(destination_root, controller_file))
      end

      def declared?(action)
        source.match?(/mcp_tool\s+:#{action}\b/)
      end

      def declaration(action)
        line = %(mcp_tool :#{action}, description: "#{description(action)}")
        WRITE_ACTIONS.include?(action) ? "#{line}, write: true" : line
      end

      def description(action)
        resource = controller.split("/").last.humanize(capitalize: false)
        record = resource.singularize
        article = record.match?(/\A[aeiou]/i) ? "an" : "a"
        {
          "index" => "List #{resource}",
          "show" => "Show one #{record} by id",
          "create" => "Create #{article} #{record}",
          "update" => "Update #{article} #{record}",
          "destroy" => "Delete #{article} #{record}"
        }.fetch(action) { "TODO: describe what #{action} does for the agent" }
      end
    end
  end
end
