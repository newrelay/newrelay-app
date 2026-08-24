# Reputation Manager — Version-wise Roadmap

Groups the reputation work into shippable versions (from the scope-reduction verdict in
`reputation-design-remaining.md`). Each version is independently shippable and adds real value.
Rule across all versions: **no feature ships as "real" until its backend exists** — until then it stays
behind the `reputation_demo_surfaces` flag with a `Demo` badge. Detail on each item: `reputation-demo-inventory.md`.

Effort shown as **human / CC** (CC = Claude Code assisted).

---

## v1.0 — "Real reviews that work"  (MVP — the only version customers strictly need)
**Goal:** a customer connects Google/Facebook, sees their real reviews, and replies from the UI.

| Feature | Backend | Status |
|---|---|---|
| Provider spine — real sync + reply (Ayrshare **or** direct Google GBP) | pick 1 provider, finish adapter | **the critical path** |
| Overview: Avg Rating, Total Reviews, Pending, Response Rate, Review Trend, Platform Breakdown, Recent Reviews + reply | existing `/reviews`, `/integrations` | reconnect (demo-inv 1,9) |
| Reviews page: list + reply / ignore / AI-draft | existing `/reviews/*` | reconnect (demo-inv 2) |
| Requests: send review invites + funnel | existing `/review_requests` | drop mock fallbacks (demo-inv 4) |
| Widgets, Settings | existing `/widgets`, settings | mostly done (demo-inv 5) |

**Deferred/hidden in v1.0 (flag OFF):** Reputation Score, AI Sentiment, AI Insights, month-over-month deltas,
Listings, Feedback, Share Report.
**Ship criteria:** connect Google → a real review appears → reply posts to Google. No fake numbers on screen.
**Effort:** provider spine ~3–5 days / CC ~1–2 days; reconnect ~1 day / CC ~2–4 hrs.

---

## v1.1 — "Overview goes fully real"  (trust + polish)
**Goal:** remove the last Demo badges from the page customers stare at most.

| Feature | Backend |
|---|---|
| `reputation_demo_surfaces` feature flag (gate all Demo surfaces) | flag plumbing |
| Month-over-month deltas (+X% cards, platform trend column) | new `reputation_snapshots` table + daily cron (reuse `SyncAllReviewsJob`); renders `—` until 30 days of history |
| Reputation Score | server-side formula (weighted avg rating + response rate + velocity) on the summary endpoint |

**Ship criteria:** Overview has zero Demo badges; deltas are honest (blank until history).
**Effort:** ~2–3 days / CC ~1 day.

---

## v2.0 — "Listings"  (multi-location)
**Goal:** manage business listings + connected platforms across locations.

**Status (2026-08-21): lean backend SHIPPED.** `Reputation::Listing` model + `reputation_listings`
table (name/address/category/country/phone/website/email/primary/platforms jsonb/synced_at) +
`listings_controller` (index/create/destroy) + route + `Account#reputation_listings`. ListingsPage
wired to `GET/POST /reputation/listings` with mock fallback (Demo badge only when mock); Add-Listing
modal persists. **Deferred (still Demo/computed on FE):** optimization score, rating/review rollups,
per-platform sync (needs v1.0 provider), Listing Detail page.

| Feature | Backend | Status |
|---|---|---|
| Listings page (grid, stats, filters, Add/Export) — UI already built | `Reputation::Listing` model + `listings_controller` (index/create) | ✅ done |
| Listing Detail page (`ListingDetailView` port) | same model + per-listing reviews/activity | ⬜ deferred |
| Per-platform sync (Google Business Profile, etc.) | **build on the v1.0 provider, do not greenfield a 2nd sync stack** | ⬜ deferred |

**Ship criteria:** a real location with real optimization score + platform health, syncing.
**Effort:** ~1–2 weeks / CC ~3–5 days. **Depends on v1.0 provider.**

---

## v2.1 — "Feedback / private interceptor"  ✅ SHIPPED
**Goal:** intercept 1–3★ feedback privately before it goes public (the funnel promised in Overview copy).

**Status (2026-08-21): fully done.** `Reputation::FeedbackSubmission` model, public `POST /reputation/feedback`
(creates submission + marks request completed), dashboard `GET /reputation/feedback` (index), FeedbackPage
wired with Demo fallback, sidebar `reputation_feedback` route correct. Nothing outstanding.

| Feature | Backend |
|---|---|
| Feedback page (`FeedbackView` port) + route `reputation_feedback` | dashboard `feedback_controller#index` over existing public `feedback#create` submissions |
| Fix sidebar "Feedback" (currently → `reputation_requests`) | 1-line repoint (like the Listings fix) |

