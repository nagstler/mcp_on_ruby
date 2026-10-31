# frozen_string_literal: true

# A session-style controller with Rails' default CSRF protection.
class NotesController < ApplicationController
  protect_from_forgery with: :exception

  mcp_tool :create, description: "Write a note", write: true, params: { body: :string }

  def create
    render json: { body: params[:body] }, status: :created
  end
end
