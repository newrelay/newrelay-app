# PRD — CRM Deals / Pipelines / Opportunities (Phase 2)

**Status:** Draft · **Owner:** Product + Dashboard · **Created:** 2026-08-25  
**Parent:** `docs/solution-notes/newrelay-ui-parity-prd.md` (Phase 2)  
**Visual source:** [new-relay-ui.vercel.app](https://new-relay-ui.vercel.app) → Deals / Pipelines / Opportunities  
**Markup:** `NewRelay-UI/src/views/{deals,pipelines,opportunities}/*`  
**Do not start build** until product signs the open decisions in §7.

**Success in one line:** agents can create, stage-move, and list real deals linked to
Contacts/Companies — with Relay UI matching the mock’s table + board — without
fabricated metrics or mock dollars.

---

## 1. Context

Phase 0–1 of UI parity shipped **Coming soon** sidebar leaves for Deals,
Pipelines, and Opportunities. There is **no** deal/pipeline schema or API in
this app today. Contacts + Companies already exist and are the CRM anchor.

The live mock treats the three leaves as **views over the same sales objects**,
not three independent products:

| Leaf | Mock primary UI |
|---|---|
| **Deals** | Table (+ board toggle), stage metric chips, deal drawer |
| **Pipelines** | Kanban by stage, pipeline picker, aggregate chips |
| **Opportunities** | Table with amount / close date / priority / probability |

---

## 2. Goals / non-goals

### Goals (MVP)

1. Persist deals on an account with stages belonging to a pipeline.
2. List + board UIs on Relay tokens (no `woot-*`, no hardcoded hex).
3. Link a deal to optional Contact and/or Company.
4. Assign an owner (account user).
5. Create / edit / delete / change stage (board drag or form).
6. Empty states that match Relay patterns (no demo “Load mock data” in prod).

### Non-goals (MVP)

- Import CSV / templates / deal templates (mock buttons — defer).
- Fabricated sparklines, “vs last month” trends, Clearbit logos, pravatar.
- Separate Opportunity entity if it duplicates Deal (see §7).
- Calendar / Tasks / Workspace (locked out of parent PRD).
- Marketing funnels / forms / surveys.
- Revenue analytics dashboards (Phase 3).
- Custom stage probability engines, forecasting, quoting, invoices.

---

## 3. Recommended product model (MVP)

**One domain object: Deal.** Pipeline is a named set of ordered stages.
Opportunities and Deals are the same rows; Pipelines is the board of those rows.

```
Account
  └── Pipeline (name, position)          // default “Sales Pipeline”
        └── PipelineStage (name, position, color token, is_won?, is_lost?)
  └── Deal
        name, amount_cents, currency, close_on, priority, probability (0–100)
        pipeline_id, stage_id, owner_id (User)
        contact_id? (Contact), company_id? (Company)
        account_id
```

**Why not three tables:** mock data for Deals / Pipelines / Opportunities is the
same set of names/amounts/stages. Three entities would triple API + UI cost for
no user-visible win in MVP.

**Sidebar (after ship):** keep three leaves if product wants mock IA parity —
each routes to the same module with a different default view
(`?view=table|board` or dedicated route names that share one store). Or collapse
Opportunities into Deals (one leaf) — product call §7.

---

## 4. UX scope (port from mock, Relay only)

Follow `components-next/relay/DESIGN.md` + `TOKENS.md`. Reuse Companies index
patterns (`CompaniesIndex.vue`, create dialog, empty state) where they fit.

### Shared chrome

- Page title `text-base font-medium`; description `text-[13px] text-muted-foreground`.
- Primary CTA: New Deal (`RelayButton`).
- Pipeline switcher (if >1 pipeline).
- Filters / sort: stage, owner, close date — MVP can be simple chips + search.
- **Never** ship mock metric cards with fake trends. If metrics ship, they must
  be computed from real deals (count, sum amount, win rate from won stages).

### Deals view

- Table: name, company, stage badge, value, close date, owner, last activity
  (activity = `updated_at` until a real activity feed exists).
- Optional board toggle (same as Pipelines board).
- Row → detail drawer/sheet (overview fields only in MVP; no fake activity tabs).

### Pipelines view

- Kanban columns = stages; cards = deals; drag → update `stage_id`.
- Column header: stage name, count, sum(amount).

### Opportunities view (if kept as leaf)

- Same data as Deals table; columns emphasize amount, close date, priority,
  probability. No second create flow.

---

## 5. Backend sketch (OSS)

| Piece | Notes |
|---|---|
| Migrations | `pipelines`, `pipeline_stages`, `deals` (+ indexes on account_id, stage_id, owner_id) |
| Models | `Pipeline`, `PipelineStage`, `Deal` under `app/models/` |
| Seed default | On account create or first CRM visit: one “Sales Pipeline” with Lead → Qualified → Proposal → Negotiation → Won (+ Lost optional) |
| API | `Api::V1::Accounts::PipelinesController`, `…::DealsController` (CRUD + `update` stage) |
| Policy | Account users with CRM permission — reuse existing agent/admin patterns; no new role required for MVP |
| EE | Not EE-gated unless product later ties CRM to a plan feature flag |

Services: thin controllers → `Deals::CreateService` / update / move-stage if logic
grows; otherwise model validations + controller is enough for MVP.

**Specs required:** model + API happy/failure for create and stage move.

---

## 6. Frontend sketch

| Piece | Location |
|---|---|
| Routes | Under dashboard CRM group; replace `comingSoon` with real `to` |
| Pages | e.g. `routes/dashboard/deals/` or `crm/` — Index (table), Board, shared DealForm / DealDrawer |
| Store | Pinia store mirroring `stores/companies` |
| i18n | `en.json` only |

Wire sidebar keys already present (`SIDEBAR.DEALS` etc.) to real routes when
ready; remove `comingSoon: true`.

---

## 7. Open product decisions (block build)

| # | Question | **Recommended default** |
|---|---|---|
| 1 | Deal vs Opportunity as separate models? | **One model (Deal).** Opportunities leaf = alternate table columns / route. |
| 2 | Keep three sidebar leaves? | **Yes** — three routes, one store (mock IA parity). |
| 3 | Default stages? | Lead, Qualified, Proposal, Negotiation, Won, Lost. |
| 4 | Amount currency? | Account currency if exists; else `USD`. |
| 5 | Metrics row on first ship? | **Yes, computed only** (counts + sums). No sparklines / MoM until analytics Phase 3. |
| 6 | Deal ↔ Conversation link? | **Defer.** Optional `conversation_id` later. |
| 7 | Import? | **Defer.** |
| 8 | Plan / feature flag? | **No flag** for MVP unless billing requires it. |

**Build starts only after:** decisions 1–3 + 5 confirmed (or explicitly overridden).

---

## 8. Work plan (after approval)

1. **Schema + API + default pipeline seed** (behind routes not yet linked, or feature-ready).
2. **Deals table + create/edit drawer** (Relay).
3. **Pipelines board + drag stage**.
4. **Opportunities route** (reuse table; column set).
5. **Sidebar:** flip Coming soon → live routes.
6. **Empty states + computed metric chips.**

Do not port mock demo toggles. Do not add Workspace/Calendar.

---

## 9. Related

- Parent UI parity: `docs/solution-notes/newrelay-ui-parity-prd.md`
- Companies UI patterns: `app/javascript/dashboard/routes/dashboard/companies/`
- Porting map: `app/javascript/dashboard/components-next/relay/NEWRELAY_PORTING_MAP.md`
- UX IA (aspirational): `UX_ARCHITECTURE.md` § CRM & Sales
