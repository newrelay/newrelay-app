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

### Phase A — Reputation Settings store  → ConfigurationPage + AutomationPage
- [ ] migration `reputation_settings` (account_id, jsonb config, timestamps, unique index on account_id)
- [ ] model `Reputation::Setting` (belongs_to :account)
- [ ] `Api::V1::Accounts::Reputation::SettingsController` (show + update, singular)
- [ ] route `resource :settings, only: [:show, :update], controller: 'settings'`
- [ ] migrate + smoke test
- [ ] wire ConfigurationPage load(onMounted) + real save handlers (kill dead button)
- [ ] wire AutomationPage load + real save

### Phase B — Widget config persistence → both widget studios
- [ ] migration add `jsonb config` to `reputation_widgets`
- [ ] permit `config` in widgets_controller
- [ ] ReviewWidgetModal: load existing carousel/grid widget config, Save = create-or-update
- [ ] VideoTestimonialWidgetModal: same for video style

### Phase C — verify + document
- [ ] rubocop clean on new Ruby
- [ ] eslint clean on touched Vue (pre-commit gate)
- [ ] update this doc + reputation-redesign-plan.md

## Log
(append dated notes per phase; record any gotcha so it isn't repeated)
