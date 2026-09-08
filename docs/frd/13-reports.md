# FRD: Reports

**Status:** Shipped
**Module:** OSS core (v2 reports engine), Enterprise (some report endpoints gated)
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** The analytics layer — every meaningful conversation event (resolved, first-response, bot-handoff) is recorded as a `ReportingEvent`, rolled up daily into `ReportingEventsRollup` for fast querying, and surfaced through per-dimension report endpoints (agent, team, inbox, label, channel) and CSV export.

**Who uses it:** Admins/managers (dashboards, CSV exports), the event system (writes events as things happen), a background rollup job (aggregates for fast reads).

---

## 2. How it works

1. **Write path:** `app/listeners/reporting_event_listener.rb` subscribes to domain events and writes raw `ReportingEvent` rows:
   - `conversation_resolved` → records resolution time (`value`, `value_in_business_hours` separately accounts for working-hours-only duration)
   - `first_reply_created` → records `name: 'first_response'` (first-response time)
   - `reply_created` → subsequent reply timing
   - `conversation_bot_handoff` / `conversation_captain_inference_resolved` / `conversation_captain_inference_handoff` → AI/bot-specific metrics
   - `conversation_opened` (reopen after resolve) → tracks reopen timing relative to the prior resolution
2. Each raw event carries `event_start_time`/`event_end_time` so downstream consumers can compute duration without re-deriving it, plus optional `value_in_business_hours` to answer "how long during working hours" separately from wall-clock time.
3. **Rollup path:** `ReportingEvents::RollupService` aggregates raw events into `reporting_events_rollups` — one row per `(account, date, dimension_type, dimension_id, metric)` (dimension = agent/team/inbox/label/etc.), storing `count`, `sum_value`, `sum_value_business_hours`. This is what report endpoints actually query for anything beyond a live/small window — avoids scanning raw events for date-range reports. `ReportingEvents::BackfillService` can regenerate rollups historically (e.g. after a metric definition change).
4. `ReportingEvents::EventMetricRegistry` / `MetricRegistry` centralize the mapping of event name → metric definition, so builders don't hardcode event-name strings.
5. **Read path:** `Api::V2::Accounts::ReportsController` exposes one endpoint per report shape (`summary`, `agents`, `inboxes`, `labels`, `teams`, `conversations`, `conversation_traffic`, `bot_metrics`, `bot_summary`, `inbox_label_matrix`, `first_response_time_distribution`, `outgoing_messages_count`), each backed by its own builder under `app/builders/v2/reports/*_builder.rb` (one class per report — no shared "god" report service).
6. `SummaryReportsController` (`/summary_reports/{agent,team,inbox,label,channel}`) and `LiveReportsController` cover lighter-weight/real-time variants separate from the historical `reports#*` endpoints.
7. CSV export (`generate_csv`) reuses the same builders, just renders a different format.
8. A separate `Year in Review` resource (`resource :year_in_review`) produces an annual summary.

---

## 3. Data model

**Table:** `reporting_events` (raw, append-only)
```
reporting_events
  - account_id, inbox_id, user_id, conversation_id: integer (optional except account_id)
  - name: string          # 'conversation_resolved', 'first_response', 'conversation_bot_handoff', 'conversation_opened', 'conversation_captain_inference_resolved', etc.
  - value: float, not null
  - value_in_business_hours: float
  - event_start_time, event_end_time: datetime
```

**Table:** `reporting_events_rollups` (pre-aggregated, one row per day/dimension/metric)
```
reporting_events_rollups
  - account_id: bigint, not null
  - date: date, not null
  - dimension_type: string, not null   # e.g. "Agent", "Inbox", "Team", "Label"
  - dimension_id: bigint, not null
  - metric: string, not null
  - count: bigint, default 0
  - sum_value: float, default 0.0
  - sum_value_business_hours: float, default 0.0
```
Unique key on `(account_id, date, dimension_type, dimension_id, metric)` — one row per day/dimension/metric combination, upserted by the rollup service.

---

## 4. Backend / API

