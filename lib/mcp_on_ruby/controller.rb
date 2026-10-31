# frozen_string_literal: true

module McpOnRuby
  # Included into every Rails controller by the engine.
  #
  #   class OrdersController < ApplicationController
  #     mcp_tool :index, description: "Search orders", params: { status: :string }
  #     mcp_tool :update, description: "Update an order", write: true
  #   end
  module Controller
    extend ActiveSupport::Concern

    included do
      class_attribute :mcp_declarations, instance_accessor: false, default: {}.freeze
      helper_method :mcp_request? if respond_to?(:helper_method)
    end

    class_methods do
      # Exposes an action of this controller as an MCP tool.
      #
      # @param action [Symbol] the controller action
      # @param description [String] what the tool does, written for the agent
      # @param title [String] optional human-readable name
      # @param name [String] tool name; defaults to "<controller>_<action>"
      # @param params [Hash] parameter schema, see McpOnRuby::Schema
      # @param write [Boolean] required for actions routed with POST, PUT, PATCH, or DELETE
      # @param annotations [Hash] overrides for the hints derived from the HTTP verb
      def mcp_tool(action, **, &)
        declaration = Declaration.new(action:, **, &)
        self.mcp_declarations = mcp_declarations.merge(declaration.action => declaration).freeze
        declaration
      end
    end

    # True while this action is running because an MCP client called it.
    def mcp_request?
      request.env.key?(McpOnRuby::TOOL_ENV_KEY)
    end

    # The name of the MCP tool being called, or nil outside MCP requests.
    def mcp_tool_name
      request.env[McpOnRuby::TOOL_ENV_KEY]
    end

    # The user a local `bin/rails mcp:stdio` session acts as, from `config.stdio_user`.
    # Apps without Warden can use this in their own authentication filter.
    def mcp_user
      request.env[McpOnRuby::USER_ENV_KEY]
    end

    private

    # Requests dispatched by an MCP tool call pass CSRF verification. They cannot be forged
    # cross-site: the flag lives in the Rack env and is set only by the dispatcher, and the MCP
    # endpoint itself rejects requests from foreign browser origins.
    def verified_request?
      mcp_request? || super
    end
  end
end
