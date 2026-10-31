# frozen_string_literal: true

# Responses that are not JSON, to exercise result mapping.
class PagesController < ApplicationController
  mcp_tool :html, description: "Render an HTML page"
  mcp_tool :text, description: "Render plain text"
  mcp_tool :moved, description: "Redirect elsewhere"
  mcp_tool :crash, description: "Raise an error"
  mcp_tool :noisy, description: "Print to stdout while rendering JSON"

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

  # Output like this must never corrupt the stdio protocol stream.
  def noisy
    puts "noise from puts"
    $stdout.puts "noise from $stdout"
    STDOUT.puts "noise from STDOUT" # rubocop:disable Style/GlobalStdStream
    render json: { quiet: true }
  end
end
