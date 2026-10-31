# frozen_string_literal: true

module Admin
  # A namespaced controller, to exercise tool naming and dispatch under a module.
  class ReportsController < ActionController::API
    mcp_tool :index, description: "List admin reports"

    def index
      render json: [{ name: "daily" }]
    end
  end
end
