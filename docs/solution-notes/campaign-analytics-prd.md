# PRD — Campaign Analytics (Phase 3)

**Status:** Approved (defaults) · **Owner:** Product + Dashboard · **Created:** 2026-08-25 · **Approved:** 2026-08-25  
**Parent:** `docs/solution-notes/newrelay-ui-parity-prd.md` (Phase 3)  
**Visual source:** [new-relay-ui.vercel.app](https://new-relay-ui.vercel.app) → Analytics → Campaign Analytics  
**Markup:** `NewRelay-UI/src/views/analytics/CampaignAnalyticsView.vue`  
**Build started 2026-08-25** with §7 recommended defaults (user “next”).

**Success in one line:** Analytics → Campaign Analytics shows **computed** campaign
performance from existing Campaign + Conversation (+ message) data — never
fabricated open/click rates from the mock.

---

## 1. Context

Phase 0–1 left **Campaign Analytics** as a Coming soon sidebar leaf. Live
campaigns already exist in this app (`Campaign` model, Marketing → Campaigns
UI for Live chat / SMS / WhatsApp).

The mock UI is an **email-marketing** dashboard (Sent / Opened / Clicked /
Conversion Rate + sparklines). Chatwoot campaigns are **inbox outreach**
(Website ongoing triggers, one-off SMS / Twilio / WhatsApp). Those email open
and click events are **not stored today**.

| Mock metric | Exists in this app today? |
|---|---|
| Total campaigns | Yes (`Campaign` count) |
| Sent | Partial — one-off sends happen via channel services; no first-class `sent_count` column |
| Opened / open rate | **No** |
| Clicked / click rate | **No** |
| Conversion rate | **No** (unless defined as attributed conversations) |
| MoM trend / sparklines | **No** time-series store |

**Attribution that does exist:**

- `campaigns` table + `campaign_status` / `campaign_type` / `inbox_id`
- `conversations.campaign_id` (conversations started from a campaign)
- Messages may carry `additional_attributes.campaign_id` (GIN index present)

---

## 2. Goals / non-goals

### Goals (MVP)

1. Live **Campaign Analytics** page under Analytics (flip Coming soon).
2. Summary chips computed only from DB:
   - Total campaigns
   - Active / completed / processing counts
   - Conversations attributed (`conversations.campaign_id`)
   - Optional: conversations per campaign in a table
3. Filter by channel (inbox type), status, date range on `campaigns.created_at`
   (or `scheduled_at` for one-off).
4. Relay UI (tokens only). Empty state when no campaigns.
5. Row click → existing campaign detail / list route when available.

### Non-goals (MVP)

- Fabricating Sent / Opened / Clicked / Conversion to match the mock.
- Sparklines / MoM trends without a metrics rollup table.
- Building Funnels / Landing Pages / Forms / Surveys (still Coming soon).
- Revenue Analytics / custom Dashboards (separate Phase).
- Full email ESP integration (SendGrid open/click webhooks) — own PRD if needed.
- Import / export of analytics CSV (defer).

---

## 3. Recommended MVP product model

**No new domain tables for v1.** Aggregate over existing rows.

```
Account
  └── Campaign (existing)
        └── Conversation (optional campaign_id)
```

**API sketch:** `GET /api/v1/accounts/:id/campaign_analytics`

Response (illustrative):

```json
{
  "payload": {
    "summary": {
      "total_campaigns": 12,
      "active": 4,
      "completed": 7,
      "processing": 1,
      "attributed_conversations": 86
    },
    "campaigns": [
      {
        "id": 1,
        "title": "...",
        "campaign_type": "one_off",
        "campaign_status": "completed",
        "inbox": { "id": 3, "name": "SMS", "channel_type": "..." },
        "scheduled_at": "...",
        "created_at": "...",
        "conversations_count": 40
      }
    ]
  }
}
```

Optional later (not MVP): `campaign_stats` daily rollup for sparklines once
product defines events worth counting.

---

## 4. UX scope (port layout, not fake numbers)

From mock: page header, metric chips row, searchable campaign table.

| Mock column | MVP mapping |
|---|---|
| Title / desc | `title` / `description` |
| Status | `campaign_status` |
| Channels | inbox channel type badge |
| Audience | audience size if JSON present; else "—" |
| Sent | **Omit** or show "—" until send receipts exist |
| Open / Click | **Omit** |
| Created | `created_at` / `scheduled_at` |
| Conversations | **Add** attributed conversation count |

Metric chips: Total · Active · Completed · Attributed conversations.  
Do **not** show Opened / Clicked / Conversion Rate until real event capture ships.

---

## 5. Backend sketch

| Piece | Notes |
|---|---|
| Controller | `Api::V1::Accounts::CampaignAnalyticsController#show` (or `#index`) |
| Service | `Campaigns::AnalyticsService#perform` — SQL counts + per-campaign `conversations` count |
| Policy | Same as campaigns (admin + agent) |
| Specs | Happy path + empty account |

Indexes: `conversations.campaign_id` already useful; no migration required for MVP.

---

## 6. Frontend sketch

| Piece | Location |
|---|---|
| Route | `accounts/:accountId/campaign-analytics` → `CampaignAnalyticsIndex.vue` |
| Sidebar | Analytics → Campaign Analytics `to` + remove `comingSoon` |
| Store/API | Thin client calling campaign analytics endpoint |
| i18n | `en.json` only |

Reuse Relay table / metric chip patterns from CRM (`DealMetricsRow`).

---

## 7. Open product decisions (block build)

| # | Question | **Recommended default** |
|---|---|---|
| 1 | Ship analytics **without** open/click, or wait for ESP events? | **Ship without** — computed chips + conversation attribution |
| 2 | “Conversion” = attributed conversations / campaigns? | **Defer label** — show conversation counts, do not call it conversion |
| 3 | Include ongoing Website campaigns in the table? | **Yes** — all campaign types |
| 4 | Date filter default | Last 30 days on `created_at` |
| 5 | Revenue Analytics / Dashboards in same sprint? | **No** — stay Coming soon |
| 6 | Persist daily rollups now? | **No** — query live for MVP |

**Decision 1:** approved — ship without open/click (conversation attribution only).

---

## 8. Work plan (after approval)

1. `Campaigns::AnalyticsService` + API + specs — **done 2026-08-25**.
2. Campaign Analytics page (metrics + table + empty state) — **done 2026-08-25**.
3. Sidebar: flip Coming soon → live route — **done 2026-08-25**.
4. (Later PRD) Send/open/click ingestion if product wants mock parity.

---

## 9. Related

- Parent: `docs/solution-notes/newrelay-ui-parity-prd.md`
- CRM Phase 2 (complete): `docs/solution-notes/crm-deals-pipelines-prd.md`
- Campaigns UI: `app/javascript/dashboard/routes/dashboard/campaigns/`
- Mock: `NewRelay-UI/src/views/analytics/CampaignAnalyticsView.vue`
