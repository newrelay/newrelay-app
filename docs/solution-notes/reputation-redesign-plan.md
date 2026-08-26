# Reputation — NewRelay design audit & phase plan

**Created:** 2026-08-26 · **Owner:** Reputation squad · **Purpose:** track the port of every
Reputation page to the NewRelay reference design so a missed item is never re-litigated.

- **Reference (target design):** NewRelay-UI `src/views/reputation/*` + `src/views/reviews/*`
  (dev server `http://localhost:5174`).
- **Our app:** `app/javascript/dashboard/routes/dashboard/reputation/pages/*`
  (standalone UI `http://localhost:5173/reputation/*`, mock API).
- **Golden rule:** tokens are identical — copy NewRelay Tailwind classes verbatim; never hardcode
  hex, never `woot-*`/`slate-*`. See `components-next/relay/NEWRELAY_PORTING_MAP.md`.

## Page mapping (our page → reference view)

| Our page | Reference view | Ref lines |
|---|---|---|
| `OverviewPage` | `reputation/OverviewView.vue` | 612 |
| `ReviewsPage` | `reviews/ReviewsView.vue` | 728 |
| `RequestsPage` ("Review Requests") | `reputation/ReviewOutreachView.vue` ("Configuration") | 1916 |
| `ListingsPage` | `reputation/IntegrationsView.vue` ("Integrations") | 1000 |
| `VideoTestimonialsPage` | `reputation/VideoReviewsView.vue` ("Video Reviews") | 1043 |
| `SettingsPage` | `reputation/SettingsView.vue` ("Reputation Settings") | 334 |
| `WidgetsPage` | *(no page — `VideoTestimonialWidgetModal` / `ReviewWidgetModal`)* | — |
| `FeedbackPage` | *(no page — `FeedbackBreakdownModal`)* | — |

> **Decision (nav shape) — RESOLVED 2026-08-26:** **keep our 8 pages.** Port each to the matching
> reference view's design; do **not** collapse the nav to the reference's 5-item IA. Requests,
> Widgets, Listings, and Feedback stay as their own routes.

---

## Per-page status

Legend — **Design:** ✅ ported to Relay tokens · ⚠️ partial · ❌ legacy. **Data:** real / mock / demo-gated.

### 1. OverviewPage — Design ✅ · Data mock (demo-gated)
- Rendered and matches the reference: KPI row (Reputation Score / Average Rating / Total Reviews /
  Overall Feedback), Review Trend chart, Relay AI Insights panel.
- **Pending:** de-mock. `mock≈21`, redirects out when `reputation_demo_surfaces` is off. Wire KPIs,
  trend series, and AI insights to real backend (reuse `Reputation::AiInsightsService`).

### 2. ReviewsPage — Design ✅ · Data partial
- Ported list with sort / platform / filter dropdowns matching `ReviewsView`.
- **Pending:** verify the reviews list, reply action, and filters are wired to real reviews (only
  `api≈2` hits today); de-mock anything left. Confirm reply-draft path (`Reputation::AiDraftService`).

### 3. RequestsPage — Design ✅ (own layout) · Data real · **STRUCTURE GAP**
- Ours is a **dispatch/log** page: Total Sent / Delivered / Link Clicks / Completed KPIs +
  Outbound Logs table + Quick Filters + Manual Entry. Backend-wired (`api≈9`).
- Reference **"Configuration"** is a **4-tab** surface: `channels` · `qr_link` · `ai_outreach` ·
  `spam_shield` (1916 lines). We have **none of these tabs**.
- **Pending (largest feature gap):** decide — keep Requests as the log page **and** add a
  Configuration surface for the 3 missing tabs (QR call-to-action, AI outreach, Spam Reviews
  Filters), or fold both together. These are net-new features, not just a restyle.
- ✅ **RequestReviewsModal reflow (2026-08-26):** matched the reference's new wizard order —
  **Step 1 = Channel** (+ sending method/schedule), **Step 2 = Recipients**. Recipients are now
  eligibility-filtered to contacts that have the field the chosen channel needs (Email→email,
  SMS/WhatsApp→phone), with an "N hidden" hint. Removed CSV import + manual-entry; added a
  **Company filter** (from `additional_attributes.company_name`) alongside Quick Filters. All still
  real-contact-wired.

