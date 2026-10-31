# frozen_string_literal: true

module RegistryFixtures
  class UnroutedController < ActionController::API
    mcp_tool :archive, description: "Archive things"
  end
end
