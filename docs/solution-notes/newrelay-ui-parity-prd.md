# PRD — Tenant dashboard UI parity (NewRelay)

**Status:** Draft · **Owner:** Dashboard UI · **Compared:** 2026-08-25
**Locked 2026-08-25:** do **not** update Workspace, Customer Engagement, or Reputation.
**Phase 0–1:** complete 2026-08-25. **Phase 2 PRD:** drafted (`crm-deals-pipelines-prd.md`); build blocked on §7.
**Source of truth (visual + IA):** [https://new-relay-ui.vercel.app](https://new-relay-ui.vercel.app)
**This app:** `app/javascript/dashboard/` (Vue 3, Relay tokens)

This is a **visual + information-architecture parity** PRD for the tenant
dashboard. It is not a Super Admin PRD and not a new-CRM-backend PRD.

**Success in one line:** remaining in-scope screens (Settings leftovers,
optional Relay AI copy, CRM/Marketing Coming soon leaves, ⌘K) match the
live mock — without touching Workspace, Customer Engagement, or Reputation.

---

## 1. Locked — do not change

Product decision (2026-08-25): these three areas stay as they are in this
app. Do not add, rename, restyle, or “visual QA” them as part of this PRD.

| Area | Keep as today | Do not do |
|---|---|---|
| **Workspace** | No Workspace sidebar group. Tasks stay under Contacts. No Dashboard home. No Calendar leaf. | Add Dashboard / Tasks / Calendar. Change default landing. |
| **Customer Engagement** | Inbox + Conversations tree in `Sidebar.vue`. Inbox views. Conversation onboarding / empty / composer. | Sidebar reorder, live `/conversations` restyle, Inbox empty restyle, strip `woot-*` on conversation chrome. |
| **Reputation** | Overview, Reviews, Video; Listings + Feedback behind demo flag; **Requests**; **Settings**. | Remap to Review Outreach / Integrations. Hide Feedback. Port live label set. |

Open decisions **1** (Workspace Dashboard vs Conversations home) and **5**
(live reputation labels) are **closed**: keep Conversations as landing;
keep current Reputation labels and routes.

---

## 2. Sources of truth (priority order)

| Priority | Source | Rule |
|---|---|---|
| 1 (IA + pixels) | https://new-relay-ui.vercel.app | Live snapshot wins **only for in-scope sections**. Deep links 404 (SPA) — load `/` then navigate. Root redirects to `/ecommerce/dashboard-1` (stub); ignore that landing. |
| 2 (markup) | `/Users/deependrasankhala/Documents/chandresh/NewRelay-UI/src/views/` | Port classes for in-scope screens only. No demo toggles. |
| 3 (how to port) | `app/javascript/dashboard/components-next/relay/DESIGN.md`, `TOKENS.md`, `NEWRELAY_PORTING_MAP.md` | Tokens 1:1. Never invent hex. Never translate to `n-*` / `woot-*`. |

**Ignore mock leftovers:** `/ecommerce/*`, `/todo/*`, `/project-management/*`,
`/original/*`, `/developers/*`, Designing demo, developer buttons.

---

## 3. Design system contract (in-scope screens only)

Same as `docs/solution-notes/settings-ui-newrelay-port-prd.md` §3.
User-facing AI name is **Relay AI**. **Never fabricate metrics.**

---

## 4. Sidebar IA — still in play vs locked

Source: `Sidebar.vue` `primaryMenuItems` (~line 265).

| Section | Mock | This app | This PRD |
|---|---|---|---|
| Workspace | Dashboard, Tasks, Calendar | Missing | **Locked out** |
| Customer Engagement | Inbox + Conversations tree | Match | **Locked out** |
| Reputation | Live: Outreach, Integrations, … | Requests, Settings, Feedback | **Locked out** |
| CRM & Sales | + Deals, Pipelines, Opportunities | Contacts + Companies | **In scope** (Coming soon or P2 CRM) |
| Marketing | + Funnels, LP, Forms, Surveys | Campaigns only | **In scope** (Coming soon leaves) |
| Relay AI | 7 items | Same 7; label `"Relay"` | **In scope** (copy only) |
| Analytics | Reports + 3 | Reports live; 3 `comingSoon` | Match — leave |
| Knowledge Base | 4 items under Portals | Same | Match — leave |
| Header ⌘K | Palette overlay | Full `/search` page | **In scope** |

---

## 5. Work plan (revised)

### Phase 0 — this sprint

- Settings leftover `woot-*`: already converted (see child PRD).
- `SIDEBAR.CAPTAIN` → **Relay AI** — done 2026-08-25.

**Removed from Phase 0:** conversations/inbox visual QA, conversation
`woot-*` strip, onboarding vs live `/conversations`.

### Phase 1 — remaining shell (no new backends)

1. ⌘K palette overlay — **done 2026-08-25.** Header search / ⌘K opens the
   existing `ninja-keys` CommandBar. Palette includes **Go to Search** so
   `/search` stays reachable. Fallback: if CommandBar is not mounted, the
   header still routes to `search`.
2. Coming soon leaves — **done 2026-08-25:** Deals, Pipelines,
   Opportunities; Funnels, Landing Pages, Forms, Surveys. Sidebar leaves
   without a `to` now render (also unblocks Analytics Coming soon leaves).
3. **Do not** add Workspace. **Do not** remap Reputation.
4. Floating Relay AI FAB — **removed 2026-08-25** (`CopilotLauncher` unmounted
   from `Dashboard.vue`). Copilot panel still opens from the conversation
   sidepanel switch. Shared settings loading spinner in `SettingsLayout.vue`
   no longer uses `woot-loading-state`.
5. Settings leftover widgets pass — **done 2026-08-25 (batches A–D):**
   - **A:** loading + delete/confirm → Spinner / `RelayConfirmModal`.
   - **B:** `Code.vue` Relay restyle; canned → next Editor; hljs tokens.
   - **C:** signature / business hours / pre-chat → next Editor.
   - **D:** `WootReports` → `ReportsShell`; report filters import
     `DatePicker` (dual-range kept — not swapped to single-date
     `RelayDatePicker`); teams Create/Edit use local `Wizard` import
     instead of `woot-wizard`.
   - **Out of this PRD:** conversation ReplyBox + AutomationActionInput
     stay on WootWriter; global `woot-code` tag name remains (component
     already Relay-styled).

### Phase 2 — CRM objects — **in progress (defaults approved 2026-08-25)**

PRD: `docs/solution-notes/crm-deals-pipelines-prd.md`. Schema/API first;
UI follows. Do not port mock dollars.

### Phase 3 — Campaign Analytics when metrics exist

---

## 6. Out of scope

- Workspace, Customer Engagement, Reputation (locked above)
- Super Admin (`docs/solution-notes/super-admin-ui-prd.md`)
- Building Funnels / LP / Forms / Surveys / Calendar as product
- Mock leftover routes
- Fabricating metrics

---

## 7. Open product calls (remaining)

| # | Question | Default |
|---|---|---|
| 1 | ⌘K palette vs Search page only? | **Palette** that can jump to Search |
| 2 | Deals / Pipelines / Opportunities: Coming soon or real CRM? | **Coming soon** |
| 3 | Floating Relay AI FAB? | **Closed — no FAB** (launcher unmounted) |

---

## 8. Related

- Settings leftover `woot-*`: `docs/solution-notes/settings-ui-newrelay-port-prd.md`
- CRM Phase 2: `docs/solution-notes/crm-deals-pipelines-prd.md`
- Super Admin: `docs/solution-notes/super-admin-ui-prd.md`
- Reputation (do not expand here): `docs/solution-notes/reputation-design-port.md`
