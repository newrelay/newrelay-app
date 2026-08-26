# Reputation design reference (NewRelay) — one-stop folder

Everything needed to port each Reputation page faithfully, in one place. **Read the matching
`source/views/...vue` for exact Tailwind classes** — tokens are identical to our Relay theme, so
classes copy over verbatim (`bg-card`, `text-muted-foreground`, `bg-primary`, `rounded-xl`, …).
Never hardcode hex, never `woot-*`/`slate-*`.

## Folder contents
- `source/views/reputation/*.vue` — the 6 reference views (exact design spec)
- `source/views/reviews/ReviewsView.vue` + components — reviews list
- `source/views/reputation/components/*` — modals (request, export, share, widget, feedback breakdown)
- `source/style.css` — NewRelay tokens (already 1:1 in our `_relay-theme.scss`)
- `source/navigation.ts` — reference menu structure/labels
- `index.md` — this file (per-page spec + how to view live)

## View the live reference
Reference dev server: `http://localhost:5174` (hydrates after ~1–2s on deep links). Routes:
`/reputation/overview` · `/reviews` · `/reputation/outreach` (Configuration) ·
`/reputation/integrations` · `/video-reviews` · `/reputation/settings`.
Our app (mock): `http://localhost:5173/reputation/*`.

> Raw PNG screenshots aren't written here — the browser screenshot tool can't save to disk. The
> `.vue` source (exact classes) + live render on `:5174` cover fidelity. If you want PNGs on disk,
> say so and I'll set up the headless `browse` daemon to dump them into `screenshots/`.

---

## Per-page spec (reference → our page → phase)

### Overview → `OverviewView.vue` → our `OverviewPage.vue`  [design ✅, matches]
- Header: `h1` "Overview" + subtitle; actions "Share Report" (outline) + "Request Reviews" (primary).
- KPI row (4): Reputation Score `85/100`, Average Rating `4.7` + stars, Total Reviews, Overall
  Feedback `94% Positive` — each card icon top-right, trend line (`+3 pts from last month`).
- Review Trend bar chart card (timeframe dropdown) + **Relay AI Insights** side panel (bulleted
  insights, colored dots).
- Our port already matches. **Phase R3:** de-mock the numbers/insights.

### Reviews → `reviews/ReviewsView.vue` → our `ReviewsPage.vue`  [design ✅]
- Header `h1` "Reviews"; sort dropdown (Newest/Oldest/Highest/Lowest), Platform filter, bulk
  actions (Needs Reply, Assigned To…). Review rows with reply.
- **Phase R3:** verify real reviews list + reply/filter wiring.

### Configuration → `ReviewOutreachView.vue` → our `RequestsPage.vue`  [STRUCTURE GAP — R2]
- Header `h1` "Configuration" + subtitle "Collect verified 5-star reviews across Google, Yelp,
  Facebook via automated multi-channel sequences."; action "Preview Empty State".
- **4 tabs:** `Channels & Templates` · `Review Link & QR Hub` · `Relay AI Automations` ·
  `Spam & Protection Shield` (`activeTab` = `channels|qr_link|ai_outreach|spam_shield`).
- Channels tab: "SMS Request Template" card — channel toggles (SMS/Email/WhatsApp/Video
  Testimonial), template select + "New Template", message textarea w/ char count + `1 SMS`,
  merge-tag chips (`{{FirstName}}`,`{{BusinessName}}`,`{{ReviewLink}}`,`{{EmployeeName}}`), and a
  **live phone preview** on the right.
- QR tab: QR call-to-action text + QR hub. AI tab: outreach automations. Spam tab: "Spam Reviews
  Filters".
- Our Requests is a **dispatch/log** page (KPIs + Outbound Logs + Manual Entry). Decision (locked):
  keep Requests, **add** this Configuration surface for the 3 missing tabs. These are net-new.

### Integrations → `IntegrationsView.vue` → our `ListingsPage.vue`  [design ✅ / feature gap — R2/R3]
- Header `h1` "Integrations" + subtitle; actions "Preview Empty State" + "Sync All Accounts".
- Toolbar: search platforms + filters (Platform Status / Category-Niche / Recommended-Popular) +
  grid/list toggle.
- **Platform connect cards grid** (2–4 col): Google, Yelp, Trustpilot, Facebook, TripAdvisor,
  Apple, Amazon, G2 — each: logo, name, category badge, description, status pill
  (Popular/Easy setup/Recommended), "Configure →".
- Lower sections: **Automatic Review Sync**, **Relay AI Smart Auto-Reply**, **Sync Webhook
  Endpoint**, + a "Request Received" request-integration state.
- **Phase R2:** add sync/auto-reply/webhook sections. **R3:** de-mock the connect cards.

### Video Testimonials → `VideoReviewsView.vue` → our `VideoTestimonialsPage.vue`  [DONE]
- `h1` "Video Reviews"; stat cards (Total Videos 321, 78%, Avg Rating 4.9, 42), tabs incl.
  Overview. Fully ported + real across our Phases 1–3. No action.

### Settings → `SettingsView.vue` → our `SettingsPage.vue`  [design ❌ LEGACY — R1, do first]
- Header `h1` "Reputation Settings" + subtitle "Manage review gating, Relay AI auto-responder
  policies, alerts, and website embed widgets."; actions "Preview Empty State" + "Save Changes".
- **Card: Relay AI Auto-Responder** (icon in `bg-primary/10` box, "Relay AI Powered" badge top
  right): 2-col switch rows "Auto-Draft Smart Replies" / "Auto-Publish for 5-Star Reviews";
  2-col selects "AI Response Tone" (Friendly & Enthusiastic) / "Natural Response Delay" (15 min).
- **Card: Smart Review Gating & Sentiment Routing**: "Enable Smart Sentiment Filtering" switch,
  "Public Review Threshold" + "Private Resolution Form URL" fields.
- **Card: Immediate Negative Review Alert** + embed-widget settings.
- Our SettingsPage = 1247 lines with **28 `woot-*`/`slate-*`** hardcoded classes → full re-port to
  Relay tokens, restructured to these cards, keeping wired logic (`api≈13`).

### Widgets → *(no reference page — `components/VideoTestimonialWidgetModal.vue`, `reviews/components/ReviewWidgetModal.vue`)* → our `WidgetsPage.vue`  [partial — R1]
- Reference ships widgets as **modals**, not a page. Use the two widget modals as the styling
  source. **Phase R1:** strip our 7 legacy `woot-*` classes → Relay tokens.

### Feedback → *(no reference page — `components/FeedbackBreakdownModal.vue`)* → our `FeedbackPage.vue`  [demo — R3]
- Reference has only a breakdown **modal**. **Phase R3:** de-mock, or fold into an Overview
  breakdown modal.

---

## How I use this each phase
1. Open the reference `.vue` for the page (exact classes) + render it on `:5174` for the visual.
2. Port section-by-section into our page; swap `ui/*` → Relay components; keep our store/i18n/logic.
3. Mark genuinely-missing data `NiN` (`REPORT.DATA_PENDING`) — never fabricate.
4. Tick the item in `../reputation-redesign-plan.md` so nothing repeats.
