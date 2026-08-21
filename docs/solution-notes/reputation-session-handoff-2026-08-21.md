# Reputation — Session Handoff (2026-08-21)

Snapshot of what shipped this session. Living trackers stay authoritative:
`reputation-roadmap.md` (versions), `reputation-demo-inventory.md` (Demo items),
`reputation-design-port.md` (design port lessons).

## TL;DR
Every roadmap item **v1.0 → v3.0 now has a lean backend.** The whole flow runs offline via a
**mock review provider** (flip one env var when Google approval lands). Demo surfaces stay gated
behind `REPUTATION_DEMO_SURFACES`; each un-backed element carries an amber **Demo** badge that
disappears when real data is present.

## Shipped this session

### Mock provider spine (de-risks v1.0)
- `app/services/reputation/providers/mock.rb` — fake `list_reviews` + `publish_reply`.
- `providers.rb` routes to Mock when `REPUTATION_GOOGLE_PROVIDER=mock`; `skip_oauth?` = gmbapi || mock
  (connect with just a location_id, no OAuth).
- `review_request_send_service.rb#deliver_mock` — review-request send/receive works without Twilio/SMTP
  (logs the link, marks request completed).
- Frontend flag `reputationGoogleViaGmbapi` covers `%w[gmbapi mock]`.
- **Switch to real Google:** set `REPUTATION_GOOGLE_PROVIDER=google` — zero other changes.

### v2.0 Listings (lean)
- Table `reputation_listings` + `Reputation::Listing` + `listings_controller` (index/create/destroy) +
  `Account#reputation_listings` + route.
- `ListingsPage.vue` loads `GET /reputation/listings` (mock fallback, Demo badge only when mock);
  Add-Listing modal `POST`s.
- **Deferred (still Demo/computed on FE):** optimization %, rating/review rollups, per-platform sync
  (build on the v1.0 provider), Listing Detail page.

### v2.1 Feedback — confirmed already complete
- Public `POST /reputation/feedback` (creates submission, marks request completed) + dashboard
  `GET /reputation/feedback` + `FeedbackPage.vue` wired + sidebar route correct. Nothing outstanding.

### v3.0 Share Report (lean)
- Table `reputation_reports` (token + config jsonb) + `Reputation::Report` (auto token).
- Dashboard `reports_controller#create` → returns `share_url`.
- **Public** `Reputation::ReportsController#show` renders a printable HTML report at
  `GET /reputation/reports/:token` from live `SummaryBuilder` data.
- `ShareReportModal.vue`: Generate → POST, Open Report → opens link, Copy Link → real URL.
- **Deferred (Demo choices in wizard):** server-side PDF/PNG/CSV, email delivery, link expiry, download counts
  (browser print-to-PDF covers "PDF" for now).

### v3.0 AI Sentiment + Insights
- `Reputation::AiInsightsService` (inherits enterprise `Llm::BaseAiService`, same as `AiDraftService`) —
  ONE LLM call over ≤50 recent reviews → `{sentiment 0-100, insights:[{title,text}]}`.
- `ai_insights_controller#show` (`GET /reputation/ai_insights`) — cached per account per day
  (`Rails.cache`, `skip_nil: true`).
- `OverviewPage.vue` fetches it in `loadData`; real sentiment %/bullets replace mock + drop Demo badge,
  mock fallback when no LLM / no reviews.

## Migrations applied
`reputation_listings` (…150000) and `reputation_reports` (…160000) — both migrated (exit 0), schema.rb + model
annotations updated. AI insights needs no migration.

## Verification status (important)
- Ruby syntax ✅ all new files; ESLint ✅ all touched Vue.
- **No live browser render** — dev server is remote/Docker; Rails boot is slow (migrations run, `rails runner`
  times out on boot, not failure).
- **AI insights not run against a live LLM** — JSON-parse + cache path mirror the working `AiDraftService`,
  but no real model round-trip was exercised here. Verify before promoting the flag in prod; confirm LLM budget
  (one call per account per day).

## Next candidates (all optional, all deferred above)
- Listings: per-platform sync + optimization/rating rollups (needs the v1.0 provider), Listing Detail page.
- Share Report: real PDF/PNG export + email delivery.
- Promote `REPUTATION_DEMO_SURFACES` per-account once each surface is validated with real data.
