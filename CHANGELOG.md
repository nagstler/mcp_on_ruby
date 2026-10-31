# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-10-31

MCP on Ruby is now a Rails engine that exposes existing controller actions as MCP tools,
built on the official [`mcp`](https://github.com/modelcontextprotocol/ruby-sdk) gem.

### Added

- `mcp_tool` controller macro with a compact parameter schema DSL (nested objects, arrays, unions, nullable)
- Route-aware registry: path params become required arguments, annotations come from the HTTP verb, and
  misconfiguration (unrouted declarations, unflagged writes, duplicate names) raises at boot
- Dispatch of tool calls as in-process requests through the full middleware stack, forwarding the caller's
  `Authorization` header and cookies
- Result mapping from HTTP responses to MCP tool results, including structured JSON and agent-readable errors
- Stateless Streamable HTTP endpoint via `mount McpOnRuby::Engine, at: "/mcp"`
- `bin/rails mcp:stdio` with `stdio_user` (Devise/Warden) and `stdio_headers` (token auth) identities
- `bin/rails mcp:tools` and `bin/rails mcp:doctor`
- `mcp_on_ruby:install` and `mcp_on_ruby:expose` generators
- `McpOnRuby::TestHelper` (`mcp_call`, `mcp_tools`) and `mcp_on_ruby/rspec`
- `tool_call.mcp_on_ruby` instrumentation event
- `allow_writes` kill switch and `allowed_origins` for browser clients

### Changed

- Requires Ruby 3.2+ and Rails 7.1+
- The protocol layer is provided by the official `mcp` gem

### Removed

- The hand-written JSON-RPC server, Rack middleware, SSE transport, and `app/tools`/`app/resources` classes

## [1.0.0] - 2025-01-28

### Added
- Production-ready MCP server implementation for Rails applications
- Rails-native integration with generators, middleware, and Railtie
- Full JSON-RPC 2.0 protocol support over HTTP transport
- Rails generators for quick setup:
  - `rails generate mcp_on_ruby:install` - Complete MCP server setup
  - `rails generate mcp_on_ruby:tool` - Create new tools with templates
  - `rails generate mcp_on_ruby:resource` - Create new resources with URI templates
- Comprehensive security features:
  - Bearer token authentication
  - Rate limiting (configurable per minute)
  - CORS support with configurable origins
  - DNS rebinding protection
  - Localhost-only mode for development
- Automatic tool and resource discovery in Rails apps
- JSON Schema validation for tool inputs
- URI templating for resources
- Error handling with proper JSON-RPC error codes
- Claude Desktop integration with stdio bridge example
- Extensive documentation and examples

### Changed
- Complete architectural rewrite focused on Rails integration
- Simplified API following Rails conventions
- Improved error handling and logging
- Better security defaults

### Fixed
- Rails 8 compatibility issues with frozen arrays
- Middleware initialization timing issues
- Tool auto-registration in development mode
- PostgreSQL parameter binding in tool examples

### Removed
- Standalone client implementation (focus on server-side)
- STDIO transport (HTTP-only, with bridge examples for stdio clients)
- Prompts and roots features (not commonly used in Rails context)

## [0.2.0] - 2024-07-24

### Added
- OAuth 2.1 authentication for secure remote connections
- Permission-based access control for MCP methods
- JWT token validation and management
- Automatic token refresh mechanism
- HTTP transport authentication integration
- Middleware architecture for server authentication
- Authentication examples and documentation

## [0.1.0] - 2024-06-15

### Added
- Initial implementation of core MCP protocol
- JSON-RPC 2.0 message format
- HTTP and STDIO transports
- Basic server and client functionality
- Tool definition and execution
- Resource management
- Prompt handling
- Root filesystem access

[Unreleased]: https://github.com/nagstler/mcp_on_ruby/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/nagstler/mcp_on_ruby/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/nagstler/mcp_on_ruby/releases/tag/v1.0.0
