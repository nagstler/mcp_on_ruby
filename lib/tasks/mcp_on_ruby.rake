# frozen_string_literal: true

namespace :mcp do
  desc "Serve this app's MCP tools over stdio for local agents"
  task stdio: :environment do
    McpOnRuby::Stdio.run
  end

  desc "List the controller actions exposed as MCP tools"
  task tools: :environment do
    print McpOnRuby::ToolTable.render(McpOnRuby.registry.tools)
  end

  desc "Check the MCP on Ruby setup"
  task doctor: :environment do
    doctor = McpOnRuby::Doctor.new.run
    print doctor.report
    exit(1) unless doctor.ok?
  end
end
