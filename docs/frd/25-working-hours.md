# FRD: Working Hours

**Status:** Shipped
**Module:** OSS core
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** Per-inbox, per-day-of-week open/close schedule that gates the "we'll reply during business hours" contact-facing behavior and feeds "business hours only" calculations elsewhere in the app (SLA thresholds, auto-assignment, campaign triggers).

**Who uses it:** Admins (configure per inbox), the system (every "was this within business hours?" check across SLA, reporting, campaigns).

---

## 2. How it works

1. One `WorkingHour` row per `(inbox, day_of_week)` — up to 7 rows per inbox. Each day is either `closed_all_day`, `open_all_day`, or has an explicit `open_hour`/`open_minutes`/`close_hour`/`close_minutes` range — validated (`0..23` for hours, `0..59` for minutes) only when neither all-day flag is set.
2. Model-level validations enforce internal consistency: `close_after_open` (close time must be after open time), `ensure_open_all_day_hours` and `open_all_day_and_closed_all_day` (mutually-exclusive-flag sanity checks) — prevents saving a nonsensical schedule (e.g. both `open_all_day` and `closed_all_day` true, or close before open).
3. `WorkingHour.today` scopes to the current day of week; `open_at?(time)`/`open_now?`/`closed_now?` are the actual query methods everything else calls — encapsulating the timezone-aware (inbox's own `timezone`, see [04-inboxes.md](04-inboxes.md)) open/closed logic in one place rather than each caller re-deriving it.
4. `Concerns::OutOfOfficiable` (included presumably by `Inbox`/`Conversation`) exposes this at the model level — e.g. deciding whether to send the inbox's `out_of_office_message` to a contact instead of the normal auto-reply.
5. Consumers beyond the obvious: `Account`/`Inbox` models reference it directly, `Inbox::EventDataPresenter` includes working-hours state in outbound event/webhook payloads, `InboxesController#update_inbox_working_hours` is a dedicated update path (separate from general inbox settings save — see [04-inboxes.md](04-inboxes.md)), and `ReportingEventHelper` uses it to compute `value_in_business_hours` on reporting events (see [13-reports.md](13-reports.md)) — the "response time during business hours only" metric depends directly on this feature's schedule data.

---

## 3. Data model

**Table:** `working_hours`
```
working_hours
  - account_id, inbox_id: bigint
  - day_of_week: integer, not null   # 0-6
  - closed_all_day: boolean, default false
  - open_all_day: boolean, default false
  - open_hour, open_minutes, close_hour, close_minutes: integer (required unless closed_all_day)
```
No unique index observed on `(inbox_id, day_of_week)` in the schema excerpt — uniqueness (one row per day per inbox) appears to be an application-level convention (`assign_account` callback, `self.today` scope) rather than a DB constraint.

---

## 4. Backend / API

**Routes:** working hours are managed as part of inbox settings — `POST /inboxes/:id` (general update, see [04-inboxes.md](04-inboxes.md)) with `InboxesController#update_inbox_working_hours` handling the working-hours-specific portion of the payload, rather than a standalone `/working_hours` resource.

**Model:** `app/models/working_hour.rb`. **Concern:** `app/models/concerns/out_of_officisable.rb`. **Consumers:** `app/models/{account,inbox}.rb`, `app/presenters/inbox/event_data_presenter.rb`, `app/helpers/reporting_event_helper.rb`.

---

## 5. Frontend

**Vue:** working-hours schedule editor (per-day open/close time pickers, all-day toggles) inside inbox settings, gated by the inbox's `working_hours_enabled` flag (see [04-inboxes.md](04-inboxes.md)).

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/working_hour_spec.rb` | validations, `open_at?`/`open_now?`/`closed_now?` logic, consistency callbacks |
| `spec/factories/working_hours.rb` | test data |

**Coverage gaps observed:** no dedicated spec found for `Concerns::OutOfOfficiable` itself, or for the SLA/reporting "business hours only" calculations that consume this data (`value_in_business_hours` — see [13-reports.md](13-reports.md), [19-sla-custom-roles.md](19-sla-custom-roles.md)) — those are likely covered within the SLA/reporting specs themselves rather than from the Working Hours side, but the cross-cutting timezone-conversion logic specifically wasn't confirmed as directly tested.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, `TZInfo` (inbox timezone validation/conversion, shared with [04-inboxes.md](04-inboxes.md))
- No external dependency

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Close time set before open time | Blocked by `close_after_open` validation |
| Both `open_all_day` and `closed_all_day` set true | Blocked by `open_all_day_and_closed_all_day` validation |
| `open_all_day` true but hour/minute fields also set | `ensure_open_all_day_hours` normalizes/validates this state |
| Inbox timezone changes after working hours are set | Hours are stored as plain integers (not timezone-aware timestamps) — interpreted against whatever the inbox's *current* timezone is at check-time, so a timezone change immediately reinterprets existing hours rather than requiring hours to be re-entered (behavior inferred from column design, not directly traced through `open_at?`) |

---

## 9. Open gaps / notes

- No DB-level unique constraint on `(inbox_id, day_of_week)` was found — relies on application code to avoid duplicate day rows per inbox. Low risk in practice (only reachable through the dedicated update path) but worth knowing if direct DB writes are ever done.
- The timezone-reinterpretation behavior on inbox timezone change (previous bullet) is inferred from the schema, not directly confirmed by reading `open_at?`'s implementation — worth a quick check if this edge case matters operationally.
