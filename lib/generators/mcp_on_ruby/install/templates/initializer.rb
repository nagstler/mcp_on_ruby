# frozen_string_literal: true

McpOnRuby.configure do |config|
  # Name and version reported to MCP clients.
  # config.server_name    = "<%= Rails.application.class.module_parent_name.underscore.dasherize %>"
  # config.server_version = "1.0.0"

  # Guidance sent to agents when they connect.
  # config.instructions = "Tools for <%= Rails.application.class.module_parent_name.titleize %>."

  # Identity for local sessions started with `bin/rails mcp:stdio`.
  # Devise / Warden apps: sign in as a user.
  # config.stdio_user = -> { User.find_by!(email: ENV.fetch("MCP_USER")) }
  # Token-authenticated APIs: send headers your app already accepts.
  # config.stdio_headers = -> { { "Authorization" => "Bearer #{ENV.fetch("MCP_TOKEN")}" } }

  # Set to false to hide and refuse every tool declared with `write: true`.
  # config.allow_writes = true

  # Browser origins allowed to call the HTTP endpoint (non-browser clients send no Origin).
  # config.allowed_origins = ["https://app.example.com"]
end
