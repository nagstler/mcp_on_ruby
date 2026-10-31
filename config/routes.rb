# frozen_string_literal: true

McpOnRuby::Engine.routes.draw do
  match "/", to: McpOnRuby::Endpoint.new, via: :all, as: :endpoint
end
