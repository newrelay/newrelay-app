# Jira draft — MCP Server Integration

Each block below is one Jira issue. Copy everything between the `=====` lines (title included) straight into a new Jira issue's title + description.

=====================================================
TITLE: MCP Server Integration
ISSUE TYPE: Epic
=====================================================

Context:
Lets an account admin turn on an MCP (Model Context Protocol) endpoint at /mcp so a user can connect their own AI client (Claude Desktop, Cursor, etc.) to their Chatwoot account — read conversations/contacts and perform a small set of safe writes, gated by a per-tool scope list on their personal access token.

Requirement:
Ship foundation + read tools, safe-write tools, and a self-service settings page where a user controls which tools their own access token may use. Full OAuth 2.1 support and any customer-visible write tools (send reply, change conversation status) are explicitly out of scope for now — deferred, no build date.

Acceptance criteria:
- Given mcp_integration is off for an account, when any MCP tool is called, then the call fails closed with a readable error (no 500).
- Given a valid Bearer token for a member of the account, when the client calls tools/list, then it receives the full catalog appropriate to that token's scopes.
- Given a token with a non-empty scopes list, when a tool not in that list is called, then the call is rejected with a readable error, not a crash.
- Given a token with an empty/unset scopes list (default for every existing token), when any tool is called, then access is unaffected — fully backward compatible, no migration or backfill needed.
- Given a user opens their MCP permissions page, when MCP is off for their account, then they see an "ask your administrator" message and no checkbox list.
- Given a user unchecks some tools and clicks Save, when the save completes, then the explicit list of remaining allowed tool names is persisted (an empty list is never used to mean "narrowed access" — it only ever means "never scoped, full access").

Dependencies:
New production dependency for the MCP protocol library. New feature flag controlling whether MCP is enabled per account (default disabled). New columns on the access token table to store per-tool scopes and last-used timestamp.

Test notes:
Auth, feature-flag, and account-membership checks must each have a passing spec. Every tool needs at least one happy-path spec. Manually verify against a real MCP client (Claude Desktop or Cursor) before sign-off.

Status: Implemented and committed on the current feature branch, not yet merged to main. Keep this in "Ready for QA" until merged and verified — do not mark Done on merge alone.

=====================================================
TITLE: MCP Server Foundation + Read Tools
ISSUE TYPE: Story
EPIC: MCP Server Integration
=====================================================

Context:
First slice of the MCP work — stands up the server endpoint and ships read-only access so a connected AI client can look up account data.

Requirement:
Stand up the MCP endpoint, authenticate every call with a personal Bearer access token (bot-owned tokens rejected), re-check account membership and the MCP feature flag on every single call, and expose read tools for: accounts, conversations (list + single), contacts (list + single), inboxes, agents, teams, and labels.

Acceptance criteria:
- Given a missing or invalid Bearer token, when any tool is called, then the server returns an authentication error and no tool runs.
- Given a bot-owned token, when used against the MCP endpoint, then the call is rejected.
- Given a valid token but the caller is not a member of the requested account, when a tool is called, then it is rejected the same way the existing REST API rejects it.
- Given an unknown or deleted conversation/contact id, when the corresponding tool is called, then it returns a readable tool error, never a server crash.

