# frozen_string_literal: true

require "rails/generators"

module McpOnRuby
  module Generators
    # rails generate mcp_on_ruby:expose orders index show
    class ExposeGenerator < Rails::Generators::Base
      WRITE_ACTIONS = %w[create update destroy].freeze
      PARAM_ACTIONS = %w[create update].freeze
      SKIPPED_COLUMNS = %w[created_at updated_at].freeze

      COLUMN_TYPES = {
        integer: "type: :integer", bigint: "type: :integer",
        decimal: "type: :number", float: "type: :number",
        boolean: "type: :boolean",
        date: 'type: :string, format: "date"',
        datetime: 'type: :string, format: "date-time"', timestamp: 'type: :string, format: "date-time"',
        json: "type: :object", jsonb: "type: :object"
      }.freeze

      desc "Adds mcp_tool declarations for existing controller actions."

      argument :controller, type: :string, banner: "CONTROLLER", desc: "Controller path, e.g. orders or admin/orders"
      argument :actions, type: :array, banner: "ACTION ACTION", desc: "Actions to expose"

      def add_declarations
        unless File.exist?(File.join(destination_root, controller_file))
          raise Thor::Error, "#{controller_file} does not exist"
        end

        pending = actions.reject { |action| declared?(action) }
        return say_status(:identical, controller_file, :blue) if pending.empty?

        inject_into_file controller_file, declarations(pending), after: class_line_pattern
      end

      private

      def declarations(pending)
        indent = "#{class_line[:indent]}  "
        text = pending.map { |action| declaration(action).gsub(/^/, indent) }.join
        following_line = source[class_line.end(0)..].lines.first.to_s.strip
        following_line.empty? || following_line == "end" ? text : "#{text}\n"
      end

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

      def class_line
        @class_line ||= class_line_pattern.match(source) ||
                        raise(Thor::Error, "#{controller_class} not found in #{controller_file}")
      end

      def source
        File.read(File.join(destination_root, controller_file))
      end

      def declared?(action)
        source.match?(/mcp_tool\s+:#{action}\b/)
      end

      def declaration(action)
        line = %(mcp_tool :#{action}, description: "#{description(action)}")
        line += ", write: true" if WRITE_ACTIONS.include?(action)
        params = PARAM_ACTIONS.include?(action) ? model_params : nil
        params ? "#{line} do\n#{params}end\n" : "#{line}\n"
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

      # A params block built from the model's columns, when the controller has an ActiveRecord model.
      def model_params
        model = controller.split("/").last.classify.safe_constantize
        return unless model.respond_to?(:columns_hash)

        columns = model.columns_hash.except(model.primary_key, *SKIPPED_COLUMNS)
        return if columns.empty?

        lines = columns.map do |name, column|
          "    param :#{name}, #{COLUMN_TYPES.fetch(column.type, "type: :string")}\n"
        end
        "  param :#{model.model_name.param_key}, required: true do\n#{lines.join}  end\n"
      end
    end
  end
end
