# Releasing

MCP on Ruby follows [Semantic Versioning](https://semver.org). Releases are cut from `main`.

## Steps

1. Open a release PR that:
   - sets `McpOnRuby::VERSION` in `lib/mcp_on_ruby/version.rb`
   - moves `[Unreleased]` entries in `CHANGELOG.md` under the new version with today's date
2. Merge it once CI is green.
3. Tag the merge commit and create the GitHub release:

   ```bash
   git switch main && git pull
   git tag -a v2.0.1 -m "v2.0.1"
   git push origin v2.0.1
   gh release create v2.0.1 --title "v2.0.1" --notes-from-tag   # or paste the changelog section
   ```

4. Publish to RubyGems, either:
   - **from CI:** run the **Release** workflow (Actions → Release → Run workflow) with the tag, or
   - **locally:** `gem build mcp_on_ruby.gemspec --strict && gem push mcp_on_ruby-2.0.1.gem` (MFA is required).

## One-time setup for CI publishing

The Release workflow uses [RubyGems trusted publishing](https://guides.rubygems.org/trusted-publishing/),
so no API key is stored in GitHub:

1. On rubygems.org, open **mcp_on_ruby → Trusted publishers → Create**.
2. Repository `nagstler/mcp_on_ruby`, workflow `release.yml`, environment `rubygems`.
3. In GitHub, create the `rubygems` environment (Settings → Environments), optionally with required reviewers.
