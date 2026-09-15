# MCP Permissions Settings Page — Design

## Goal

Let an individual user see and control what their own MCP connection is
allowed to do — a real settings surface, replacing the current reality
where a Bearer token either has full access to every MCP tool or (if
`mcp_integration` is off for the account) none at all, with no visibility
into which. This is the "Future direction" item from the MCP server FRD
(`docs/frd/26-mcp-server.md` §5/§9/§10) and design spec, now being built.

## Context

The MCP server backend (14 tools, `Mcp::BaseTool`, auth/tenancy) was ported
onto this branch from `worktree-mcp-server` (PR #5, not yet merged to
`main`) specifically to build this page against — see the port commit for
why a file-state port was used instead of a history merge (unrelated git
histories between the two branches).

Two things discovered while researching this page, both correcting earlier
assumptions in the MCP FRD:

1. **`mcp_integration` has no self-service account-admin toggle.** The FRD
   assumed "Settings → Account → Features" was a Vue page any account admin
   could reach. It isn't — feature flags in `config/features.yml` are
   toggled via a Rails **super-admin** screen
   (`app/views/super_admin/accounts/show.html.erb`), platform-operator-only.
   This page must handle "MCP is off, and only a platform admin can turn it
   on" as a real, expected state.
2. **A user's `AccessToken` is shared across every account they belong to**
   (`has_one :access_token, as: :owner` on `User`) — `scopes` stored on it
   apply globally, not per-account. This page belongs in **Profile
   Settings** (user-level), not account-level Settings, matching where the
   existing Access Token page already lives.

## Decisions

| Axis | Decision |
|---|---|
| Location | New child route under Profile Settings (`/app/accounts/:accountId/profile/mcp`), alongside the existing `settings`/`mfa` routes — not account-level Settings. |
| Scope granularity | Full per-tool permission list (14 checkboxes), not a binary read/write switch — matches the FRD's original "Future direction" vision. |
| Default when `scopes` is empty | All 14 shown checked — this is the literal current behavior (empty/nil `scopes` = full access), the UI must reflect reality, not a new default. |
| Save behavior | Explicit **Save** button, not auto-save per checkbox toggle — accidentally unchecking a box shouldn't immediately narrow access with no undo. |
| Account-disabled state | If `mcp_integration` is off for the account, show only a message ("ask your administrator") — no checkbox list, since there's nothing to scope yet. |
| Token display | Not duplicated here — the existing Access Token page already handles view/copy/regenerate. This page links to it rather than repeating it. |
| Design system | Relay (`components-next/relay/`) — this branch has it; the `worktree-mcp-server` branch that built the backend does not, which is why this page couldn't be built there. |

## Backend

### `Mcp::BaseTool` — scope enforcement

`authenticate!` currently resolves `access_token` as a local variable
(used once, for the `last_used_at` touch) and discards it. Change it to
keep the resolved record as `@access_token`, then add a new check called
from `call`, right after `authenticate!` and before `require_account!`
(scopes gate which tools exist at all for this token, independent of which
account a call targets):

```ruby
def call(**args)
  authenticate!
  Current.mcp = true
  authorize_scope!
  require_account!(args[:account_id]) if self.class.requires_account?

  Mcp::BaseTool.success(perform(**args))
rescue ToolError => e
  Mcp::BaseTool.failure(e.message)
rescue StandardError => e
  ChatwootExceptionTracker.new(e, user: Current.user, account: Current.account).capture_exception
  Mcp::BaseTool.failure('Something went wrong')
ensure
  Current.reset
end

private

def authorize_scope!
  return if @access_token.scopes.blank?
  return if @access_token.scopes.include?(self.class.tool_name)

  raise ToolError, "This access token is not permitted to use #{self.class.tool_name}"
end
```

