# frozen_string_literal: true

McpOnRuby.configure do |config|
  config.instructions = "Tools for the dummy shop."
  config.stdio_user = -> { User.find_by(email: ENV.fetch("MCP_USER")) if ENV["MCP_USER"] }
  config.stdio_headers = -> { { "Authorization" => "Bearer #{ENV.fetch("MCP_TOKEN")}" } if ENV["MCP_TOKEN"] }
end
