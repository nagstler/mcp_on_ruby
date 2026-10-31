# frozen_string_literal: true

module McpOnRuby
  # Renders the exposed tools as a table for `bin/rails mcp:tools`.
  module ToolTable
    HEADERS = %w[TOOL ACTION VERB PATH ACCESS].freeze

    module_function

    def render(specs, configuration: McpOnRuby.configuration)
      return "No tools are exposed. Add `mcp_tool` declarations to your controllers.\n" if specs.empty?

      rows = specs.map do |spec|
        [spec.name, "#{spec.controller.name}##{spec.action}", spec.verb, spec.path, access(spec, configuration)]
      end
      widths = HEADERS.each_index.map { |index| ([HEADERS] + rows).map { |row| row[index].length }.max }

      ([HEADERS] + rows).map { |row| format_row(row, widths) }.join("\n") << "\n"
    end

    def access(spec, configuration)
      return "read-only" unless spec.write?

      configuration.allow_writes ? "write" : "write (disabled)"
    end

    def format_row(row, widths)
      row.each_with_index.map { |cell, index| cell.ljust(widths[index]) }.join("  ").rstrip
    end
  end
end
