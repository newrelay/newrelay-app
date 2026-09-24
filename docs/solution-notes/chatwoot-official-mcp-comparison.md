# Does upstream Chatwoot have an official MCP server? — Research

**Date:** 2026-09-22
**Question:** Does the upstream `chatwoot/chatwoot` project (github.com/chatwoot/chatwoot) ship its own official MCP (Model Context Protocol) server — the reverse direction of what we built (external AI clients like Claude Desktop/Claude Code/Cursor connecting *into* Chatwoot to read conversations/contacts and take safe actions)? If not, what do they have instead, and does anything they've built change our Phase 3 OAuth 2.1 plan (`docs/frd/26-mcp-server.md`)?

**One-line answer: No.** Upstream `chatwoot/chatwoot` does **not** ship an official MCP server exposing Chatwoot data/tools to external AI agents. The only in-repo use of the `fast-mcp` gem is via `tidewave`, a **development-only** gem (local Rails dev-tooling, not a Chatwoot product feature). A community contributor built the *reverse* direction — Captain (Chatwoot's own AI agent) acting as an **MCP client** connecting *out* to external MCP servers — but that PR was closed unmerged. Several unofficial third-party projects exist on GitHub that turn the Chatwoot REST API into an MCP server, none endorsed by the Chatwoot team.

---

## 1. What upstream actually has

### 1.1 `fast-mcp` gem is present, but only via `tidewave` (dev tooling, not a product feature)

`Gemfile.lock` on `chatwoot/chatwoot`'s default branch lists `fast-mcp (1.5.0)` as a dependency — but it is pulled in transitively by the `tidewave` gem, not used directly by any Chatwoot application code:

```
tidewave (0.2.0)
  fast-mcp (~> 1.5.0)
  rack (>= 2.0)
  rails (>= 7.1.0)
```
Source: `Gemfile.lock` on `chatwoot/chatwoot@main`, fetched via `gh api repos/chatwoot/chatwoot/contents/Gemfile.lock` (2026-09-22).

`tidewave` is declared only inside `group :development do ... end` in `Gemfile`:
```ruby
group :development do
  gem 'annotaterb'
  gem 'bullet'
  ...
  gem 'tidewave'
end
```
Source: `Gemfile` on `chatwoot/chatwoot@main`, same fetch.

[Tidewave](https://tidewave.ai) is a third-party Rails gem that runs an MCP server for **local development only** — it lets a coding-assistant (e.g. Claude Code) introspect a *running dev instance* of the Rails app (routes, models, logs) while a developer is coding. It is not mounted in production, not customer-facing, and has nothing to do with Chatwoot exposing conversations/contacts/etc. to end-user AI agents. A repo-wide tree search (`gh api repos/chatwoot/chatwoot/git/trees/main?recursive=true`) found **zero** paths containing "mcp" outside `Gemfile(.lock)` and unrelated `pnpm-lock.yaml`/test-fixture string matches — i.e. no `app/mcp`, `lib/mcp`, or similar directory exists upstream.

### 1.2 Captain "MCP client" feature — proposed by the community, closed unmerged

This is the closest upstream ever got to "MCP," and it's the **opposite direction** from our feature:

- **Issue:** [`chatwoot/chatwoot#14382` — "Support MCP servers integration in Captain AI Agents"](https://github.com/chatwoot/chatwoot/issues/14382) (opened by a community user). Asks for Captain (Chatwoot's built-in AI support agent) to act as an **MCP client**, connecting *outward* to external MCP servers (CRMs, ERPs, billing systems) so Captain could use their tools — not for Chatwoot to expose *itself* as an MCP server.
- **PR:** [`chatwoot/chatwoot#13456` — "feat(captain): Add MCP server integration for external tool providers"](https://github.com/chatwoot/chatwoot/pull/13456), by community contributor `Kenth06`. Implemented: `enterprise/app/models/captain/mcp_server.rb`, `assistant_mcp_server.rb`, `Captain::Mcp::ClientService`, `Captain::Mcp::DiscoveryService`, an `McpTool` adapter, an admin UI for registering MCP servers (Bearer/API-Key/Header auth) per Captain assistant, and SSRF protections. Feature-flagged behind `captain_mcp`. 132 RSpec tests included.
- **Outcome — closed, not merged.** Chatwoot maintainer `aakashb95` commented: *"there are a few blockers for merging this PR, architectural and structural... this is on our roadmap but not an immediate priority."* The PR went idle and was ultimately closed by the same maintainer: *"I'm closing this for now since the PR is too large to review and has been inactive for several months. If we decide to pick this up again, we can start with a fresh discussion and smaller PRs."*
  Source: PR comment thread, `gh pr view 13456 --repo chatwoot/chatwoot --json comments` (2026-09-22); closed by `aakashb95`, closedAt `2026-07-16`.

So: Captain-as-MCP-client is on Chatwoot's roadmap (unprioritized), not shipped. There is no work, proposal, or roadmap mention of Chatwoot-as-MCP-server (the direction we built) in this thread or anywhere else found.

### 1.3 Chatwoot CLI "agent skill" — a CLI wrapper, explicitly not an MCP server

Chatwoot's developer docs (developers.chatwoot.com) document a **Chatwoot CLI** with an installable "agent skill" for coding tools:

> "Install the Chatwoot CLI agent skill so coding tools like Claude Code, Cursor, and Codex can use chatwoot effectively."
> Install via `npx skills add chatwoot/cli` (skills.sh).
Source: <https://developers.chatwoot.com/cli/agent-skill.md> (fetched 2026-09-22).

This is a **skill file that teaches an agent to shell out to the `chatwoot` CLI binary** (e.g. `chatwoot conv 123 reply "..."`, JSON output via `-o json`, `hc articles` for help-center search) and make raw REST API calls when needed — it is not an MCP server, does not speak the MCP protocol, and is explicitly described in the doc as distinct from MCP. Auth is via `chatwoot auth login` (interactive) or a `CHATWOOT_API_KEY` env var for non-interactive agents. The developer docs' top-level nav (Installation, Development Guide, Chatwoot CLI, API Reference, Architecture Guide — via <https://developers.chatwoot.com/introduction>) has no MCP or "AI agent" section.

### 1.4 Changelog / blog

The official changelog (<https://www.chatwoot.com/changelog>) has no entry for an MCP server, Model Context Protocol, or Claude/external-AI-agent integration as of 2026-09-22. Its only AI-related entries are Captain (native assistant), OpenAI-compatible endpoint config, Captain image analysis, and Langfuse tracing — none of these are MCP.

---

## 2. Unofficial / third-party Chatwoot MCP servers (community, not endorsed by Chatwoot)

None of these are part of `chatwoot/chatwoot` or linked from official docs. Listed for completeness since they answer "does an MCP server for Chatwoot exist anywhere":

| Project | Tools | Auth | Transport | Packaging | Status |
|---|---|---|---|---|---|
| [`hugoblanc/chatwoot-mcp`](https://github.com/hugoblanc/chatwoot-mcp) | 4: `chatwoot_list_conversations`, `chatwoot_get_conversation`, `chatwoot_list_messages`, `chatwoot_create_message` | API access token (Bearer) or JWT email/password login | stdio (standard MCP SDK default) | npm package (`npx chatwoot-mcp-server`) | Third-party; 9 stars / 7 forks |
| [`StackLab-Digital/chatwoot_mcp`](https://github.com/StackLab-Digital/chatwoot_mcp) | 5: `chatwoot_setup`, `chatwoot_list_inboxes`, `chatwoot_list_conversations`, `chatwoot_send_message`, `chatwoot_update_conversation` | OAuth-style config (`baseUrl` + `apiToken`) with KV namespace storage | SSE over HTTP (`/sse`) | Node.js local, Docker Compose, or Cloudflare Workers | Third-party; 11 stars / 7 forks; **archived by owner 2026-07-17, read-only** |
| `mohnori/chatwoot-mcp` (via Glama) | Conversation read/reply, date-range filtering | Not confirmed from primary source (not independently fetched) | Not confirmed | Not confirmed | Third-party (per Glama listing) |
| `renatoascencio/mcp-chatwoot` (via Glama/websearch) | Reported ~133 tools spanning Application, Public, Platform, Enterprise, Help Center APIs, multi-account support | Not confirmed from primary source (not independently fetched) | Not confirmed | Not confirmed | Third-party (per Glama listing) — **not independently verified, treat as unconfirmed** |

The last two rows were only surfaced via web search / Glama directory listings, not fetched from their own repos — flagged as unconfirmed rather than guessed at.

---

## 3. Comparison against our 16-tool MCP server

Our implementation: `app/tools/mcp/*.rb` (16 concrete tool files + `base_tool.rb`), fast-mcp gem, mounted at `/mcp`, Bearer token via `AccessToken`, per-tool scopes, feature-flagged via `mcp_integration`. See `docs/frd/26-mcp-server.md`.

| | Our fork (NewRelay/DakshAI) | Upstream `chatwoot/chatwoot` |
|---|---|---|
| Chatwoot exposed as an MCP **server** (external agents connect in) | **Yes** — 16 tools (`list_accounts`, `list_conversations`, `get_conversation`, `list_contacts`, `get_contact`, `list_inboxes`, `list_agents`, `list_teams`, `list_labels`, `add_private_note`, `add_label`, `remove_label`, `assign_conversation`, `set_priority`, `send_reply`, `set_status`) | **No** — nothing shipped, nothing proposed |
| Chatwoot/Captain as an MCP **client** (connects out to external tool servers) | Not built | Proposed (issue #14382), implemented in a community PR (#13456), **closed unmerged**, acknowledged as unprioritized roadmap item |
| Gem | `fast-mcp` (direct dependency, used at `app/tools/mcp`) | `fast-mcp` present only transitively via `tidewave` (dev-only, unrelated purpose) |
| Auth model (shipped) | Bearer token via existing `AccessToken` model, per-tool scopes | N/A — no shipped MCP server. The closed Captain-MCP-client PR used Bearer/API-Key/Header auth for *outbound* connections to third-party servers, not inbound auth for a Chatwoot-hosted server — not directly comparable. |
| OAuth 2.1 solved anywhere in upstream for MCP inbound auth | Not found | Not found — no evidence upstream has designed or built inbound OAuth 2.1 for an MCP server (because they have no such server). No Doorkeeper-for-MCP or similar work located. |
| Transport | HTTP POST, no SSE in v1 (per our FRD) | N/A for inbound; the closed Captain PR is about outbound client connections |
| Feature flag | `mcp_integration` | N/A (no such feature exists); the closed PR used `captain_mcp` for its client-side feature |
| CLI/agent-skill alternative | Not built | Ships a `chatwoot` CLI + installable "agent skill" (`npx skills add chatwoot/cli`) that lets coding agents shell out to CLI commands / REST API — functionally different from MCP (no `tools/list`, no structured JSON-schema tool calls, no MCP transport) |

### What they have that we don't
- A CLI + "agent skill" pattern for coding tools (Claude Code/Cursor/Codex) to drive Chatwoot via shell commands — different mechanism (CLI wrapper, not MCP), and it's for account/help-center admin tasks from a terminal, not an always-on MCP tool server.
- An open (unmerged) design for Captain-as-MCP-**client**, which is a different feature surface than ours (agents *using* external tools vs. external agents *using* Chatwoot).

### What we have that they don't
- An actual, shipped MCP **server** exposing Chatwoot conversation/contact/inbox/label data and safe write actions (reply, private note, label, assign, priority, status) to external AI clients (Claude Desktop, Claude Code, Cursor) via the standard MCP tool-call protocol. Nothing equivalent exists upstream, official or community-endorsed.

### Implication for our Phase 3 (OAuth 2.1) plan
Upstream has **not** solved inbound OAuth 2.1 for an MCP server — because they don't have an MCP server to protect. There is no Doorkeeper-for-MCP integration, no prior art, and no roadmap signal to borrow from. Our Phase 3 OAuth 2.1 design (per `docs/frd/26-mcp-server.md`) will need to be built from scratch or by evaluating `doorkeeper` (already likely present for other OAuth flows in this codebase — not verified as part of this research) against the MCP OAuth 2.1 spec directly, not by porting an upstream Chatwoot pattern.

---

## Sources

- `Gemfile`, `Gemfile.lock` — `chatwoot/chatwoot@main`, fetched via GitHub API 2026-09-22
- Repo tree search — `gh api repos/chatwoot/chatwoot/git/trees/main?recursive=true`, 2026-09-22 (no `mcp`-named paths found)
- [`chatwoot/chatwoot#14382`](https://github.com/chatwoot/chatwoot/issues/14382) — "Support MCP servers integration in Captain AI Agents"
- [`chatwoot/chatwoot#13456`](https://github.com/chatwoot/chatwoot/pull/13456) — "feat(captain): Add MCP server integration for external tool providers" (closed unmerged, 2026-07-16)
- <https://developers.chatwoot.com/cli/agent-skill.md> — Chatwoot CLI agent skill docs
- <https://developers.chatwoot.com/introduction> — developer docs nav/index
- <https://www.chatwoot.com/changelog> — official changelog (no MCP entries as of 2026-09-22)
- <https://github.com/hugoblanc/chatwoot-mcp> — third-party MCP server
- <https://github.com/StackLab-Digital/chatwoot_mcp> — third-party MCP server (archived 2026-07-17)
- This repo: `app/tools/mcp/*.rb`, `docs/frd/26-mcp-server.md` — our own implementation, for the comparison table
