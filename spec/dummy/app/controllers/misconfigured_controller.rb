# frozen_string_literal: true

# Declares a tool with no route when MCP_BROKEN_DECLARATION is set, to prove boot-time validation.
class MisconfiguredController < ActionController::API
  mcp_tool :archive, description: "Has no route" if ENV["MCP_BROKEN_DECLARATION"]
end