`self.class.tool_name` is the exact string every tool already registers
via `tool_name '...'` (fast-mcp's own DSL) — no new naming scheme needed.

**Backward compatibility:** every access token that exists today has
`scopes == []` (the column's default), so `authorize_scope!` is a no-op for
all of them until a user visits this page and explicitly narrows their own
scope. No migration, no backfill.

### API — reading and writing scopes

- `app/views/api/v1/models/_user.json.jbuilder` — add `json.access_token_scopes resource.access_token.scopes` alongside the existing `json.access_token resource.access_token.token` line.
- `Api::V1::ProfilesController#update` — accept a `scopes` param (array of tool-name strings) and persist it: `current_user.access_token.update!(scopes: params[:scopes]) if params.key?(:scopes)`. Guarded by `params.key?` so unrelated profile updates (name, avatar, etc.) never accidentally clear scopes.
- Whether `mcp_integration` is enabled for the current account: no new endpoint — the frontend already has this via the existing `useAccount()` composable's `isFeatureEnabledonAccount` getter, backed by the accounts store's existing `features` field.

## Frontend

- New route: `mcp` child of `profile_settings` (`app/javascript/dashboard/routes/dashboard/settings/profile/profile.routes.js`), following the `mfa` route's shape (including its `beforeEnter` guard pattern, adapted to check `isFeatureEnabledonAccount('mcp_integration')` instead of the MFA global config flag — if off, the guard doesn't need to redirect away, since the page's own body handles that state; the guard pattern is a structural reference, not necessarily reused verbatim).
- New component, Relay-based (no legacy `woot-*`/scoped CSS), styled per `components-next/relay/DESIGN.md`/`TOKENS.md`. Structure:
  - `SectionLayout` wrapper (matches the existing Access Token/MFA pages), title "MCP Permissions", description explaining what this controls.
  - If `!isFeatureEnabledonAccount('mcp_integration')`: a single message, no checkboxes.
  - Else: two grouped lists (headings "Read" / "Write"), one row per tool, each row built like `autoresponder/components/settings/SettingsToggleRow.vue` (label + description + `RelayCheckbox`, `v-model` to local component state — not directly to the store, since changes aren't persisted until Save).
  - Tool list, Read (9): `list_accounts`, `list_conversations`, `get_conversation`, `list_contacts`, `get_contact`, `list_inboxes`, `list_agents`, `list_teams`, `list_labels`.
  - Tool list, Write (5): `add_private_note`, `add_label`, `remove_label`, `assign_conversation`, `set_priority`.
  - `RelayButton` "Save" at the bottom, disabled until at least one checkbox differs from the last-saved state; on click, `PATCH /api/v1/profile` with the full selected-tool-name array as `scopes`.
  - A small link/note pointing to the existing Access Token section for viewing/regenerating the token itself.
- Store: extend the existing `auth` module (where `resetAccessToken` already lives) with an action to `PATCH` scopes, or add scopes-handling directly to the existing profile-update action if one already covers arbitrary profile fields — the `ui` agent should check which pattern the codebase already uses for partial profile updates and follow it, not invent a third.

## Error handling

- A tool call rejected by `authorize_scope!` returns the same
  `{ content: [...], isError: true }` shape every other `ToolError` produces
  — no new error format.
- `[]` means "full access" at the backend level, but the UI never *saves*
  `[]` — "all 14 checked" saves all 14 tool-name strings explicitly, not an
  empty array. This matters: if "select all" saved `[]`, a user who later
  unchecks just one box couldn't tell the backend "39 of 40... I mean 13 of
  14 tools, not full access" without first knowing `[]` was standing in for
  "all of them" — every subsequent save must be able to express exactly the
  current checkbox state as an explicit list. So `[]` stays reserved for
  "this token has never been scoped" (the state every pre-existing token is
  already in), and becomes unreachable from this UI once a user has saved
  here at least once — checking all 14 boxes and saving is not the same
  action as "reset to never-scoped," and this page doesn't need to offer
  the latter.

## Testing

- Backend: one shared spec proving `authorize_scope!` rejects a tool not in
  a non-empty `scopes` array (using one read tool and one write tool as
  representatives, not all 14) and proving an empty-`scopes` token is
  unaffected (existing specs already cover this implicitly, since none of
  them set `scopes` — worth one explicit spec making it a stated guarantee,
  not an accident of the fixtures never setting the field). One spec on
  `ProfilesController#update` confirming `scopes` persists and unrelated
  profile updates don't clear it.
- Frontend: a component spec for the new page covering the disabled state,
  the checkbox list rendering all 14 tools in the right groups, and the
  Save action firing the right API call with the right payload.

## Out of scope for this page

- Any UI for the account-wide `mcp_integration` toggle itself (still
  super-admin-only; a separate, larger question about whether account
  admins should get self-service control, not decided here).
- Per-account scoping (the token, and therefore scopes, are user-global by
  design — see Context above).
- Enforcement scopes for anything beyond "which tools this token may call"
  (e.g. restricting *which conversations/inboxes* a token can touch beyond
  what `ConversationPolicy`/tenancy already enforce) — not requested, not
  designed here.
