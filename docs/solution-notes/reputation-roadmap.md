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

| Feature | Backend |
|---|---|
| Listings page (grid, stats, filters, Add/Export) — UI already built | `Reputation::Listing` model + `listings_controller` (index/create/sync) |
| Listing Detail page (`ListingDetailView` port) | same model + per-listing reviews/activity |
| Per-platform sync (Google Business Profile, etc.) | **build on the v1.0 provider, do not greenfield a 2nd sync stack** |

**Ship criteria:** a real location with real optimization score + platform health, syncing.
**Effort:** ~1–2 weeks / CC ~3–5 days. **Depends on v1.0 provider.**

---

## v2.1 — "Feedback / private interceptor"
**Goal:** intercept 1–3★ feedback privately before it goes public (the funnel promised in Overview copy).

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
| AI Sentiment (92% card) | per-review sentiment classify (reuse `ai_draft` LLM path) → aggregate; **budget batching + caching** |
| Relay AI Insights (bullets) | daily LLM summary over recent reviews, cached per account |
| Share Report wizard (UI built) | report-builder service: render selected sections → PDF/PNG → signed share link + email |

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

## Cross-cutting (every version)
- `enterprise/` overlay check for each new model/controller (CLAUDE.md).
- Semantic tokens only; lucide icons (verify names); i18n sweep is a **separate track** (still deferred).
- Freeze a page's design before wiring real data into it (avoid re-wiring a moving target).

## The one-line call
Ship **v1.0** and stop. It is the whole product for most customers. v1.1–v3.0 are real but optional;
gate them behind the flag and pull them forward only when a customer asks or the provider spine is rock-solid.
