# FRD: MCP Server (Model Context Protocol)

**Status:** Planned
**Module:** newrelay custom (new integration surface, mounted in OSS core)
**Last updated:** 2026-09-08

---

## 1. What it is

**One-liner:** An MCP (Model Context Protocol) server mounted inside this Rails app at `/mcp`, letting a user connect their own AI agent (Claude, Cursor, etc.) to their Chatwoot account to read conversations/contacts and perform a small set of safe actions.

**Who uses it:** Account admin (turns the feature on for the account); any agent/user on that account, indirectly, via their connected AI client acting on their behalf.

---

## 2. How it works

1. Account admin enables the `mcp_integration` feature flag for their account (existing Features settings screen — no new UI).
2. User adds `https://<their-instance>/mcp` plus their existing personal `AccessToken` as a Bearer token to their MCP client (Claude Desktop, Cursor, etc.).
3. Client calls `tools/list` — server returns the tool catalog (§9).
4. Client calls `list_accounts` first to discover which accounts the token can see, since one token's owner may belong to more than one account.
5. Every subsequent tool call carries an explicit `account_id`. The server re-verifies the token owner is a member of that account and that the account's `mcp_integration` flag is on, before touching any data.
6. Read tools query existing finder/scopes directly. Safe-write tools (private note, label, assignment, priority) call the same service paths the REST API controllers already use.
7. Any failure (bad token, flag off, not a member, not found) returns a structured MCP tool error (`isError: true`) with a human-readable message — never a 500.

---

## 3. Data model

**Tables:** No new tables. `accounts.feature_flags` (existing bitfield column — one new bit registered). `access_tokens` gets two new **nullable** columns (see Migration below) — added now, unused by REST, so it's zero behavior change until Phase 3 uses them.

```
config/features.yml
  - name: mcp_integration (new entry, enabled: false by default)

access_tokens
  - scopes: string, array, default: [] (nullable/empty = full access, same as today)
  - last_used_at: datetime (nullable)
```

**Relationships:** No new associations. `AccessToken belongs_to :owner` (existing, polymorphic `User`/`AgentBot`) is the only lookup used.

**Migration file(s):** One new migration, `add_scopes_and_last_used_at_to_access_tokens`. Added in Phase 1 specifically so Phase 3 (OAuth 2.1 / scoped tokens) can issue rows against the same table instead of forking the auth model later — see architecture review note in §10.

---

## 4. Backend / API

**Routes:**
| Method | Path | Controller#action | Auth/permission |
|---|---|---|---|
| POST | `/mcp` | `Mcp::Server` (Rack app, `fast-mcp` gem — not a standard `ActionController`) | `Authorization: Bearer <AccessToken>`, resolved per-request; account membership + `mcp_integration` flag re-checked per tool call |