**Routes (v2):**
| Method | Path | Controller#action |
|---|---|---|
| GET | `/reports/summary` \| `/agents` \| `/inboxes` \| `/labels` \| `/teams` \| `/conversations` \| `/conversations_summary` \| `/conversation_traffic` \| `/bot_metrics` \| `/bot_summary` \| `/inbox_label_matrix` \| `/first_response_time_distribution` \| `/outgoing_messages_count` | `api/v2/accounts/reports#*` |
| GET | `/summary_reports/{agent,team,inbox,label,channel}` | `summary_reports#*` |
| GET | `/live_reports/*` | `live_reports#*` |
| GET | `/year_in_review` | `year_in_review#show` |
| GET (Enterprise) | `/reporting_events` | account-scoped raw event access, enterprise-gated |

**Engine:** `app/listeners/reporting_event_listener.rb`, `app/services/reporting_events/rollup_service.rb`, `backfill_service.rb`, `event_metric_registry.rb`, `metric_registry.rb`, `app/services/reports/raw_data_source.rb`, `app/builders/v2/reports/*.rb`, `app/builders/v2/reports/timeseries/`, `app/builders/v2/reports/conversations/`.

---

## 5. Frontend

**Vue:** report dashboards under `dashboard/routes/dashboard/settings/reports/` — one view per report type (overview, agents, teams, inboxes, labels, CSAT, conversation traffic), charts via `chart.js`/`vue-chartjs`.

**States handled:** date-range picker, per-dimension drill-down, CSV download trigger, empty/no-data state.

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/reporting_event_spec.rb`, `reporting_events_rollup_spec.rb` | model validations |
| `spec/listeners/reporting_event_listener_spec.rb` | event → raw event creation |
| `spec/services/reporting_events/` | rollup + backfill logic |
| `spec/builders/v2/report_builder_spec.rb` + `spec/builders/v2/reports/*_spec.rb` (agent, team, channel, inbox, label, bot metrics, first-response distribution, conversations, timeseries) | per-report-type calculation logic — one spec per builder |
| `spec/controllers/api/v2/accounts/reports_controller_spec.rb`, `report_controller_spec.rb`, `summary_reports_controller_spec.rb`, `live_reports_controller_spec.rb` | endpoint-level coverage |
| `spec/enterprise/controllers/api/v1/accounts/reporting_events_controller_spec.rb`, `spec/enterprise/controllers/enterprise/api/v2/accounts/reports_controller_spec.rb` | Enterprise-gated endpoints |
| `spec/helpers/reporting_event_helper_spec.rb` | helper logic |

**Coverage gaps observed:** none significant — this is the most exhaustively spec'd feature reviewed so far (one spec file per builder class, matching the one-builder-per-report-type architecture).

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, PostgreSQL (rollup upsert pattern via unique composite index), Sidekiq (rollup/backfill jobs run async)
- Frontend: `chart.js` + `vue-chartjs`

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Rollup write races with another rollup for the same day/dimension/metric | Protected by the unique composite index — service presumably upserts (`find_or_create`/`upsert`) rather than blind insert |
| Metric definitions change after historical data exists | `BackfillService` exists specifically to regenerate rollups from raw events |
| Reporting event created without a matching rollup yet | `safe_rollup` wrapper in the listener (per method name) suggests rollup failures don't block the raw event write |

---

## 9. Price / plan gating

**Gating type:** Ungated boolean. No report-row quota.
**`feature_key`(s):** `reports`, `report_rollup`

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | yes | — | |
| Standard | yes | — | |
| Business | yes | — | |
| Enterprise | yes | negotiated | |

**Credits / usage:** none
**Enforced by:** `account.feature_enabled?('reports')` after `ReconcilePlanFeaturesService`
**Source:** `lib/seeders/plan_feature_limit_seeder.rb`

---

## 10. Open gaps / notes

- None significant — well-architected (raw event + rollup + registry + per-report builder separation) and well-tested. Good reference pattern if a new custom report type needs to be added later (Reputation/CRM reporting could follow the same `builders/v2/reports/*_builder.rb` convention).
