# Reputation Wire-Up Plan (de-mocking / making features functional)

Goal: turn the UI-only Reputation surfaces into real, persisted features.
Autonomous build — commits are LOCAL only (never push without explicit ask).
Update this file after **every** phase so issues don't repeat.

## Audit result (starting point)

Fully demo / no backend (UI-only "Save" flips a boolean):
- ConfigurationPage — AI config, spam config, review destination, slug, QR, template picks. Dead "Save Template Changes" button (no @click).
- AutomationPage — all rules local, `saveSettings()` fake.
- ReviewWidgetModal / VideoTestimonialWidgetModal — `handleSaveWidget()` fake, no persist.
- IntegrationsPage — hardcoded 12-platform array; toggles/sync/request all fake. **Intentional showcase** (real connect flow = SettingsPage). Leave as demo.

Real API w/ sample fallback (already badged, fine): Overview AI/trend, Listings, Feedback, Widgets preview, VideoTestimonials AI tabs.

## Design decision

No account-level reputation settings store exists. Add ONE schemaless store:
- `reputation_settings` table: `account_id` + `jsonb config` (one row per account, singular resource).
- Extend `reputation_widgets` with `jsonb config` for the widget-studio blobs.
Frontend owns the shape; strong params permit the whole `config` hash. Lazy + robust: no per-field columns for fast-moving UI state.

## Phases

### Phase A — Reputation Settings store  → ConfigurationPage + AutomationPage ✅ DONE
- [x] migration `reputation_settings` (account_id, jsonb config, timestamps, unique index on account_id)
- [x] model `Reputation::Setting` (belongs_to :account, has_one on Account)
- [x] `Api::V1::Accounts::Reputation::SettingsController` (show + update, singular; shallow-merge)
- [x] route `resource :settings, only: [:show, :update], controller: 'settings'`
- [x] migrate + smoke test (round-trip + merge verified via rails runner; route recognizes)
- [x] wire ConfigurationPage load(onMounted) + real save handlers (dead button now saves; Demo badge removed)
- [x] wire AutomationPage load + real save (localStorage → backend under `automation` key)
- commits: `3e02be89` (fe) + settings-store commit (be)
- Gotcha: config is ONE shallow-merged jsonb blob shared by Config (flat keys + aiSettings/spamSettings) and Automation (`automation` key). Keep keys namespaced so saves don't clobber each other.

### Phase B — Widget config persistence → both widget studios ✅ DONE
- [x] migration add `jsonb config` to `reputation_widgets`
- [x] permit `config: {}` in widgets_controller
- [x] ReviewWidgetModal: load on open (config.source == review_studio), Save = create-or-update
- [x] VideoTestimonialWidgetModal: same, tagged video_studio
- commit: `afc568c5`
- Gotcha: widget `style` enum is only carousel/grid/badge. Studios have extra layouts
  (compact / bubble / story_strip) — map non-enum → 'carousel' for the column, keep the real
  layout in `config.layout`. Studio widgets are identified by `config.source`, NOT name.

### Phase C — verify + document ✅ DONE
- [x] rubocop clean on all new Ruby (settings + widgets + migrations)
- [x] eslint clean on touched Vue (pre-commit lint-staged passed on each commit)
- [x] backend round-trips verified via rails runner (settings merge, widget config, route recognize)
- [x] this doc updated

## Left intentionally as demo (not a gap)
- IntegrationsPage — hardcoded showcase; the real platform-connect flow already lives in
  SettingsPage (`/reputation/integrations` OAuth). Wiring the 12-platform grid (mostly
  "Coming Soon", no backend) would duplicate SettingsPage. Keep badged "Demo".
- Sample-data fallbacks (Overview AI/trend, Listings, Feedback, Widgets preview) — correct
  behaviour: real API first, badged sample only when the account is empty.

## Log
(append dated notes per phase; record any gotcha so it isn't repeated)
