# FRD: Bulk Actions

**Status:** Shipped
**Module:** OSS core
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** Apply one operation (assign, label, snooze, status change, delete) to many conversations or contacts at once, selected via checkboxes in the dashboard list view, processed asynchronously with an audit trail of the result.

**Who uses it:** Agents/admins, from the conversation list or contacts book multi-select toolbar.

---

## 2. How it works

1. `BulkActionsController#create` accepts a `type` (conversation or contact) and a list of `ids`, plus the action-specific params, and enqueues either `enqueue_conversation_job` or `enqueue_contact_job` — actual work always happens in a background job, never inline, since a bulk action can touch up to `Limits::BULK_ACTIONS_LIMIT` (100) records.
2. For conversations: `BulkActionsJob#bulk_update` runs three passes over the selected records — `bulk_remove_labels`, then per-conversation `bulk_add_labels`, `bulk_snoozed_until`, and a general attribute `update` (status, assignee, priority, etc.) — so a single bulk action can combine several changes in one submit (e.g. "assign to agent X and add label Y" together).
3. For contacts: a separate, contact-specific pipeline — `Contacts::BulkActionService` dispatches to `Contacts::BulkAssignLabelsService`, `BulkRemoveLabelsService`, `BulkDeleteService` (see also [09-labels-custom-attributes.md](09-labels-custom-attributes.md)) — contact deletion is gated by its own `check_authorization_for_contact_action`/`delete_contact_action?` check, since bulk-deleting contacts is more destructive than the conversation-side operations.
4. `BulkActionAudit` records the outcome: `action_label`/`operation_type` (what was requested), `status`, `statistics` (jsonb — presumably counts of succeeded/failed/skipped records), `completed_at` — giving the user a way to check back on a large bulk action's result rather than just trusting a fire-and-forget request succeeded.
5. `Current.user`/`Current.reset` wrap the job so downstream code (e.g. audit logging, "who did this" attribution on the affected records) sees the correct acting user even though the work runs in a background worker, not the original request.

---

## 3. Data model

**Table:** `bulk_action_audits`
```
bulk_action_audits
  - account_id, user_id: bigint, not null
  - action_label: string, not null
  - operation_type: string, not null
  - status: integer, default 0
  - statistics: jsonb, default {}
  - completed_at: datetime
```
No dedicated table for the bulk operation itself — conversations/contacts/labels are updated directly on their own tables; only the audit record is bulk-actions-specific.

---

## 4. Backend / API

**Routes:**
| Method | Path | Controller#action |
|---|---|---|
| POST | `/bulk_actions` | `bulk_actions#create` (conversations/contacts) |
| — | `/bulk_action_audits` | read the audit trail (see [09-labels-custom-attributes.md]/general account routes) |

**Jobs:** `app/jobs/bulk_actions_job.rb` (conversations, `queue_as :medium`), `app/jobs/contacts/bulk_action_job.rb` (contacts).

**Services:** `app/services/contacts/{bulk_action_service, bulk_assign_labels_service, bulk_remove_labels_service, bulk_delete_service}.rb`.

**Limit:** `Limits::BULK_ACTIONS_LIMIT = 100` (`lib/limits.rb`) — max records per bulk operation.

---

## 5. Frontend

**Vue:** multi-select checkboxes + bulk-action toolbar on the conversation list and contacts book; a bulk-action-audit history view (likely under settings or a notifications-style panel) to check on completed/in-progress runs.

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/controllers/api/v1/accounts/bulk_actions_controller_spec.rb` | endpoint, conversation/contact dispatch |
| `spec/jobs/bulk_actions_job_spec.rb` | conversation bulk-update job |
| `spec/jobs/contacts/bulk_action_job_spec.rb` | contact bulk job |
| `spec/services/contacts/bulk_action_service_spec.rb` | contact service dispatch |
| (label-specific: `bulk_assign_labels_service_spec.rb`, `bulk_remove_labels_service_spec.rb` — see [09-labels-custom-attributes.md](09-labels-custom-attributes.md)) | |

**Coverage gaps observed:** no `spec/models/bulk_action_audit_spec.rb` found — the audit record itself (statistics shape, status transitions) doesn't appear to have a direct model spec; likely exercised indirectly through the job specs, but not confirmed.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, Sidekiq (`queue_as :medium`), `Current` (Rails' `ActiveSupport::CurrentAttributes`) for propagating the acting user into background context

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| More than 100 ids submitted | Blocked before enqueue (`Limits::BULK_ACTIONS_LIMIT`) |
| Non-admin attempts bulk-delete on contacts | Blocked via `check_authorization_for_contact_action`/`delete_contact_action?` |
| One record in the batch fails to update | Not confirmed whether the job isolates per-record failures (continues the loop) or aborts the whole batch — worth checking given the pattern in [07-macros.md](07-macros.md) flagged the same uncertainty for a different bulk job |

---

## 9. Price / plan gating

**Gating type:** Mixed — bulk actions themselves are not in the matrix; the bulk-action audit log flag is Business-only.
**`feature_key`(s):** none for bulk actions. Related: `audit_logs` (premium)

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | bulk actions not gated; audit log no | — | `audit_logs` off |
| Standard | bulk actions not gated; audit log no | — | `audit_logs` off |
| Business | yes | — | `audit_logs` on |
| Enterprise | yes | negotiated | |

**Credits / usage:** none
**Enforced by:** conversation permissions for the action; `account.feature_enabled?('audit_logs')` for the audit trail
**Source:** `lib/seeders/plan_feature_limit_seeder.rb` (`PREMIUM_ONLY_FEATURES` includes `audit_logs`)

---

## 10. Open gaps / notes

- Per-record failure isolation within `BulkActionsJob`/`Contacts::BulkActionJob` not directly confirmed — same class of open question as flagged for `MacrosExecutionJob` in [07-macros.md](07-macros.md). Worth a single pass checking all "loop over N records in a background job" code paths in the codebase for consistent error-isolation behavior.
- No direct `BulkActionAudit` model spec found.
