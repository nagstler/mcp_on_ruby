# frozen_string_literal: true

module McpOnRuby
  # A declared action matched to its route: everything needed to list the tool and dispatch calls to it.
  class ToolSpec
    READ_VERBS = %w[GET HEAD].freeze

    HINTS = {
      "GET" => { read_only_hint: true, destructive_hint: false, idempotent_hint: true },
      "POST" => { read_only_hint: false, destructive_hint: false, idempotent_hint: false },
      "PUT" => { read_only_hint: false, destructive_hint: true, idempotent_hint: true },
      "PATCH" => { read_only_hint: false, destructive_hint: true, idempotent_hint: true },
      "DELETE" => { read_only_hint: false, destructive_hint: true, idempotent_hint: true }
    }.freeze

    attr_reader :name, :controller, :action, :verb, :path, :path_params, :declaration

    def initialize(name:, controller:, action:, verb:, path:, path_params:, declaration:)
      @name = name
      @controller = controller
      @action = action
      @verb = verb
      @path = path
      @path_params = path_params
      @declaration = declaration
    end

    def controller_path
      controller.controller_path
    end

    def description
      declaration.description
    end

    def title
      declaration.title
    end

    def write?
      declaration.write? || !READ_VERBS.include?(verb)
    end

    # The declared parameters plus the route's path parameters, which are always required.
    def input_schema
      @input_schema ||= begin
        schema = declaration.input_schema
        path_properties = path_params.to_h { |param| [param, path_param_schema(param)] }
        properties = path_properties.merge(schema[:properties])
        required = (path_params + schema.fetch(:required, [])).uniq

        { type: "object", properties: }.tap { |result| result[:required] = required if required.any? }
      end
    end

    def annotations
      hints = HINTS.fetch(READ_VERBS.include?(verb) ? "GET" : verb, HINTS["POST"])
      hints = hints.merge(read_only_hint: false) if write?
      { open_world_hint: false, title: }.compact.merge(hints).merge(declaration.annotations)
    end

    # Builds the MCP::Tool class served for this spec. Calls are forwarded to the handler.
    def to_mcp_tool(handler)
      spec = self
      Class.new(MCP::Tool) do
        tool_name spec.name
        title spec.title if spec.title
        description spec.description
        input_schema spec.input_schema
        annotations spec.annotations
        define_singleton_method(:call) do |server_context:, **arguments|
          handler.call(spec, arguments, server_context)
        end
      end
    end

    def to_s
      "#{name} (#{controller.name}##{action}, #{verb} #{path})"
    end

    private

    def path_param_schema(param)
      { anyOf: [{ type: "string" }, { type: "integer" }], description: "The :#{param} segment of #{path}" }
    end
  end
end