### 4. ListingsPage — Design ✅ · Data mock (demo-gated)
- Ported; naming differs (ours "Listings" vs ref "Integrations").
- Reference adds: **Automatic Review Sync**, **Relay AI Smart Auto-Reply**, **Sync Webhook
  Endpoint**, platform connect cards + a "Request Received" request-integration state.
- **Pending:** de-mock (`mock≈16`) + add the sync / auto-reply / webhook sections from the reference.

### 5. VideoTestimonialsPage — Design ✅ · Data real — **DONE**
- Fully ported and de-mocked across Phases 1–3 (library, moderation, share/embed, CSV, notes,
  timeline, AI transcript/insights, tag filter). Matches `VideoReviewsView`. No action.

### 6. SettingsPage — Design ❌ LEGACY · Data real · **BIGGEST DESIGN DEBT**
- 1247 lines but **28 hardcoded `woot-*` / `slate-*` classes** (`bg-woot-500`, `focus:ring-woot-500`,
  `border-slate-750`, `bg-slate-850`, …) — a direct DESIGN.md violation; breaks dark mode.
- Reference `SettingsView` (334 lines, clean Relay tokens): **Relay AI Auto-Responder** (+ natural
  response delay), **Smart Review Gating & Sentiment Routing** (public threshold, private
  resolution form URL), **Immediate Negative Review Alert**.
- **Pending:** full re-port to Relay tokens + restructure to the reference's sections. Keep the
  existing wired logic (`api≈13`); change markup/classes only.

### 7. WidgetsPage — Design ⚠️ partial · Data mock
- `woot≈7` legacy classes + `mock≈10`. Chatwoot-only page (reference ships widgets as modals:
  `VideoTestimonialWidgetModal`, `ReviewWidgetModal`).
- **Pending:** strip the 7 legacy classes → Relay tokens; align embed/widget cards to the reference
  widget-modal styling; de-mock.

### 8. FeedbackPage — Design ✅ · Data mock (demo-gated)
- Ported; Chatwoot-only page (reference has only `FeedbackBreakdownModal`). `mock≈17`, demo-gated.
- **Pending:** decide if Feedback stays a full page or becomes the breakdown modal off Overview;
  de-mock whichever survives.

---

## Phase plan (ship in slices; update this doc after each)

### Phase R1 — Design-debt cleanup (pure DESIGN.md violations, no new features) — **do first**
- **R1a — token cleanup ✅ DONE (2026-08-26):** replaced **all** hardcoded `woot-*`/`slate-*`
  (+ `indigo`→`primary`, `red/rose`→`destructive`) with Relay semantic tokens in `SettingsPage.vue`
  and `WidgetsPage.vue`. 157/157 pure class swaps, no structural change; dark mode now token-driven.
  Verified: `rg` count 0 remaining, eslint exit 0, backgrounds preserved.
- **R1a also fixed `bg-white`** (16 in Settings, 6+2 in Widgets) → `bg-card`/`bg-muted`, except the
  QR print poster (`#qr-print-card`) which stays `bg-white` intentionally (printable artifact).

> **⚠️ MAPPING CORRECTION (2026-08-26):** the original audit mis-mapped `SettingsPage` → reference
> `SettingsView`. **They are not the same surface.** Our `SettingsPage.vue` is an **8-tab config
> hub** (Integrations, Relay AI Reviews, Review Link, SMS/Email/WhatsApp Requests, Reviews QR, Spam
> Reviews) with **12 real backend endpoints**, live Google/Facebook **OAuth**, template CRUD, and
> `html2canvas` QR generation. It is our implementation of the reference's **Configuration
> (`ReviewOutreachView`) + Integrations (`IntegrationsView`) COMBINED** — *not* the reference's
> small 4-card `SettingsView` (auto-responder / gating / alerts / badge). Rewriting our hub into
> `SettingsView` would **delete real OAuth/templates/QR/spam features** — do NOT do that.

- **R1b — corrected scope (PENDING, needs a direction decision):** the right port is to restyle each
  of our 8 config-hub tabs to the matching reference **Configuration tab** + **Integrations card**
  design (preserving all wiring) — this is effectively the R2 Configuration/Integrations work, done
  on our combined page. Separately, the reference's `SettingsView` (auto-responder/gating/alerts/
  badge) has **no direct equivalent** in our app today; decide whether to build it as a new small
  page or fold those controls into the hub's "Relay AI Reviews" tab.
