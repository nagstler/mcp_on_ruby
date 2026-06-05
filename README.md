# MCP on Ruby

<div align="center">

[![Gem Version](https://badge.fury.io/rb/mcp_on_ruby.svg)](https://badge.fury.io/rb/mcp_on_ruby)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ruby Version](https://img.shields.io/badge/Ruby-2.7%2B-red.svg)](https://www.ruby-lang.org/)

**Model Context Protocol (MCP) server for Rails applications**

Expose your Rails app as an AI accessible interface — define tools and resources the Rails way.

![MCP](https://github.com/user-attachments/assets/12c3c244-0026-47b0-861e-e40d731ac4e6)


</div>

---

## Features

🚀 **Production-Ready** - Authentication, rate limiting, error handling, security  
🔧 **Rails Integration** - Generators, autoloading, middleware, Railtie  
🛠️ **Tools System** - Callable functions with JSON Schema validation  
📊 **Resources System** - Data exposure with URI templating  
🔒 **Security** - DNS rebinding protection, CORS, token authentication  
⚡ **Real-time** - Server Events (SSE) foundation (full implementation coming soon)  
🎯 **Developer-Friendly** - Clean DSL, generators, testing support  

## Installation

Add to your `Gemfile`:

```ruby
gem 'mcp_on_ruby'
```

Then run:

```bash
bundle install
rails generate mcp_on_ruby:install
```

## Quick Start

### 1. Install and Configure

```bash
# Generate MCP server files
rails generate mcp_on_ruby:install

# Create a tool
rails generate mcp_on_ruby:tool UserManager --description "Manage application users"

# Create a resource  
rails generate mcp_on_ruby:resource UserStats --uri "users/{id}/stats" --template
```

### 2. Configure MCP Server

```ruby
# config/initializers/mcp_on_ruby.rb
McpOnRuby.configure do |config|
  config.authentication_required = true
  config.authentication_token = ENV['MCP_AUTH_TOKEN']
  config.rate_limit_per_minute = 60
  config.allowed_origins = [/\.yourdomain\.com$/]
end

Rails.application.configure do
  config.mcp.enabled = true
  config.mcp.auto_register_tools = true
  config.mcp.auto_register_resources = true
end
```

### 3. Create Tools

```ruby
# app/tools/user_manager_tool.rb
class UserManagerTool < ApplicationTool
  def initialize
    super(
      name: 'user_manager',
      description: 'Manage application users',
      input_schema: {
        type: 'object',
        properties: {
          action: { type: 'string', enum: ['create', 'update', 'delete'] },
          user_id: { type: 'integer' },
          attributes: { type: 'object' }
        },
        required: ['action']
      }
    )
  end

  protected

  def execute(arguments, context)
    case arguments['action']
    when 'create'
      user = User.create!(arguments['attributes'])
      { success: true, user: user.as_json }
    when 'update'
      user = User.find(arguments['user_id'])
      user.update!(arguments['attributes'])
      { success: true, user: user.as_json }
    else
      { error: 'Unsupported action' }
    end
  end

  def authorize(context)
    # Add your authorization logic
    context[:authenticated] == true
  end
end
```

### 4. Create Resources

```ruby
# app/resources/user_stats_resource.rb
class UserStatsResource < ApplicationResource
  def initialize
    super(
      uri: 'users/{id}/stats',
      name: 'User Statistics',
      description: 'Get detailed user statistics',
      mime_type: 'application/json'
    )
  end

  protected

  def fetch_content(params, context)
    user = User.find(params['id'])
    
    {
      user_id: user.id,
      statistics: {
        posts_count: user.posts.count,
        comments_count: user.comments.count,
        last_login: user.last_login_at,
        account_created: user.created_at
      },
      generated_at: Time.current.iso8601
    }
  end

  def authorize(context)
    # Check if user can access this data
    context[:authenticated] == true
  end
end
```

### 5. Start Your Server

```bash
rails server
# MCP server available at http://localhost:3000/mcp
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Rails App                            │
├─────────────────────────────────────────────────────────────┤
│  app/tools/          │  app/resources/                      │
│  ├── application_tool.rb     ├── application_resource.rb    │
│  ├── user_manager_tool.rb    ├── user_stats_resource.rb     │
│  └── ...                     └── ...                        │
├─────────────────────────────────────────────────────────────┤
│                    MCP Server Core                          │
│  ┌─────────────────┐ ┌─────────────────┐ ┌──────────────┐   │
│  │     Tools       │ │    Resources    │ │  Transport   │   │
│  │  - Validation   │ │  - Templating   │ │  - HTTP      │   │
│  │  - Authorization│ │  - Authorization│ │  - SSE       │   │
│  │  - Execution    │ │  - Content      │ │  - Security  │   │
│  └─────────────────┘ └─────────────────┘ └──────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                  JSON-RPC Protocol                          │
└─────────────────────────────────────────────────────────────┘
```

## Examples

Connect your Rails MCP server with different AI clients:

👉 **[Claude Desktop](examples/claude/)** - Complete setup guide with bridge script

👉 **MCP registries and control planes** - Register the Rails MCP endpoint with
an MCP-compatible registry or gateway so tool discovery, access control, audit
trails, and approvals can be managed centrally while Rails owns the tools.

## Documentation

👉 **[Advanced Usage](docs/advanced-usage.md)** - Custom authorization, caching, manual configuration  
👉 **[Testing Guide](docs/testing.md)** - RSpec integration and testing patterns  
👉 **[API Reference](docs/api-reference.md)** - Complete API documentation


## Requirements

- Ruby 2.7.0 or higher
- Rails 6.0 or higher (for full integration)
- JSON Schema validation support

## Dependencies

Production dependencies (minimal footprint):
- `json-schema` (~> 3.0) - JSON Schema validation
- `rack` (~> 2.2) - HTTP transport layer
- `webrick` (~> 1.7) - HTTP server

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`bundle exec rspec`)
5. Commit your changes (`git commit -am 'Add some feature'`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.txt) file for details.

## 🙏 Acknowledgments

- The [Model Context Protocol](https://modelcontextprotocol.io) team at Anthropic for creating the specification
- The Ruby on Rails community for inspiration and conventions

---

<div align="center">

Made with ❤️ for the Ruby community

</div>
