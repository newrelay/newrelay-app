# FRD: Reputation Management

**Status:** Shipped (Google, mock-mode default), Partial (Facebook adapter stubbed, real Google API pending approval)
**Module:** newrelay custom
**Last updated:** 2026-09-07

> Consolidated FRD covering the whole Reputation module (integrations, listings, reviews, requests, feedback funnel, reports, widgets, video testimonials) — same "overview" treatment as [05-channels.md](05-channels.md), given the module's size (14 controllers, 14 models, 8 services, 8 jobs). Supersedes the planning-stage `docs/solution-notes/reputation-management-feature-bible.md` (aspirational, many `[fill]` placeholders) — this reflects what's actually built. Prior solution notes (`reputation-*.md`) remain useful for design/rollout history but this file is the as-built reference going forward.

---

## 1. What it is

**One-liner:** Businesses/agencies connect Google Business Profile listings, manage and AI-draft-reply to reviews from one dashboard, send review-request campaigns that route unhappy customers to private feedback instead of a public review, track a reputation score over time, embed a review widget on their site, and collect video testimonials.

**Who uses it:** Agency admins (manage multiple client listings), business owners (single listing), end customers (leave reviews/feedback/testimonials via public, unauthenticated links).

---

## 2. How it works

### Provider abstraction (the key architectural decision)
`Reputation::Providers.adapter_for(integration)` resolves a read/reply adapter per integration. Controlled by `REPUTATION_GOOGLE_PROVIDER` env var:
- `google` (default in production) → real Google Business Profile API adapter (`Reputation::Providers::Google`)
- `mock` → `Reputation::Providers::Mock`, fully offline fake data, **no OAuth required at all** (`skip_oauth?` short-circuits the connect flow)

This exists because Google's GBP API access approval has historically taken 1-2+ weeks (per the original feature bible) — mock mode lets the entire flow (connect → sync → reply → widget → reports) be built, demoed, and even used in a live "Demo" mode without waiting on Google. A `Reputation::PublicReviewsController` (Google-styled public review page) only exists to make mock mode end-to-end testable by real people. `Facebook` is a stubbed adapter case in the same dispatcher, not confirmed fully implemented.

### Listings & Integrations
1. `Reputation::Listing` is the business location record (name, address, category, hours, social links, photos via `has_many_attached`) — richer than a bare integration, since one listing can end up connected to multiple provider integrations.
2. `Reputation::Integration` is the actual OAuth/API connection (`provider`, `location_id`, tokens, `status: active/disconnected`), optionally linked to a `Listing`. Unique per `(account_id, provider, location_id)`.
3. `Reputation::ListingMember` assigns specific users to a listing (agency use case — client-specific access).
4. `Reputation::IntegrationRequest` lets a user request a provider that isn't yet supported (`platform`, `email`, `notes`) — a lightweight "vote for this integration" form, not an actual connection.

### Reviews & replies
5. `Reputation::ReviewSyncJob` (per-integration) / `SyncAllReviewsJob` (fan-out) pull reviews via the resolved provider adapter, upserting into `Reputation::Review` (unique on `account_id, external_id, provider`).
6. `Reputation::Review.status` enum (`pending / replied / ignored`) tracks reply workflow state.
7. `Reputation::AiDraftService` generates an AI-suggested reply (`GET .../reviews/:id/ai_draft`); the agent can edit before publishing.
8. `POST .../reviews/:id/reply` → `Reputation::ReplyPublisherJob` posts the reply back through the provider adapter and updates status to `replied`.

### Review Requests & the gated feedback funnel
9. Admins build `Reputation::Template`s (`template_type: standard` or video-invite, `channel`, `subject`/`body`).
10. `Reputation::ReviewRequestSendService` (immediate) / `DispatchScheduledRequestsJob` (cron, for `scheduled_at` requests) sends a request to a contact with a unique `token`, tracked through `sent → clicked → completed` via `Reputation::ReviewRequest`.
11. **The gating logic (this is the actual differentiator vs. a plain review-request tool):** the public link the customer clicks does NOT go straight to Google. `Reputation::FeedbackController#create` (public, token-authenticated via `review_request.live_for_public_submit?`) captures a private rating first. Low ratings become a `Reputation::FeedbackSubmission` (private, visible only in-dashboard) instead of ever reaching the public review platform — protecting the business's public rating from unhappy customers while still capturing the feedback. High ratings presumably redirect onward to the actual Google review page (not fully traced in this pass — see gap below).