POST-only, no SSE transport in v1 (see §8 — `fast-mcp`'s SSE mode holds a Puma thread open and fights `rack-timeout`; not worth the risk for request/response tool calls).

**Models/services involved:**
- `app/mcp/tools/*.rb` (new — plain Ruby objects, `call(args)` + a JSON-schema constant; each wrapped by one thin `FastMcp::Tool` adapter so the gem stays swappable, not inherited from directly)
- `app/models/access_token.rb` (existing, read-only reuse; `scopes`/`last_used_at` columns added per §3, unused until Phase 3)
- `app/controllers/concerns/access_token_auth_helper.rb` (existing — pattern reused, not directly inherited, since the mount isn't an `ActionController`)
- `app/models/concerns/featurable.rb` / `Account#feature_enabled?` (existing, reused as-is)
- Auth hook sets `Current.mcp = true` alongside `Current.user`, so every write stamps its MCP origin for the Enterprise audit log (see §10)

**Background jobs:** None in v1 — all tool calls are synchronous request/response.

**External integrations:** `fast-mcp` gem (already resolves in `Gemfile.lock` as a transitive dep of `tidewave`; needs promoting to a direct `Gemfile` entry).

---

## 5. Frontend

**Vue components:** None new. The `mcp_integration` toggle surfaces automatically in the existing account Features settings screen, which is driven by `config/features.yml`.

**Store module(s):** None new.

**States handled:** N/A — no new UI surface. (MCP client-side errors are handled by the connecting agent, not this app's frontend.)

---

## 6. Test coverage (planned)

| Spec file | What it will cover |
|---|---|
| `spec/requests/mcp/auth_spec.rb` | Missing/invalid Bearer token → 401; `AgentBot`-owned token rejected |
| `spec/requests/mcp/feature_flag_spec.rb` | `mcp_integration` disabled for account → every tool call fails closed with a readable error |
| `spec/requests/mcp/tenancy_spec.rb` | Valid token, but user not a member of the requested `account_id` → rejected |
| `spec/requests/mcp/tools/*_spec.rb` | One happy-path spec per tool in the catalog (§9) |

**Coverage gaps observed:** N/A — nothing shipped yet.

---

## 7. Dev tools / dependencies actually used

- Backend gems: `fast-mcp` (~> 1.5.0). **Correction from the initial spec draft:** it currently resolves in `Gemfile.lock` only as a transitive dep of `tidewave`, which is `group :development` — so this is a genuinely new **production** dependency, not a free reuse. It also pins `rack (~> 3.1)`, which caps future Rack/Rails upgrades. Mitigated by wrapping it in thin adapters (see §4) rather than building tools directly against its classes.
- Frontend libs: none new
- External services: none new

---

## 8. Edge cases / failure modes (as designed)

| Scenario | Designed behavior |
|---|---|
| Missing/invalid Bearer token | MCP-level 401, no tool executes |
| Token valid, `mcp_integration` flag off for account | Every tool call fails closed with a human-readable error |
| Token valid, user not a member of requested `account_id` | Tool call rejected, same as REST API's existing membership guard |
| `AgentBot`-owned token used | Rejected — only `User`-owned tokens accepted in v1 |
| Unknown/deleted `conversation_id` / `contact_id` | MCP tool error (`isError: true`), not a 500 |
| Agent attempts an excluded action (reply, resolve/open/pending/snooze) | Tool does not exist in the catalog — client-side "unknown tool" error, not a permission error |
| Long-lived/streaming connection (SSE) | Not offered in v1 — POST-only, so no Puma thread is held open against `rack-timeout` |

---

## 9. Build phases

Each phase ships independently — Phase 2 does not start until Phase 1 is deployed and its specs pass, per this codebase's "least code change, happy path first" guidance.

**Phase 1 — Foundation + read tools**
| Item | Detail |
|---|---|
| Mount | `/mcp` route (POST-only, no SSE), `fast-mcp` gem promoted to a direct `Gemfile` entry, `Mcp::Server` boots |
| Auth | Bearer token → `AccessToken` lookup; `User`-only; `mcp_integration` flag check; sets `Current.mcp = true` |
| Migration | `access_tokens` gets nullable `scopes` + `last_used_at` columns — added now so Phase 3 doesn't need to fork the auth model |
| Feature flag | `mcp_integration` entry added to `config/features.yml` (disabled by default) |
| Tools | `list_accounts`, `list_conversations`, `get_conversation`, `list_contacts`, `get_contact`, `list_inboxes`, `list_agents`, `list_teams`, `list_labels` — each a PORO wrapped by a thin `FastMcp::Tool` adapter |
| Exit criteria | Auth/flag/tenancy specs pass; every read tool has a happy-path spec; manually verified against Claude Desktop or Cursor |

**Phase 2 — Safe writes**
| Item | Detail |
|---|---|
| Tools | `add_private_note`, `add_label`, `remove_label`, `assign_conversation`, `set_priority` |
| Audit | Writes stamp `Current.mcp` so MCP-originated changes are distinguishable from human agent actions in the Enterprise audit log |
| Exit criteria | Happy-path spec per tool; confirmed `add_private_note` cannot produce a customer-visible message under any input; confirmed audit stamp appears on a created note |

**Phase 3 — Deferred (not yet approved, no build date)**
| Item | Detail |
|---|---|
| Tools | `send_reply` (customer-visible), status changes (resolve/open/pending/snooze) |
| Also deferred | OAuth 2.1 (needed for Claude.ai web "Connectors") — the Phase 1 `scopes`/`last_used_at` columns mean this issues new token rows against the existing table rather than forking auth; `AgentBot`-owned tokens; centrally hosted multi-tenant endpoint; `prepend_mod_with` seam on the tool catalog for Enterprise per-plan tool filtering |
| Trigger to revisit | Phase 1+2 usage data shows real demand and no safety issues from the safe-write tools |

---

## 10. Open gaps / notes

**Architecture review (2026-09-08, `cto` review):** verdict *sound with caveats* — approved with two changes folded into Phase 1 above:
1. `AccessToken` has no scopes/expiry/`last_used_at` today, so Phase 3 OAuth would otherwise need to fork the auth model rather than extend it — fixed by adding the nullable columns in Phase 1 (§3, §9).
2. Safe-write tools (Phase 2) were unaudited — the same token already permits reply/resolve/delete via REST so leak blast radius is unchanged, but MCP-originated writes were indistinguishable from human ones in the Enterprise audit log — fixed by stamping `Current.mcp` on every write (§4, §9).

Also corrected: the initial spec's claim that `fast-mcp` carries "no version-conflict risk" because it's already in `Gemfile.lock` was misleading — it only resolves there via `tidewave`, a dev-only gem, so this is a genuine new production dependency (§7). Tools are built as POROs behind a thin adapter to keep it swappable.

- Bearer-token auth does not satisfy Claude.ai web's "Connectors" flow, which requires OAuth 2.1 — known limitation, deferred to Phase 3, no longer blocked on the token model (see above).
- `send_reply` and conversation status-change tools are deliberately deferred pending Phase 1+2 usage data (see §9, Phase 3).
- No Enterprise extension seam on the tool catalog yet (e.g. per-plan tool limits) — deferred to Phase 3; OSS-only mount is otherwise the right call for v1.
- This FRD documents a **planned** feature ahead of build, which is an exception to this folder's normal as-built scope (see `docs/frd/README.md` — new features are otherwise meant to use `docs/templates/feature-bible-template.md`). Superseded by an as-built rewrite once shipped.
- Full architecture/rationale: [`docs/superpowers/specs/2026-09-08-chatwoot-mcp-server-design.md`](../superpowers/specs/2026-09-08-chatwoot-mcp-server-design.md).
