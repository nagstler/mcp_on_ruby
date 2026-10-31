# frozen_string_literal: true

# Responses that are not JSON, to exercise result mapping.
class PagesController < ApplicationController
  mcp_tool :html, description: "Render an HTML page"
  mcp_tool :text, description: "Render plain text"
  mcp_tool :moved, description: "Redirect elsewhere"
  mcp_tool :crash, description: "Raise an error"

  def html
    render html: helpers.tag.h1("Hello")
  end

  def text
    render plain: "pong"
  end

  def moved
    redirect_to "/elsewhere"
  end

  def crash
    raise "boom"
  end
end
