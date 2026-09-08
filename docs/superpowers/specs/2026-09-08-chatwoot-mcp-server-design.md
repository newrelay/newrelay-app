# Chatwoot MCP Server — Design

## Goal

Let a user connect their own AI agent (Claude, Cursor, etc.) to their Chatwoot
account over MCP, so the agent can read conversations/contacts and take a set
of low-risk actions on the user's behalf.

This is the opposite direction from the existing (upstream, unmerged here)
`feat/mcp-integration` work in `lib/mcp/clients/`, which makes Chatwoot's own
AI agent *consume* external MCP servers (e.g. Mintlify docs) as tool sources.
That work is unrelated and untouched by this design; naming below is chosen
to avoid colliding with `lib/mcp/`.

## Decisions

| Axis | Decision |
|---|---|
| Deployment | Remote HTTP/SSE endpoint, served per-instance (each self-hosted or cloud Chatwoot installation exposes its own `/mcp`) — not a centrally hosted multi-tenant service. |
| Stack | Ruby, inside this Rails app, using the [`fast-mcp`](https://rubygems.org/gems/fast-mcp) gem. Already resolves in `Gemfile.lock` as a transitive dep of `tidewave`, so no version-conflict risk. |
| Auth | Bearer token = existing Chatwoot personal `AccessToken`. No new auth system. |
| Rollout gate | Opt-in per-account feature flag via the existing `config/features.yml` / `Featurable` mechanism. Off by default. |
| Tool scope (v1) | Read tools + safe writes only. No customer-visible replies, no status changes (resolve/open/pending/snooze). |

## Architecture

- New mount point `/mcp` in `config/routes.rb`, outside the existing
  `/api/v1/accounts/:account_id/...` namespace — MCP clients configure a bare
  URL + bearer token, they don't know an account ID up front.
- Tool classes live under `app/mcp/tools/` (Rails-autoloaded), one class per
  tool, each a thin `FastMcp::Tool` subclass.
- Runs in the existing Puma process. No new deploy target, no new
  infrastructure.

## Auth & tenancy

- An auth hook on the mount reads the `Authorization: Bearer <token>` header
  and resolves it via `AccessToken.find_by(token:)` — the same model
  `AccessTokenAuthHelper` already uses for the REST API, just off the
  standard Bearer header instead of the custom `api_access_token` header.
  Missing/invalid token → MCP-level 401.
- Resolved token owner (`User`, per existing `allowed_current_user_type?`
  logic — bots excluded for MCP v1) becomes `Current.user` for the request.
- A token's user may belong to multiple accounts. `list_accounts` is the
  entry-point tool: it returns the accounts the token's user can see (id,
  name). Every other tool takes an explicit `account_id` argument and
  re-checks `Current.user.account_users.exists?(account_id:)` before
  touching any data for that account — mirrors the guard shape already used
  by the REST controllers/policies.
- Before any tool runs, the auth hook also checks the resolved account has
  the `mcp_integration` feature flag enabled (see Rollout gate below);
  otherwise every call for that account fails closed with a clear error
  ("MCP access is not enabled for this account").

## Rollout gate (feature flag)

- Add one entry to `config/features.yml`:
  ```yaml
  - name: mcp_integration
    display_name: MCP Integration
    enabled: false
  ```
- This surfaces automatically in the existing account Features settings UI
  (Settings → Account → Features) — no new UI to build. An account admin
  turns it on; `Account#feature_enabled?('mcp_integration')` gates every MCP
  request for that account.

## Tool surface (v1)

Read:
- `list_accounts` — accounts the token's user belongs to
- `list_conversations(account_id, status?, assignee_id?, inbox_id?, query?)`
- `get_conversation(account_id, conversation_id)`
- `list_contacts(account_id, search?)`
- `get_contact(account_id, contact_id)`
- `list_inboxes(account_id)`
- `list_agents(account_id)`
- `list_teams(account_id)`
- `list_labels(account_id)`

Safe writes:
- `add_private_note(account_id, conversation_id, content)` — internal note
  only, never customer-visible
- `add_label(account_id, conversation_id, labels)`
- `remove_label(account_id, conversation_id, labels)`
- `assign_conversation(account_id, conversation_id, agent_id? | team_id?)`
- `set_priority(account_id, conversation_id, priority)`

Explicitly excluded from v1 (highest-risk, deferred): `send_reply`
(customer-visible message) and conversation status changes
(resolve/open/pending/snooze).

Each tool delegates to existing finders/services already used by the REST
API controllers (e.g. `Current.account.conversations`, existing
conversation-search/finder logic, existing label/assignment update paths)
rather than re-implementing query or update logic.

## Error handling

Validation failures (unknown `account_id`, not-a-member, not-found record,
feature flag off) return a normal MCP tool error result (`isError: true`,
human-readable message) rather than raising an unhandled exception — the
connected agent sees a clean, actionable failure instead of a 500.

## Testing

New public, write-capable auth boundary, so it gets targeted request specs
(not the full "skip specs" MVP default): auth rejection (missing/invalid
token), feature-flag-off rejection, account-scoping rejection (valid token,
account not a member), and one happy-path spec per tool.

## Out of scope for v1

- `send_reply` and conversation status-change tools
- Centrally hosted multi-tenant MCP endpoint
- OAuth 2.1 / Claude.ai web "Connectors" support (requires OAuth; bearer-token
  auth won't satisfy that flow — noted as a known limitation, not a blocker)
- Agent-bot tokens (only `User`-owned tokens supported in v1)
