# Reputation — Demo/Mock Inventory & Wiring Plan

What is currently **Demo (mock)** in the Reputation feature, and the plan to make each real.
Convention: every mock element carries a visible **`Demo`** badge; all mock values live in a `mock`/`mockX`
object at the top of each file. **Delete the mock key + its `Demo` badge when the real source lands.**

## Backend that ALREADY exists (real APIs — just reconnect the UI)
`app/controllers/api/v1/accounts/reputation/`:
`integrations`, `reviews`, `review_requests`, `templates`, `video_testimonials`, `widgets`.
→ Anything these serve can be REAL today; the front-end was switched to mock for the design pass.

## Inventory

| # | Item | File | Backend status | Action |
|---|------|------|----------------|--------|
| 1 | Avg Rating, Total Reviews, Recent Reviews, Platform rating+count | `pages/OverviewPage.vue` (`mock`) | **Exists** (`/reviews`, `/integrations`) | Re-wire axios → compute from real reviews |
| 2 | Reviews list + reply/ignore/AI-draft | `pages/ReviewsPage.vue` (`reviews = ref([...])`) | **Exists** (`/reviews`, `/:id/reply|ignore|ai_draft`) | Replace hardcoded array with axios load |
| 3 | Video testimonials + outbound requests | `pages/VideoTestimonialsPage.vue` (`mockVideos`) | **Exists** (`/video_testimonials`, `requests_index`, `dispatch_request`) | Replace mock with axios (page had this before) |
| 4 | Requests funnel + logs (mock fallbacks) | `pages/RequestsPage.vue` (3 axios + `mockCustomers`) | **Exists** (`/review_requests`) | Drop the 3 mock fallbacks, rely on axios |
| 5 | Widgets (mock fallbacks) | `pages/WidgetsPage.vue` (4 axios + mock) | **Exists** (`/widgets`) | Drop mock fallbacks |
| 6 | **Reputation Score** 85/100 +3pts | `OverviewPage` (`mock.reputationScore`) | **None** | Define server-side score formula → endpoint |
| 7 | **AI Sentiment** 92% | `OverviewPage` (`mock.sentiment`) | **None** | Per-review sentiment (LLM) → aggregate |
| 8 | Card deltas (+0.2, +12%, +3pts) | `OverviewPage` | **None** (no history) | Daily snapshots table → month-over-month |
| 9 | Review Trend bars | `OverviewPage` | **Derivable** (reviews have `reviewed_at`) | Compute from real reviews — no new backend |
| 10 | Relay AI Insights (3 bullets) | `OverviewPage` (`mock.insights`) | **None** | LLM summary over recent reviews (cache daily) |
| 11 | Platform Breakdown **Trend** column | `OverviewPage` / `ListingsPage` | **None** (no history) | Same snapshots table as #8 |
| 12 | **Listings** (locations, platforms, sync %, optimization) | `pages/ListingsPage.vue` (`listings`, `stats`) + dropdowns/modals | **None** (whole feature) | New model + `listings_controller` + platform sync |
| 13 | **Share Report** wizard | `components/ShareReportModal.vue` | **None** | Report-builder service (render→PDF/PNG→link) |
| 14 | Feedback page | sidebar "Feedback" → `reputation_requests` | **Partial** (public `feedback#create` only) | New feedback dashboard controller + page |

## Plan (phased — each phase removes Demo badges as it lands)

### Phase 1 — Reconnect existing backends (front-end only, ~1 day, no server work)
Items **1–5, 9**. These backends already exist; the design pass swapped them to mock.
- Overview/Reviews/Video: restore the axios load (`GET /reputation/reviews`, `/integrations`, `/video_testimonials`),
  feed real data into the **new** design components, keep the `mock` object ONLY for #6,7,8,10,11.
- Review Trend (#9): compute from real `reviewed_at` (page already had `reviewTrend`) → drop its Demo.
- Requests/Widgets: delete the mock fallbacks.
- **Outcome:** most numbers become real; Demo badges shrink to the derived-metric + new-feature cards.

### Phase 2 — Derived metrics (backend, ~2–3 days)
Items **8, 11, 6**.
- Add a daily `reputation_snapshots` table (account_id, platform, date, reviews_count, avg_rating, response_rate),
  populated by a cron job (reuse `Reputation::SyncAllReviewsJob` cadence). → powers deltas (#8) and platform trend (#11).
- Reputation Score (#6): server-side formula (e.g. weighted avg_rating + response_rate + review velocity) → add to the
  reviews/overview summary endpoint. Remove its Demo.

### Phase 3 — AI features (backend + LLM, ~3–5 days)
Items **7, 10**.
- Sentiment (#7): batch-classify each review's sentiment (existing LLM integration used by `ai_draft`), store on the review,
  aggregate % positive. Remove Demo.
- AI Insights (#10): daily LLM summary over recent reviews (themes, action items), cache per account. Remove Demo.

### Phase 4 — New features (full backend, ~1–2 weeks each)
Items **12, 13, 14**.
- **Listings (#12):** `Reputation::Listing` model (name, address, platforms, optimization_score, last_sync) +
  `listings_controller` (index/create/sync) + per-platform sync jobs (Google Business Profile, etc.).
  Repoint `ListingsPage` axios; keep dropdowns/modals; drop page Demo badge.
- **Share Report (#13):** report-builder service — render selected sections server-side to PDF/PNG, store the file,
  return a signed share link; a share endpoint (email/link). Wire `ShareReportModal` submit → endpoint. Drop Demo.
- **Feedback (#14):** dashboard `feedback_controller#index` over the public feedback submissions + a `FeedbackPage.vue`;
  repoint the sidebar "Feedback" item (currently → `reputation_requests`).

## How to apply (per item, mechanically)
1. Build/confirm the endpoint (Phases 2–4) or locate the existing one (Phase 1).
2. In the page `<script>`: add the axios load, map the response into the same shape the template already uses
   (the mock object documents the exact fields to return).
3. Delete that key from the `mock` object **and** its `Demo` badge in the template.
4. Lint (`npx eslint <file>`); the page keeps its design, now on real data.

## Notes / caveats
- OverviewPage is under active edit (multi-session). Coordinate before large edits there.
- i18n is still deferred feature-wide (bare strings) — separate task from this Demo→real work.
- Provider reality: real Google reviews flow through the GMBapi/Google adapter (`REPUTATION_GOOGLE_PROVIDER`);
  once reviews actually sync, Phase-1 items populate on their own.
