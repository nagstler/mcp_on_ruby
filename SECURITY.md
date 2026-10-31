# Security Policy

## Supported versions

| Version | Supported |
|---|---|
| 2.x | ✅ |
| < 2.0 | ❌ |

## Reporting a vulnerability

Please **do not** open a public issue. Report vulnerabilities privately through
[GitHub Security Advisories](https://github.com/nagstler/mcp_on_ruby/security/advisories/new), or by email to
nagendra.dhanakeerthi@gmail.com.

Include a description, steps to reproduce, and the impact you expect. You will get an acknowledgement within
3 business days. Fixes are released as patch versions and credited in the changelog unless you prefer otherwise.

## Threat model

MCP on Ruby lets AI agents call your Rails controllers. Its security rests on these properties:

**Agents act as real users, through your existing checks.** Every tool call is an in-process request to a
declared controller action, through your full middleware stack and filters. The caller's `Authorization` header
and cookies are forwarded unchanged. Authentication and authorization are always your app's own code, so an
agent can do no more than the user whose credentials it presents.

**Only declared actions are reachable.** An action is a tool only if its controller declares `mcp_tool` for
it. Actions routed with `POST`, `PUT`, `PATCH`, or `DELETE` require `write: true`, and `allow_writes = false`
disables all of them at once. Tools carry read-only/destructive hints so clients can ask for confirmation.

**The "MCP request" marker cannot be forged.** `mcp_request?`, the stdio user, and the CSRF exemption for
dispatched requests rely on keys in the Rack env that only the dispatcher sets. No HTTP header can set them.

**Browsers cannot drive the endpoint cross-site.** The endpoint, served by the official SDK's Streamable HTTP
transport, rejects requests whose `Origin` is neither same-origin nor listed in `allowed_origins`, requires JSON
content types, and caps request size. Host validation is left to Rails' host authorization (`config.hosts`),
which runs before the endpoint.

**stdio sessions are local.** `bin/rails mcp:stdio` acts as the user returned by `stdio_user` or sends
`stdio_headers`. It is meant for a developer's own machine, so treat that configuration like any local
credential.

**Errors don't leak internals.** Server errors and exceptions reach the agent as a generic message. Details
go to `Rails.error`.

### Your responsibilities

- Write tool descriptions and choose exposed actions with the assumption that an agent may call any of them,
  with any arguments the schema allows.
- Keep authorization in your controllers (policies, scopes) rather than relying on the agent's judgment.
- Treat data returned to agents as disclosed to the model provider your users chose.
- Tools registered through `config.tools` bypass your controllers. Only use them for operations that are safe
  for every caller.
