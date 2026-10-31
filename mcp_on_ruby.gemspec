# frozen_string_literal: true

require_relative "lib/mcp_on_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "mcp_on_ruby"
  spec.version = McpOnRuby::VERSION
  spec.authors = ["Nagendra Dhanakeerthi"]
  spec.email = ["nagendra.dhanakeerthi@gmail.com"]

  spec.summary = "Make your Rails app usable by AI agents."
  spec.description = <<~DESC.tr("\n", " ").strip
    MCP on Ruby exposes existing Rails controller actions as Model Context Protocol (MCP) tools.
    Agents call your app through the same routes, authentication, policies, params, and JSON
    responses your users already rely on. Built on the official mcp gem; serves Streamable HTTP
    and stdio.
  DESC
  spec.homepage = "https://github.com/nagstler/mcp_on_ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "documentation_uri" => "#{spec.homepage}#readme",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*", "CHANGELOG.md", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "actionpack", ">= 7.1", "< 9"
  spec.add_dependency "mcp", "~> 1.8", ">= 1.8.2"
  spec.add_dependency "railties", ">= 7.1", "< 9"
end
