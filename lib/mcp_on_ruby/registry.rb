# frozen_string_literal: true

module McpOnRuby
  # Matches `mcp_tool` declarations to the application's routes and validates them.
  #
  # Tools are resolved lazily and cached until #reset!, which the engine calls on every code reload.
  class Registry
    WRITE_VERB_PREFERENCE = %w[PATCH PUT POST DELETE].freeze

    # @param routes [ActionDispatch::Routing::RouteSet] defaults to the application's routes
    # @param configuration [McpOnRuby::Configuration] defaults to McpOnRuby.configuration
    # @param root [String, Pathname] only controllers defined under this directory are checked for
    #   declarations without a route; defaults to Rails.root
    def initialize(routes: nil, configuration: nil, root: nil)
      @routes = routes
      @configuration = configuration
      @root = root
      @mutex = Mutex.new
      @tools = nil
    end

    # All exposed tools, including write tools.
    def tools
      @tools || @mutex.synchronize { @tools ||= build }
    end

    def find(name)
      tools.find { |tool| tool.name == name }
    end

    def reset!
      @mutex.synchronize { @tools = nil }
    end

    private

    def routes
      @routes || Rails.application.routes
    end

    def configuration
      @configuration || McpOnRuby.configuration
    end

    def build
      tools = routed_actions.filter_map do |(controller, action), route_list|
        declaration = controller.mcp_declarations[action]
        build_tool(controller, declaration, route_list) if declaration
      end

      check_unrouted_declarations!(tools)
      check_unique_names!(tools)
      tools.sort_by(&:name).freeze
    end

    # { [controller_class, action] => [routes...] } for every routed controller action.
    def routed_actions
      routes.routes.each_with_object({}) do |route, actions|
        controller = controller_for(route)
        next unless controller

        (actions[[controller, route.defaults[:action].to_s]] ||= []) << route
      end
    end

    def controller_for(route)
      path = route.defaults[:controller]
      return unless path && route.defaults[:action]

      controller = "#{path.camelize}Controller".safe_constantize
      controller if controller.respond_to?(:mcp_declarations)
    end

    def build_tool(controller, declaration, route_list)
      route = pick_route(route_list)
      verb = verb_for(route)

      if !ToolSpec::READ_VERBS.include?(verb) && !declaration.write?
        raise ConfigurationError,
              "#{controller.name}##{declaration.action} is routed as #{verb}; " \
              "add `write: true` to its mcp_tool declaration to expose it"
      end

      ToolSpec.new(
        name: declaration.name || configuration.tool_name.call(controller.controller_path, declaration.action),
        controller:, action: declaration.action, verb:,
        path: route.path.spec.to_s.delete_suffix("(.:format)"),
        path_params: route.required_parts.map(&:to_s) - ["format"],
        declaration:
      )
    end

    # Prefers a read route; among write routes prefers PATCH over PUT, as Rails' resources do.
    def pick_route(route_list)
      route_list.min_by do |route|
        verb = verb_for(route)
        ToolSpec::READ_VERBS.include?(verb) ? -1 : WRITE_VERB_PREFERENCE.index(verb) || WRITE_VERB_PREFERENCE.size
      end
    end

    def verb_for(route)
      verbs = route.verb.to_s.split("|").map(&:upcase)
      return "GET" if verbs.empty? || verbs.include?("GET")

      verbs.first
    end

    def check_unrouted_declarations!(tools)
      exposed = tools.to_set { |tool| [tool.controller, tool.action] }

      declaring_controllers.each do |controller|
        controller.mcp_declarations.each_key do |action|
          next if exposed.include?([controller, action]) || inherited_and_routed_elsewhere?(controller, action, exposed)

          raise ConfigurationError,
                "#{controller.name} declares mcp_tool :#{action}, but no route points to #{controller.name}##{action}"
        end
      end
    end

    # Loaded controllers with declarations whose source lives in the application, not in gems or engines.
    def declaring_controllers
      root = (@root || Rails.root).to_s
      [ActionController::Base, ActionController::API].flat_map(&:descendants).select do |controller|
        next false unless controller.name && controller.mcp_declarations.any?

        Object.const_source_location(controller.name)&.first.to_s.start_with?(root)
      end
    end

    # Base controllers may declare tools that only their routed subclasses serve.
    def inherited_and_routed_elsewhere?(controller, action, exposed)
      exposed.any? { |klass, routed_action| routed_action == action && klass < controller }
    end

    def check_unique_names!(tools)
      tools.group_by(&:name).each do |name, duplicates|
        next if duplicates.one?

        actions = duplicates.map { |tool| "#{tool.controller.name}##{tool.action}" }.join(" and ")
        raise ConfigurationError,
              "tool name #{name.inspect} is used by #{actions}; pass name: to mcp_tool to disambiguate"
      end
    end
  end
end
