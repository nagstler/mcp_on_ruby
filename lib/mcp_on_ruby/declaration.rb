# frozen_string_literal: true

module McpOnRuby
  # What a controller declared with `mcp_tool`, before it is matched to a route.
  class Declaration
    attr_reader :action, :description, :title, :name, :input_schema, :annotations

    def initialize(action:, description:, title: nil, name: nil, params: {}, write: false, annotations: {}, &)
      @action = action.to_s
      @description = description.to_s.strip
      @title = title
      @name = name&.to_s
      @write = write ? true : false
      @annotations = annotations.to_h.transform_keys(&:to_sym)
      @input_schema = Schema.build(params, &)

      raise ArgumentError, "mcp_tool :#{@action} needs a description" if @description.empty?
    end

    def write?
      @write
    end
  end
end
