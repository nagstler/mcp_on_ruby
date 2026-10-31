# Releasing

Releases are automated with [release-please](https://github.com/googleapis/release-please) and follow
[Semantic Versioning](https://semver.org).

## How a release happens

1. Pull requests are squash-merged into `main` with [Conventional Commit](https://www.conventionalcommits.org)
   titles (enforced by the **PR title** check). `fix:` means patch, `feat:` means minor, and `feat!:` or a
   `BREAKING CHANGE:` footer means major.
2. On every push to `main`, the **Release** workflow updates an open release PR titled
   `chore(main): release X.Y.Z`. It bumps `McpOnRuby::VERSION`, writes the `CHANGELOG.md` entry, and updates
   `.release-please-manifest.json`.
3. Merging the release PR:
   - tags `vX.Y.Z` and publishes the GitHub release with the changelog notes,
   - runs the suite against the tag and pushes the gem to RubyGems using
     [trusted publishing](https://guides.rubygems.org/trusted-publishing/), so no API key is stored in GitHub.

Nothing in this process is manual except reviewing and merging the release PR.

## Forcing a specific version

Add a `Release-As: 2.1.0` footer to a commit on `main` (for example in a squash-merge body), and the next
release PR uses that version.

## One-time setup

- **RubyGems trusted publisher:** on rubygems.org, open *mcp_on_ruby → Trusted publishers → Create* with
  repository `nagstler/mcp_on_ruby`, workflow `release.yml`, environment `rubygems`.
- **GitHub:** Settings → Actions → General → enable *Allow GitHub Actions to create and approve pull requests*
  so release-please can open its PR.

## Release PR checks

Pull requests opened by GitHub Actions do not trigger other workflows, so CI does not run on the release PR
itself. It only changes the version and changelog; CI runs on `main` after merge, and the publish job runs the
suite against the tag before pushing the gem. Maintainers merge the release PR with the ruleset's bypass.

## Manual fallback

If CI publishing is unavailable:

```bash
git switch main && git pull
gem build mcp_on_ruby.gemspec --strict
gem push mcp_on_ruby-X.Y.Z.gem   # MFA required
```
