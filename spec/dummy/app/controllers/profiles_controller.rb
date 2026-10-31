# frozen_string_literal: true

# A session-authenticated page using Warden, the way Devise apps work.
class ProfilesController < ApplicationController
  mcp_tool :show, description: "Show the signed-in user's profile"

  def show
    user = request.env["warden"].authenticate!(scope: :user)
    render json: { email: user.email, via_mcp: mcp_request? }
  end
end