Dependencies:
MCP protocol library added as a direct production dependency. New scopes/last-used-at columns on the access token table (added now so future scoped-token work doesn't need a second migration later).

Test notes:
Cover: missing/invalid token, feature flag off, cross-account access attempt, and one happy-path spec per read tool.

=====================================================
TITLE: Safe-write MCP Tools + Audit Stamping
ISSUE TYPE: Story
EPIC: MCP Server Integration
=====================================================

Context:
Second slice — lets a connected AI client perform a small set of low-risk write actions, and makes sure those writes are distinguishable from a human agent's actions in the audit trail.

Requirement:
Add write tools for: adding a private note, adding a label, removing a label, assigning a conversation, and setting priority — each reusing the exact same service logic the REST API already uses. Every write made through MCP is tagged so it shows up as MCP-originated in the audit log.

Acceptance criteria:
- Given any safe-write tool is called successfully, when the resulting record is inspected, then the audit log shows it as MCP-originated, not a human agent action.
- Given the "add private note" tool is called with any input, when the note is created, then it is always private and never customer-visible.
- Given an invalid label name, when the "add label" tool is called, then it is rejected rather than silently creating a mismatched or duplicate label.

Dependencies:
Depends on the foundation story above (auth + account-membership checks already in place).

Test notes:
One happy-path spec per write tool, plus one spec confirming the audit-log entry is tagged as MCP-originated.

=====================================================
TITLE: MCP Permissions Settings Page
ISSUE TYPE: Story
EPIC: MCP Server Integration
=====================================================

Context:
Today a personal access token either has full access to every MCP tool, or none at all (if MCP is off for the account) — with no visibility for the user into which. This adds a settings page where a user can see and control exactly which tools their own token may use.

Requirement:
Add a new page under the user's profile settings listing every available MCP tool as a checkbox, grouped as Read and Write, with an explicit Save button (no auto-save on toggle). Enforce the saved scope list on the backend so a token can only call tools it's been granted.

Acceptance criteria:
- Given MCP is off for the account, when the user opens their MCP permissions page, then they see only an "ask your administrator" message, no checkboxes.
- Given MCP is on and the token has never been scoped before, when the page loads, then every tool shows checked (matches current "unscoped = full access" behavior).
- Given the user unchecks one or more tools and clicks Save, when the request completes, then the explicit remaining tool list is persisted, and saving unrelated profile fields (name, avatar, etc.) elsewhere never clears this list.
- Given a token scoped to a subset of tools, when a tool outside that list is called, then it is rejected with the same readable error format every other tool rejection uses.
- Given a token that has never visited this page, when any tool is called, then behavior is completely unchanged from today — no migration or backfill required.

Dependencies:
Depends on the foundation story above (scopes column already added there). Links out to the existing access-token page rather than duplicating token view/copy/regenerate controls.

Test notes:
Backend: a spec proving an out-of-scope tool call is rejected, and a spec proving an unscoped token is unaffected. A spec on the profile-update endpoint confirming scope changes persist without clearing unrelated fields. Frontend: a component spec covering the "MCP off" state, the full checkbox list rendering in the right groups, and the Save action sending the correct payload.

=====================================================
TASKS (sub-tasks — attach each to its parent Story above)
=====================================================

--- Under Story: MCP Server Foundation + Read Tools ---

TITLE: Add MCP protocol library as a direct production dependency
ISSUE TYPE: Task
Add and pin the MCP server library as a top-level production dependency (it currently only resolves transitively through a dev-only gem, so this is a genuinely new production dependency, not free reuse).

TITLE: Add scopes + last_used_at columns to access tokens
ISSUE TYPE: Task
One migration adding a nullable scopes array column and a nullable last_used_at timestamp to the access token table. No backfill — existing rows default to empty/unscoped.

TITLE: Add mcp_integration feature flag
ISSUE TYPE: Task
Register a new account-level feature flag, disabled by default, that gates the whole MCP endpoint.

TITLE: Mount MCP endpoint with auth, flag, and tenancy checks
ISSUE TYPE: Task
Stand up the MCP server at its endpoint. Resolve the caller from the Bearer token (User-owned only, bot tokens rejected), and on every single call re-check the feature flag and that the caller belongs to the requested account. Any failure returns a readable tool error, never a 500.

TITLE: Implement read-only tool catalog
ISSUE TYPE: Task
Implement the 9 read tools: list accounts, list/get conversation, list/get contact, list inboxes, list agents, list teams, list labels. Each reuses existing finder/scope logic — no new query logic.

TITLE: Add auth/flag/tenancy/read-tool specs
ISSUE TYPE: Task
Spec coverage for: missing/invalid token, bot-owned token, flag off, cross-account access, and one happy-path spec per read tool.

--- Under Story: Safe-write MCP Tools + Audit Stamping ---

TITLE: Implement add_private_note tool
ISSUE TYPE: Task
Reuses the existing private-note creation path. Must be impossible to produce a customer-visible message through this tool under any input.

TITLE: Implement add_label / remove_label tools
ISSUE TYPE: Task
Reuses existing label/tagging logic, including case normalization and rejecting labels with no matching account label.

TITLE: Implement assign_conversation tool
ISSUE TYPE: Task
Reuses existing assignment logic; rejects assignment to a nonexistent agent id.

TITLE: Implement set_priority tool
ISSUE TYPE: Task
Reuses existing priority-update logic.

TITLE: Stamp MCP origin on every write for the audit log
ISSUE TYPE: Task
Every write tool call marks the request as MCP-originated so it's distinguishable from a human agent action in the audit trail.

TITLE: Add write-tool + audit-stamp specs
ISSUE TYPE: Task
One happy-path spec per write tool, plus one spec confirming the audit-log entry is tagged as MCP-originated.

--- Under Story: MCP Permissions Settings Page ---

TITLE: Enforce per-tool scopes on every MCP call
ISSUE TYPE: Task
Add a scope check that runs right after authentication and before any tool executes: if the token has a non-empty scope list and the requested tool isn't in it, reject with a readable error. An empty/unset scope list stays a no-op (full access), so every existing token is unaffected until a user explicitly narrows it.

TITLE: Accept and persist scopes on the profile update endpoint
ISSUE TYPE: Task
The profile update endpoint accepts an optional list of allowed tool names and saves it to the user's access token. Guard it so the field is only touched when explicitly present in the request — unrelated profile edits (name, avatar, etc.) must never clear it.

TITLE: Expose current scopes on the profile API response
ISSUE TYPE: Task
Add the token's current scope list to the profile API response so the settings page can render existing state on load.

TITLE: Add MCP permissions route under profile settings
ISSUE TYPE: Task
New child route under the user's profile settings section for the permissions page.

TITLE: Build the permissions checkbox page (Relay design system)
ISSUE TYPE: Task
Page shows a single "ask your administrator" message when MCP is off for the account. Otherwise, two grouped checkbox lists (Read / Write) covering all 14 tools, local component state only (not saved until Save is clicked), and a link out to the existing access-token page instead of duplicating it.

TITLE: Wire Save action to persist scopes
ISSUE TYPE: Task
Save button disabled until at least one checkbox differs from last-saved state; on click, sends the full explicit list of currently-checked tool names (never an empty list standing in for "narrowed" — empty is reserved for "never scoped").

TITLE: Add backend + frontend specs for the permissions page
ISSUE TYPE: Task
Backend: scope-enforcement spec (rejects out-of-scope tool, no-op for unscoped token) and a profile-update spec confirming scopes persist without clearing unrelated fields. Frontend: component spec covering the disabled state, full checkbox render in correct groups, and the Save action's payload.
