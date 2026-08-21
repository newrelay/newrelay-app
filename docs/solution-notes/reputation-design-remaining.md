# Reputation — Remaining Design Port Plan

Maps every **Reputation-related** reference design (`desgin-system-nr/src/views/…`) to our app and lists what is
still un-ported. Scope = Reputation only (the reference also ships analytics/campaigns/deals/etc. — **out of scope**
unless we decide to redesign those app areas separately).

## Status map (reference → our app)

| Reference design | Our target | Status |
|---|---|---|
| `reputation/OverviewView.vue` | `pages/OverviewPage.vue` | ✅ Ported (mock/Demo; see demo-inventory) |
| `reputation/VideoReviewsView.vue` | `pages/VideoTestimonialsPage.vue` | ✅ Ported |
| `reviews/ReviewsView.vue` | `pages/ReviewsPage.vue` | 🟡 Ported — **verify** vs reference (drawer, filters) |
| `listings/ListingsView.vue` | `pages/ListingsPage.vue` | ✅ Ported (dropdowns + Add/Export modals) |
| `listings/ListingDetailView.vue` | — none — | ❌ **Not ported** (new page + route) |
| `feedback/FeedbackView.vue` | — none — | ❌ **Not ported** (new page + route + sidebar fix) |
| `components/RequestReviewsModal.vue` | `components/RequestReviewsModal.vue` | ✅ Present |
| `components/RequestVideoTestimonialModal.vue` | `components/RequestVideoTestimonialModal.vue` | ✅ Present |
| `components/ExportVideoTestimonialsModal.vue` | `components/ExportVideoTestimonialsModal.vue` | ✅ Present |
| `components/ShareReportModal.vue` | `components/ShareReportModal.vue` | ✅ Ported + wired to Overview |
| `listings/components/AddListingModal.vue` | inline in `ListingsPage.vue` | ✅ Built (inline) |
| `listings/components/ExportListingsModal.vue` | inline in `ListingsPage.vue` | ✅ Built (inline) |

**Not in the reference set (no design to port — leave as-is):** `WidgetsPage`, `RequestsPage`, `SettingsPage`.
The live reference's Reputation submenu is Overview / Reviews / Video / Listings / Feedback only.

## Remaining work

### R1 — Listing Detail page  (`ListingDetailView.vue`, ~48KB — biggest)
Opened when a listing card is clicked (`Manage Listing`). Reference sections: hero (image, name, badges,
optimization score), business info (phone/website/category/hours), connected-platform manager (connect/disconnect per
platform), reviews for that listing, activity/sync log.
- **Add:** `pages/ListingDetailPage.vue` + route `reputation_listing_detail` (`listings/:listingId`).
- **Wire:** `ListingsPage` "Manage Listing" + card click → `router.push({ name: 'reputation_listing_detail', params: { listingId } })`.
- **Data:** Demo/mock until the Listings backend exists (demo-inventory #12) → carry `Demo` badges.
- **Effort:** ~1 day UI (mock). Real data waits on the Listings backend.

### R2 — Feedback page  (`feedback/FeedbackView.vue`)
Private-interceptor / feedback inbox (the "intercept 1–3★ privately" funnel from the Overview onboarding copy).
- **Add:** `pages/FeedbackPage.vue` + route `reputation_feedback` (`feedback`).
- **Fix:** sidebar "Reputation Feedback" currently → `reputation_requests` (wrong); repoint to `reputation_feedback`
  (`components-next/sidebar/Sidebar.vue`, same spot as the Listings fix we just did).
- **Data:** partial backend exists — public `reputation/feedback#create` collects submissions; needs a dashboard
  `feedback_controller#index` to list them. UI first with Demo, then wire.
- **Effort:** ~0.5–1 day UI; +0.5 day backend index endpoint.

### R3 — Reviews page verify/polish  (`reviews/ReviewsView.vue`)
`ReviewsPage.vue` exists (ported by the other session, currently mock `reviews=ref([...])`). Confirm it matches the
reference: list + right-side detail drawer, filters, bulk-select, reply/ignore actions.
- **Action:** diff against the live reference `/reviews`; fix gaps; keep Demo marker on mock data.
- **Effort:** ~0.5 day (verify + polish), or more if the drawer/filters are missing.

## Suggested order & phasing
1. **R2 Feedback** first — smallest, completes the reputation submenu (Overview/Reviews/Video/Listings/**Feedback**),
   and fixes the mis-routed sidebar item (quick win, mirrors the Listings route fix).
2. **R3 Reviews verify** — cheap, ensures the already-ported page actually matches.
3. **R1 Listing Detail** — largest; do last, and only the mock UI until the Listings backend (demo-inventory Phase 4) lands.

## CEO Review Verdict — SCOPE REDUCTION (decided)
The full port builds a large mock surface while the core loop (sync + reply to real Google/FB reviews)
is still unreliable. Reduced to the real-data spine; the rest is deferred behind a flag, not shipped as real.

### MUST ship (real value, in order)
1. **Provider spine** — finish one review provider (Ayrshare or direct Google GBP) so reviews actually sync and
   replies actually post. This is the highest-leverage item and it is NOT in the original plans.
2. **Phase-1 reconnect** (demo-inventory items 1–5, 9) — once the spine works, re-wire Overview/Reviews/Requests/Widgets
   to their existing controllers. Overview cards, Reviews list, Platform Breakdown, Review Trend all become real for free.
3. **Freeze the design before wiring** — pages are under active multi-session edit; stop rewriting them to mock, then wire once.

### DEFER behind a `reputation_demo_surfaces` feature flag (stays Demo, hidden in prod)
- Listings, Listing Detail, Feedback pages
- Share Report wizard
- Reputation Score, AI Sentiment, AI Insights, month-over-month deltas

### CUT for now (no customer demand + inherits the provider risk)
- Listings per-platform sync backend, report renderer service, per-review sentiment LLM.
  Build only after the provider spine is solid and a customer asks.

### Guardrails the original plan missed
- **Feature flag Demo surfaces** — shipping amber "Demo" badges to a paying customer is a trust defect. Gate them.
- **Deltas render `—` until history accrues** — never fake "+12%" before the snapshots table has 30 days.
- **`enterprise/` overlay check** for any new model/controller (Listing, feedback, report).
- **LLM cost budget** (batching + caching) before Sentiment/Insights.

## Rules (same as the rest of the port)
- Match the **live** reference (`https://new-relay-ui.vercel.app` → load root, then navigate); classes/fonts/icon sizes carry over.
- lucide-vue-next is installed; use it (verify each icon name resolves before importing).
- No backend for a value → **mock + one `Demo` badge**, mock kept in one object per file (see demo-inventory for the wiring-back plan).
- Semantic tokens only (`bg-card`, `border-border`, `bg-primary`, …); no `woot-*`/`slate-*` hardcodes.
- New pages need: page file + route in `reputation.routes.js` + (if a nav item) sidebar entry in `Sidebar.vue`.
- Coordinate on shared files under active multi-session edit (`OverviewPage.vue`, `ReputationLayout.vue`, the design-port tracker).