- **R1c — new Automation page ✅ DONE (2026-08-26):** built `AutomationPage.vue`, a faithful port of
  the reference `SettingsView` (4 cards: Relay AI Auto-Responder, Smart Review Gating, Notification
  & Alert Preferences, Website Trust Badge Embed) using Relay components (`RelaySwitch`,
  `RelayInput`, `RelayButton`) + native selects. Route `reputation_automation` (`/reputation/
  automation`, admin-only); sidebar nav label "Automation" (`SIDEBAR.REPUTATION_AUTOMATION` in
  en.json). MVP state = localStorage `rep_automation_settings` (no backend contract for these policy
  fields yet — ponytail: wire to a settings endpoint when one exists). Verified: eslint exit 0, JSON
  valid, route/nav/i18n wired, Relay APIs confirmed. **Live render pending a Vite restart** — the
  standalone `:5173` blanks on HMR + P404s on hard deep-links (known dev-server quirks, not the code).
- Now we ship **9 pages** (the 8 + Automation) — the config hub stays "Settings"; Automation is the
  reference's settings surface.
- **Exit (R1):** zero `woot-*`/`slate-*` (✅) + new Automation page (✅). Tab-by-tab restyle of the
  config hub → corrected R2.

### Dedicated Configuration + Integrations pages — ✅ DONE (2026-08-26, per user request)
- **User asked for the reference's `Configuration` and `Integrations` as their own pages** (not folded
  into the Settings config hub). Built both as new pages, routed + sidebar-linked **behind
  `reputation_demo_surfaces`** (same showcase pattern as Listings/Feedback), each with a "Demo" badge.
  - `IntegrationsPage.vue` — platform catalog (12 platforms) with search/status/category/sort filters,
    grid4/grid2/list views, per-platform **Integration Settings** modal (Auto Sync / Smart Auto-Reply /
    Webhook), connect/notify toggles, request-integration flow, and empty state.
  - `ConfigurationPage.vue` — 4 tabs: **Channels & Templates** (per-channel editor + `outreachTemplates`
    picker + insert-tags), **Review Link & QR Hub** (copy link + QR frame selector + download),
    **Relay AI Automations** (auto-reply toggle + rating threshold + instructions), **Spam & Protection
    Shield** (auto-flag rating + blocklist keywords).
- **Why demo-gated:** the *real* platform OAuth connect + live request templates + QR generator live in
  the Settings config hub (real endpoints). These two pages are faithful design ports / showcases; their
  toggles and saves are local demo state (no backend contract). Real users (flag off) don't see them.

### Phase R2 — Fill missing reference surfaces — ✅ DONE (2026-08-26)
- **Configuration tabs (`qr_link`, `ai_outreach`, `spam_shield`)** — ✅ **already built**: our
  SettingsPage config hub has `reviews_qr`, `reviews_ai`, and `spam_reviews` tabs (with real
  endpoints). No new work needed — this half was redundant, as flagged during reconciliation.
- **ListingsPage / Integrations** — ✅ added the reference's per-listing **Integration Settings
  modal** (opened from "Manage Listing"): Automatic Review Sync + Relay AI Smart Auto-Reply toggles
  (`RelaySwitch`) and a read-only Sync Webhook Endpoint (`{origin}/api/v1/reputation/sync/{id}`).
  Demo state on the demo-gated Listings page — no backend contract for these policy fields yet.
- **Exit:** ✅ every reference Integrations/Configuration section now has a home (real in the config
  hub, or demo-gated on Listings).

### Phase R3 — De-mock (RE-SCOPED after deep inspection, 2026-08-26)
**Finding:** the pages are far more real than the first audit implied. The "mock" is **intentional,
flag-gated, badged** demo content, not lies to real users:
- **Overview** — real: `avgRating`/`totalReviews`/`platforms`/`trendBars`/`recentReviews` all compute
  from real `/reviews` + `/summary`. Only the AI Sentiment/Insights cards fall back to sample data,
  and they were `v-if="showDemoSurfaces"` (hidden from real users) + badged "Demo".
  - ✅ **Done:** AI cards now show real insights to **real** users when `/ai_insights` returns data
    (`v-if="!aiIsMock || showDemoSurfaces"`); sample fallback stays demo-only + badged. Trend chart
    width follows the same condition.
  - ✅ **Done (2026-08-26):** restored the reference's 4th KPI — **Overall Feedback** (positive share
    of reviews, `rating>=4`) as a real always-on card, replacing the demo AI Sentiment KPI. Clicking
    it opens **`FeedbackBreakdownModal.vue`** (ported from the reference): sentiment split
    (positive/neutral/negative), sentiment bar, and per-platform breakdown all computed from real
    `allReviews`; the "Top Feedback Themes" section is demo-only + badged (needs a topic-analysis
    backend). Skipped: month-over-month feedback delta (no endpoint).