**Ship criteria:** negative feedback lands in a private inbox, not on Google.
**Effort:** ~1 day / CC ~4 hrs UI + ~0.5 day backend.

---

## v3.0 — "AI + reporting"  (differentiation)
**Goal:** the AI story and shareable reports.

| Feature | Backend |
|---|---|
| AI Sentiment (92% card) | per-review sentiment classify (reuse `ai_draft` LLM path) → aggregate; **budget batching + caching** — **SHIPPED 2026-08-21** |
| Relay AI Insights (bullets) | daily LLM summary over recent reviews, cached per account — **SHIPPED 2026-08-21** |

**v3.0 AI Sentiment + Insights status (2026-08-21): SHIPPED.** `Reputation::AiInsightsService` (inherits enterprise
`Llm::BaseAiService`, same as `AiDraftService`) makes ONE LLM call over up to 50 recent reviews → `{sentiment 0-100,
insights:[{title,text}]}`. `AiInsightsController#show` (`GET /reputation/ai_insights`) caches per account per day
(`Rails.cache`, `skip_nil: true` so a misconfig doesn't stick 24h). OverviewPage fetches it in `loadData`; real
sentiment % + insight bullets replace the mock and drop the Demo badge when present, mock fallback otherwise (no LLM /
no reviews). **All roadmap items v1.0–v3.0 now have a lean backend.**
| Share Report wizard (UI built) | report-builder service: render selected sections → PDF/PNG → signed share link + email — **lean version SHIPPED 2026-08-21** |

**v3.0 Share Report status (2026-08-21): lean backend SHIPPED.** `Reputation::Report` model + `reputation_reports`
table (token + config jsonb) + dashboard `reports_controller#create` (persists config, returns `share_url`) +
**public** `Reputation::ReportsController#show` rendering a printable HTML report at `GET /reputation/reports/:token`
from live `SummaryBuilder` data (score/avg rating/reviews/response rate/platform breakdown). ShareReportModal wired:
Generate → POST, Open Report → opens the public link, Copy Link → real URL. **Deferred (Demo choices in the wizard):**
server-side PDF/PNG/CSV export (use browser print-to-PDF for now), email delivery, link expiry, download counts.

**Ship criteria:** sentiment/insights reflect real reviews; a report generates + shares a working link.
**Effort:** ~1–2 weeks / CC ~4–6 days. **Depends on v1.0 (real reviews to analyze).**

---

## Dependency chain
```
v1.0 provider spine ─┬─> v1.0 reconnect ──> v1.1 (deltas/score/flag)
                     ├─> v2.0 Listings (needs provider sync)
                     └─> v3.0 AI (needs real reviews)
v2.1 Feedback ── mostly independent (public feedback backend exists)
```

## Request Reviews — Quick Filters (decided 2026-08-21)
The recipient picker's Quick Filters (Completed Jobs, Closed Deals, Positive Feedback,
Appointment Completed, Invoice Paid) are CRM/job concepts with **no native Chatwoot field**.
Decision: back them with **contact labels** — reuse the contacts index `?labels=<slug>` support
(`tagged_with`, contacts_controller.rb), zero backend. "Recent Customers" = default `sort=-last_activity_at`.
Slugs: `completed-job`, `closed-deal`, `positive-feedback`, `appointment-completed`, `invoice-paid`.
Wired in `RequestsPage.vue` + `RequestReviewsModal.vue` via `FILTER_PARAMS`; search overrides the filter.
**Default labels auto-seeded:** on first open the picker `ensureDefaultLabels()` GETs `/labels` and POSTs any of the
five slugs that are missing (idempotent, once/session) — so the labels exist in the account (and show up in the contact
label picker) without the user creating them. Re-seeds if a user deletes one; that's the "default" semantic.
**Ceiling:** a filter is empty until contacts actually carry that label (via automations/CRM sync/manual tagging) — honest, not a bug.
**Upgrade path:** for richer rules (date ranges, custom attributes like `invoice_status=paid`) switch to `POST /contacts/filter`
(`Contacts::FilterService`). `positive-feedback` can later point at real reviews/CSAT instead of a label.

