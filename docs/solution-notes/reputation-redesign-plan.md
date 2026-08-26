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

### Phase R2 — Fill missing reference surfaces (net-new features)
- **RequestsPage / Configuration:** build the 3 missing tabs — `qr_link` (QR CTA), `ai_outreach`,
  `spam_shield` (Spam Reviews Filters).
- **ListingsPage / Integrations:** add Automatic Review Sync, Smart Auto-Reply, Webhook Endpoint.
- **Exit:** every reference section has a home in our pages (real or explicitly demo-gated).

### Phase R3 — De-mock the demo-gated pages (honesty)
- **Overview**, **Reviews**, **Listings**, **Feedback**: wire KPIs / lists / connections to real
  backend; drop `mock*` and the `reputation_demo_surfaces` redirect where data is real.
- **Exit:** no page shows fabricated numbers with the demo flag OFF (blank/empty is honest).

### Phase R4 — Verify & polish
- Visual-diff each page against `localhost:5174`; fix spacing/hierarchy; add missing i18n keys
  (no bare strings); confirm light + dark. Mark `NiN` (`REPORT.DATA_PENDING`) for any value we
  genuinely don't have — never fabricate.

## Deferred / not in scope
- Collapsing our 8-page nav to the reference's 5 items (see Open decision above).
- Any reference feature with no backend (mark `NiN`, don't fake).
