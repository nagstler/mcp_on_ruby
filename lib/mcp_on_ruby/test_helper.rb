# frozen_string_literal: true

module McpOnRuby
  # Test helpers for apps using MCP on Ruby. Calls go through the real MCP server and your real
  # controllers, so schema, authentication, and authorization mistakes all surface in tests.
  #
  # Minitest:
  #   class ActiveSupport::TestCase
  #     include McpOnRuby::TestHelper
  #   end
  #
  # RSpec:
  #   require "mcp_on_ruby/rspec"
  module TestHelper
    # The outcome of a tool call made in a test.
    class Result
      attr_reader :response

      def initialize(response)
        @response = response
      end

      def success?
        !error?
      end

      def error?
        result["isError"] == true || response.key?("error")
      end

      # Parsed JSON the action rendered (or, for errors, `{ "status" => ..., "body" => ... }`).
      def structured
        result["structuredContent"]
      end

      # HTTP status of a failed call, e.g. 403. Nil for successful calls.
      def status
        structured["status"] if result["isError"] && structured.is_a?(Hash)
      end

      # Text content the agent sees.
      def text
        Array(result["content"]).filter_map { |block| block["text"] }.join("\n")
      end

      # JSON-RPC error message for protocol-level failures, such as an unknown tool or invalid arguments.
      def protocol_error
        response.dig("error", "data") || response.dig("error", "message")
      end

      def inspect
        "#<#{self.class.name} #{error? ? "error" : "success"} #{text.inspect}>"
      end

      private

      def result
        response.fetch("result", {})
      end
    end

    # Calls an MCP tool the way an agent would.
    #
    # @param tool [String, Symbol] tool name, e.g. :orders_index
    # @param arguments [Hash] tool arguments
    # @param as [Object] user to sign in through Warden/Devise (like `config.stdio_user`)
    # @param headers [Hash] request headers, e.g. { "Authorization" => "Bearer token" }
    # @return [McpOnRuby::TestHelper::Result]
    def mcp_call(tool, arguments = {}, as: nil, headers: {})
      Result.new(mcp_rpc("tools/call", { name: tool.to_s, arguments: }, as:, headers:))
    end

    # Names of the tools an agent can see.
    def mcp_tools
      mcp_rpc("tools/list", {}).dig("result", "tools").map { |tool| tool["name"] }
    end

    private

    def mcp_rpc(method, params, as: nil, headers: {})
      context = CallContext.new(transport: :test, user: as, headers:)
      server = McpOnRuby.server_factory.build(context)
      JSON.parse(server.handle_json(JSON.generate(jsonrpc: "2.0", id: 1, method:, params:)))
    end
  end
end