## Request Reviews — Delivery Channels (decided 2026-08-21)
`RequestsPage.vue` step 2. **Dynamic open rate:** per-channel rate is computed from real `review_requests`
(`opened = status past "sent"` / total for that `channel` enum) instead of the old hardcoded 92/96/98%;
shows `—` "No sends yet" until data exists. Backend enum only has `sms|email`, so WhatsApp always reads `—`
(no adapter yet). **Channel/recipient validation:** each channel needs a field on the recipient (Email→`email`,
SMS/WhatsApp→`phone`); `mapContact`/manual/CSV rows now carry `email`+`phone` (manual/CSV split on `@`).
`channelError` computed blocks Next (step 2) and Send when a selected, currently-visible contact lacks the
required field. Default channel stays `['Email']`.
**Ceiling:** validation only sees recipients still in the loaded list (switching Quick Filter can hide
some); WhatsApp open rate needs a real WhatsApp send path (backend enum is `sms|email` only, so WhatsApp reads `—`).
**Applied to BOTH surfaces:** `RequestsPage.vue` (Requests route, real send) and `RequestReviewsModal.vue`
(Overview "Request Reviews", mock send) — the modal now also GETs `/reputation/review_requests` for its rates.
Rates show `—`/"No sends yet" until the account actually has send history.

## Request Reviews — Sending Method: immediate job + scheduled cron (decided 2026-08-21)
Step 2 "Sending Method" is now real end-to-end.
- **Send Immediately** → `review_requests#create` calls `ReviewRequestSendService#send!` which creates the request
  (`status: :sent`) and enqueues `Reputation::SendReviewRequestJob` (async delivery via existing mailer/Twilio/mock).
- **Schedule Later** → the picker shows a native `<input type="datetime-local">` (min = now, future-only validation
  in `scheduleError`); the payload carries `scheduled_at`. The service persists it `status: :scheduled` and does NOT
  deliver. Cron `Reputation::DispatchScheduledRequestsJob` (`*/5 * * * *`, schedule.yml) selects due
  `scheduled` rows, flips them to `:sent` (so the next tick won't re-pick), and enqueues the send job.
- **Migration:** `scheduled_at :datetime` + index `[status, scheduled_at]`; new enum value `scheduled` on status.
- **Send payload contract (both FE surfaces):** `{ channel, contact_ids:[numeric ids], recipients:[raw emails/phones], scheduled_at }`.
  Controller resolves real contacts by id + find-or-creates contacts from raw emails/phones; auto-provisions a default
  per-channel template (`default_template`) so no template needs selecting. WhatsApp coerced to `sms` (no WA backend yet).
- **Verified** via `rails runner`: immediate→sent+job, future→scheduled, due+cron→sent.
**Ceiling / not done:** WhatsApp has no real adapter; no per-request retry/failure UI. **Manual/CSV rows** send as raw
`recipients` (find-or-create contact) since their FE ids aren't real contact ids.

## Request Reviews — Tone & Review Destination (decided 2026-08-21)
Both step-3 selectors in `RequestsPage.vue` are now real (the modal has no selectors — it sends its composer message + `['Google']` default).
- **Tone** → `applyTone(tone)` swaps the composer message to a tone preset (`TONE_PRESETS`: Friendly/Professional/Luxury/Casual).
  The composed `message` is now **persisted on the request** (`message :text`) and **actually delivered**: `render_body`
  prefers `request.message` over the template body and resolves both placeholder styles
  (`{{FirstName}}`/`{{contact.name}}`, `{{ReviewLink}}`/`{{review_link}}`, `{{BusinessName}}`). This closes the old
  "freeform message not used" gap — works for immediate and scheduled sends.
- **Review Destination** → selected platforms persist on the request (`destinations :jsonb`). The public
  `/r/:token` redirect (`PublicWidgetsController#redirect`) now sends the customer to the **primary destination's real
  write-review URL** when that platform is a connected `Reputation::Integration` — currently only **Google** resolves
  (`search.google.com/local/writereview?placeid=<location_id>`); everything else falls back to the testimonial funnel.
- **Migration:** `message :text`, `destinations :jsonb default: []`. **Payload:** `create` now also takes `message`, `destinations[]`.
- **Verified** via `rails runner`: message stored + rendered with placeholders; destination → nil without integration, real Google URL with one.
**Ceiling:** only Google has a real deep link (others → funnel); tone presets are static copy (not AI-rewritten — the
"Improve Message" button is still unwired).

## Cross-cutting (every version)
- `enterprise/` overlay check for each new model/controller (CLAUDE.md).
- Semantic tokens only; lucide icons (verify names); i18n sweep is a **separate track** (still deferred).
- Freeze a page's design before wiring real data into it (avoid re-wiring a moving target).

## The one-line call
Ship **v1.0** and stop. It is the whole product for most customers. v1.1–v3.0 are real but optional;
gate them behind the flag and pull them forward only when a customer asks or the provider spine is rock-solid.