### Score, snapshots, reports, widgets
12. `Reputation::ScoreCalculator` computes a weighted 0-100 score as of a given date: **50 pts** avg rating (out of 5), **30 pts** reply rate, **20 pts** review velocity (last-30-days count, capped at 10). Pure function over an in-memory review set — no DB dependency, easy to test (confirmed: `score_calculator_spec.rb` exists).
13. `Reputation::CaptureSnapshotsJob` (cron) runs the calculator daily and persists to `Reputation::Snapshot` (one row per `account, provider, captured_on`) — this is what powers trend charts.
14. `Reputation::Report` generates a shareable, token-linked report (`Reputation::PublicReportsController`/`reputation/reports` public route) — likely a client-facing PDF/web summary for agencies to send clients.
15. `Reputation::Widget` is an embeddable review carousel/grid for the business's own website (`style`, `min_rating` filter, `hide_watermark`, public token-based fetch via `Reputation::PublicWidgetsController`).

### Video Testimonials
16. `Reputation::VideoTestimonial` — a customer records a video via a public token link (`status: pending → consented → approved/rejected → published`), can optionally originate from a `review_request_id` (unique — one video per request). Tracks `views`, has AI-generated `ai_insights` (via `Reputation::VideoInsightsService`/`VideoInsightsJob`), and staff can `add_note`/`analyze` on it.

---

## 3. Data model

14 tables, all under the `reputation_*` prefix. Key ones (see §2 for behavior):

```
reputation_listings         - business profile: name, address, hours (jsonb), social_links (jsonb), photos (ActiveStorage)
reputation_listing_members  - user ↔ listing access (unique per listing+user)
reputation_integrations     - OAuth/API connection: provider, location_id (unique per account+provider+location), tokens, status
reputation_integration_requests - "please add this platform" requests (no real connection)
reputation_reviews          - synced review cache: external_id (unique per account+provider), rating, status (pending/replied/ignored)
reputation_review_replies   - draft/published replies to reviews (status, published_at)
reputation_templates        - review-request message templates (channel, template_type)
reputation_review_requests  - sent invites: token (unique), status (sent/clicked/completed), scheduled_at, destinations (jsonb)
reputation_feedback_submissions - private low-rating feedback (gated funnel), linked to a review_request
reputation_widgets          - embeddable widget config: token (unique), style, min_rating, hide_watermark
reputation_reports          - shareable report config: token (unique), config (jsonb)
reputation_snapshots        - daily score/metrics history: unique per account+provider+captured_on
reputation_settings         - one row per account, jsonb config (singleton via unique index)
reputation_video_testimonials - video collection: token (unique), status lifecycle, ai_insights (jsonb)
```

---

## 4. Backend / API

**Authenticated routes** (`/api/v1/accounts/:account_id/reputation/*`):
| Resource | Key actions |
|---|---|
| `reviews` | `index`, member `reply`, `ai_draft` (GET), `ignore` (PATCH) |
| `integrations` | `index/create/destroy`, collection `google_locations`, `oauth_state`, `sync_all`, member `sync` |
| `templates` | full CRUD |
| `integration_requests` | `create` |
| `review_requests` | `index/create` |
| `feedback` | `index` (dashboard view of private submissions) |
| `listings` | full CRUD + nested `members`, member `activities`, `upload_photos`/`destroy_photo` |
| `reports` | `create` |
| `summary`, `ai_insights`, `settings` | singleton `show`/`update` |
| `widgets` | full CRUD |
| `video_testimonials` | `index/update/destroy`, collection `dispatch_request`/`requests_index`/`export`, member `add_note`/`analyze` |

**Public routes** (unauthenticated, token or account-id based): `reputation/oauth_callbacks` (Google OAuth redirect target), `reputation/public_video_testimonials`, `reputation/public_reviews` (mock-mode only), `reputation/public_widgets`, `reputation/reports`, `reputation/feedback` (the gated-funnel submit endpoint).

**Services:** `app/services/reputation/{oauth_service, providers, score_calculator, snapshot_recorder, ai_draft_service, ai_insights_service, review_request_send_service, summary_builder, video_insights_service}.rb`

