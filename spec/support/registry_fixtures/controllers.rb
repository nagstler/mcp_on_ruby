# frozen_string_literal: true

# Controllers routed by the registry specs through their own route sets.
module RegistryFixtures
  class WidgetsController < ActionController::API
    mcp_tool :index, description: "List widgets", params: { q: :string }
    mcp_tool :show, description: "Show a widget"
    mcp_tool :create, description: "Create a widget", write: true, params: { name: { type: :string, required: true } }
    mcp_tool :update, description: "Update a widget", write: true
    mcp_tool :destroy, description: "Delete a widget", write: true, annotations: { destructive_hint: false }
  end

  class GadgetsController < ActionController::API
    mcp_tool :create, description: "Create a gadget"
  end

  class BaseController < ActionController::API
    mcp_tool :index, description: "List records"
  end

  class ThingsController < BaseController
  end

  module Admin
    class WidgetsController < ActionController::API
      mcp_tool :index, description: "List widgets for admins"
    end
  end

  class SearchController < ActionController::API
    mcp_tool :query, description: "Search", name: "widgets_index"
  end
end