- **Reviews** — already real; no work.
- **Requests** — real: KPI `stats` computed from `/review_requests`; empty ⇒ zeros. No work.
- **Widgets** — ✅ **Done (2026-08-26):** the widget live preview now renders the account's **real
  reviews** (filtered by `min_rating`), falling back to sample data only when there are no reviews
  yet, badged **"Your Reviews"** vs **"Sample Data"**. Fetches `/reputation/reviews` on mount.
- **Listings**, **Feedback** — demo-gated routes (real users are redirected out); sample data only
  shows in demo mode, badged. The R2 Integration Settings toggles on Listings are likewise
  demo-state behind the flag.
- **Exit:** ✅ **real users never see fabricated numbers.** Audited every non-gated page (Overview,
  Reviews, Requests, Widgets, Video Testimonials) — all compute from real endpoints with honest
  empty states; sample content is confined to demo-gated routes and clearly badged.
- **Remaining product decision (optional, not blocking):** on the demo-gated surfaces, keep the
  illustrative sample data (the point of a showcase flag) or swap to empty states. Yours to make —
  the current architecture is already honest either way.

### Phase R4 — Verify & polish
- Visual-diff each page against `localhost:5174`; fix spacing/hierarchy; add missing i18n keys
  (no bare strings); confirm light + dark. Mark `NiN` (`REPORT.DATA_PENDING`) for any value we
  genuinely don't have — never fabricate.
- ✅ **Token debt swept (2026-08-26):** removed all remaining `slate-*` / `dark:bg-black` from the
  reputation module (phone-preview mockups in `RequestReviewsModal` + `RequestsPage`, stray icon on
  `ReviewsPage`) → semantic tokens; validation error text `text-red-500` → `text-destructive`
  (`RequestReviewsModal`, `RequestsPage`, `SettingsPage`). Remaining `bg-white` are intentional and
  left as-is (brand-logo chips, video controls, printable QR/report surfaces).
- ✅ **Request Reviews modal made "proper" vs reference (2026-08-26)** — verified against the live
  reference on `:5173`: channel-first wizard, Schedule Later date/time/timezone, eligibility banner,
  company as top-right card badge, searchable company filter, schedule summary in review step,
  channel-step helper copy.
- ✅ **Step 3 message redesign ported (2026-08-26):** the reference's per-channel message system —
  channel switcher, channel-aware prebuilt-template picker (`components/data/outreachTemplates.js`),
  separate Email (subject/body) / SMS (char count) / WhatsApp (header/body) editors,
  Improve-with-Relay-AI, insert-variable chips, tone + single review **destination**, and a live
  device preview that renders as an Email client / WhatsApp chat / SMS thread for the selected
  channel. Slate/white device classes converted to tokens. Real submit sends the primary channel's
  composed message + `[destination]`. Deferred: sending a distinct message per channel in one batch
  (backend takes one `message`); AI enhance is the reference's canned demo (no LLM call).

## Session log — 2026-08-26 (autonomous polish)
Commits on `feature/ui-changes`: real Overall Feedback KPI + de-mock (`5f6b1d5a`); feedback breakdown
modal (`8dc6e934`); reference snapshot refresh (`051060b5`); channel-first wizard reflow (`aea75fd2`);
always-show company filter (`c5a87afc`); Schedule time input (`de610d17`); RelayTimePicker
(`35bd254d`); searchable company dropdown (`1b2ba7be`); modal polish + tokens (`20de9412`); page
token cleanup (`dc3d41c8`); destructive error token (`d76cd362`); recipients UX match (`5b6c0af8`).
Not pushed — local commits only.

## Deferred / not in scope
- Collapsing our 8-page nav to the reference's 5 items (see Open decision above).
- Any reference feature with no backend (mark `NiN`, don't fake).
