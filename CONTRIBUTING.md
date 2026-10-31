# Contributing to MCP on Ruby

Thanks for helping make Rails apps usable by AI agents. Bug reports, ideas, documentation fixes, and code are all welcome.

## Ground rules

- Be kind. This project follows the [Code of Conduct](CODE_OF_CONDUCT.md).
- For anything larger than a small fix, open an issue first so we can agree on the approach.
- Report security problems privately, as described in [SECURITY.md](SECURITY.md), never in a public issue.

## Development setup

```bash
git clone https://github.com/nagstler/mcp_on_ruby.git
cd mcp_on_ruby
bin/setup            # bundle install
bundle exec rake     # specs + RuboCop
bin/console          # IRB with the dummy Rails app loaded
```

The suite runs against a small Rails app in `spec/dummy` with token-authenticated, Warden-authenticated, and non-JSON endpoints. Integration specs speak real MCP over Streamable HTTP and spawn `bin/rails mcp:stdio` as a subprocess.

### Testing other Rails versions

The Gemfile reads `RAILS_VERSION` (default `8.1`):

```bash
RAILS_VERSION=7.1 bundle update
RAILS_VERSION=7.1 bundle exec rspec
```

CI tests Ruby 3.2–3.4 against Rails 7.1–8.1 on every pull request.

### Trying a change in a real app

```ruby
# In your app's Gemfile
gem "mcp_on_ruby", path: "../mcp_on_ruby"
```

Then `bin/rails mcp:doctor`, `bin/rails mcp:tools`, and the [MCP Inspector](https://github.com/modelcontextprotocol/inspector) (`npx @modelcontextprotocol/inspector bin/rails mcp:stdio`) are the quickest way to see what agents see.

## Pull requests

1. Branch from `main`.
2. Add or update specs. Behavior changes need a spec that fails without the change.
3. Run `bundle exec rake`; specs and RuboCop must pass.
4. Update `README.md` for user-facing changes.
5. Give the PR a [Conventional Commit](https://www.conventionalcommits.org) title. PRs are squash-merged, and the
   title becomes the commit that drives versioning and the changelog:

   | Title | Release |
   |---|---|
   | `fix: handle empty JSON bodies` | patch (2.0.0 → 2.0.1) |
   | `feat: expose show actions as MCP resources` | minor (2.0.0 → 2.1.0) |
   | `feat!: drop Rails 7.1` (or a `BREAKING CHANGE:` footer) | major (2.0.0 → 3.0.0) |
   | `docs:`, `test:`, `ci:`, `chore:`, `refactor:` | no release on their own |

   Don't edit `CHANGELOG.md` or `McpOnRuby::VERSION` by hand; the release PR does that.

## Design principles

- **The controller is the source of truth.** Agents should go through the same routes, filters, and policies as everyone else. Avoid features that create a second path around them.
- **Safe by default.** Anything that lets an agent change data must be explicit.
- **Lean on the official SDK** for protocol behavior instead of reimplementing it here.
- **Fail early and clearly.** Misconfiguration should raise at boot or in `mcp:doctor`, not on an agent's first call.