**Jobs:** `Reputation::{ReviewSyncJob, SyncAllReviewsJob, ReplyPublisherJob, SendReviewRequestJob, DispatchScheduledRequestsJob, CaptureSnapshotsJob, VideoInsightsJob, ListingImageJob}`

---

## 5. Frontend

**Vue:** `dashboard/routes/dashboard/reputation/` or equivalent — per memory, ported from a NewRelay-UI design reference (see `docs/solution-notes/reputation-design-port.md`, `reputation-reference/`). Mock-mode/demo data in the UI follows a "Demo badge + live reference URL" convention (see project memory `reputation-design-mock-marker.md`).

**Public pages:** server-rendered ERB views for the token-based public flows (`app/views/reputation/public_reviews/new.html.erb` confirmed; likely similar for widgets/reports/video-testimonial recording).

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/services/reputation/score_calculator_spec.rb` | scoring formula |
| `spec/services/reputation/providers_spec.rb`, `providers/google_spec.rb`, `providers/gmbapi_spec.rb` | provider adapter resolution + Google API adapter |
| `spec/services/reputation/ai_insights_service_spec.rb` | AI insights on testimonials |
| `spec/services/reputation/review_request_send_service_spec.rb` | request send logic |
| `spec/models/reputation/video_testimonial_spec.rb` | model validations |
| `spec/controllers/reputation/isolation_request_spec.rb` | (name suggests account-isolation/security check) |
| `spec/enterprise/controllers/api/v1/accounts/reputation/reviews_controller_spec.rb`, `listing_members_controller_spec.rb` | Enterprise-gated controller specs |
| `spec/factories/reputation/{templates, video_testimonials, review_requests}.rb` | test data |

**Coverage gaps observed:** only ~13 spec files across a module with 14 controllers, 14 models, 8 services, and 8 jobs. Notably **no spec found** for: `Reputation::Integration`/`Listing`/`Review` models directly, `Reputation::FeedbackController` (the gated-funnel logic — arguably the most business-critical piece), `AiDraftService`, `ReplyPublisherJob`, `SnapshotRecorder`/`CaptureSnapshotsJob`, `SummaryBuilder`, or any widget/report public-controller spec. This is thin relative to the module's size and the fact it handles OAuth tokens and money-adjacent trust behavior (public review gating).

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, Sidekiq (8 jobs — sync, reply, snapshots, video insights, scheduled dispatch), Google Business Profile API (real mode), ActiveStorage (listing photos)
- Mock mode: `REPUTATION_GOOGLE_PROVIDER=mock` env var — no external dependency, fully offline
- AI: LLM-backed `AiDraftService`, `AiInsightsService`, `VideoInsightsService` (likely Captain/shared LLM infra — see Captain AI FRD, Phase 5)

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Feedback link used after request already completed / token invalid | Blocked — `review_request&.live_for_public_submit?` guard returns 404 |
| Feedback submission missing required params | Rescued (`ActionController::ParameterMissing`), returns `422` with error JSON instead of a 500 |
| Google API access not yet approved | Mock mode makes the entire feature usable/demoable without it |
| Duplicate review synced twice | Prevented by unique index `(account_id, external_id, provider)` |
| Video testimonial linked to a review request that already has one | Prevented by unique partial index on `review_request_id` |

---

## 9. Open gaps / notes

- **Test coverage is the biggest gap in this module** — the gated feedback funnel (`FeedbackController`, the actual trust-protecting mechanism) and OAuth/token handling (`Integration`, `OauthService`) have no direct specs found. Given this is a differentiator feature with real external API/token risk, this is worth prioritizing before wider rollout.
- The "high rating → redirect to real public review" half of the gated funnel wasn't fully traced in this pass (only the "low rating → private feedback" half was confirmed in code) — verify `FeedbackController` or its frontend counterpart actually performs that redirect.
- Facebook provider adapter exists as a case branch but wasn't confirmed to be feature-complete — treat as unverified/partial until checked.
- This consolidates 9 originally-planned sub-areas into one FRD per the Phase 1 "overview" pattern; split any sub-area (e.g. Video Testimonials) into its own deeper FRD if it becomes a priority.
