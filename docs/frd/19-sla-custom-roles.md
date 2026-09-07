# FRD: SLA Policies & Custom Roles

**Status:** Shipped
**Module:** Enterprise only
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** Two independent Enterprise-gated features bundled in this FRD as related "governance" concerns — **SLA Policies** (response/resolution time thresholds, monitored and breach-alerted per conversation) and **Custom Roles** (fine-grained permission sets beyond the base agent/administrator split).

**Who uses it:** Admins (define policies/roles), the SLA monitor job (evaluates every applied SLA on a schedule), agents (assigned a custom role, gaining/losing specific capabilities).

---

## 2. How it works

### SLA Policies
1. An `SlaPolicy` defines up to three thresholds (in seconds/float): `first_response_time_threshold`, `next_response_time_threshold`, `resolution_time_threshold`, optionally scoped `only_during_business_hours`.
2. A policy is applied to a conversation by creating an `AppliedSla` row (unique per `account+policy+conversation` — one active application per conversation per policy) — conversations link via `sla_policy_id` (see [01-conversations.md](01-conversations.md)).
3. `Sla::TriggerSlasForAccountsJob` (cron, fans out per account) → `Sla::ProcessAccountAppliedSlasJob` (per account) → `Sla::ProcessApplied SlaJob` (per applied SLA) → `Sla::EvaluateAppliedSlaService` does the actual threshold check against the conversation's current timestamps (`first_reply_created_at`, `waiting_since`, etc. — see [01-conversations.md](01-conversations.md) data model).
4. Each evaluation can write an `SlaEvent` (`event_type` + `meta` jsonb) — an audit trail of breaches/near-breaches per applied SLA, not just a pass/fail flag; `AppliedSla.sla_status` holds the current state.
5. This three-job fan-out (accounts → applied SLAs → individual evaluation) is a deliberate scaling pattern — evaluating every applied SLA across every account in one giant job would be a single slow/fragile unit; splitting it lets failures/retries stay scoped to one conversation's SLA check.
6. SLA breach data feeds directly into [13-reports.md](13-reports.md) (`applied_slas` reporting endpoint) and conversation reporting-events.

### Custom Roles
7. A `CustomRole` is a named, account-scoped bundle of `permissions` (a Postgres text array, not jsonb) drawn from a fixed whitelist: `conversation_manage`, `conversation_unassigned_manage`, `conversation_participating_manage`, `contact_manage`, `report_manage`, `knowledge_base_manage`, `reputation_manage`, `marketing_manage`, `crm_manage`, `company_manage`, `captain_manage`.
8. An `AccountUser` (see [10-teams-agents.md](10-teams-agents.md)) optionally references a `custom_role_id` — this layers on top of, not instead of, the base `role` enum (`agent`/`administrator`); custom roles refine what an *agent* can do, they don't replace the admin/agent split itself.
9. The permission list directly mirrors newrelay's custom feature areas (`reputation_manage`, `marketing_manage`, `crm_manage`, `company_manage`, `captain_manage` alongside the stock `conversation_manage`/`contact_manage`/`report_manage`/`knowledge_base_manage`) — confirms custom roles were extended specifically to gate the newrelay-added modules (Reputation, CRM, Comment-to-DM/"marketing", Captain), not just core Chatwoot features.
10. Policy checks throughout the app (`app/policies/*_policy.rb`) consult the custom role's permission list where applicable, in addition to the base `agent`/`administrator` check.

---

## 3. Data model

```
sla_policies
  - account_id, name, description
  - first_response_time_threshold, next_response_time_threshold, resolution_time_threshold: float
  - only_during_business_hours: boolean, default false

applied_slas
  - account_id, sla_policy_id, conversation_id: bigint, not null
  - sla_status: integer, default 0
  - unique per (account_id, sla_policy_id, conversation_id)

sla_events
  - applied_sla_id, conversation_id, account_id, sla_policy_id, inbox_id: bigint, not null
  - event_type: integer
  - meta: jsonb, default {}

custom_roles
  - account_id, name, description
  - permissions: text[], default []   # whitelist-validated
```

---

## 4. Backend / API

**Routes:**
| Method | Path | Controller#action |
|---|---|---|
| GET/POST | `/sla_policies` | `sla_policies#index/create` |
| GET/PATCH/DELETE | `/sla_policies/:id` | `sla_policies#show/update/destroy` |
| GET | `/applied_slas` | `applied_slas#index` |
| GET/POST | `/custom_roles` | `custom_roles#index/create` |
| GET/PATCH/DELETE | `/custom_roles/:id` | `custom_roles#show/update/destroy` |

**Engine:** `enterprise/app/jobs/sla/{trigger_slas_for_accounts_job, process_account_applied_slas_job, process_applied_sla_job}.rb`, `enterprise/app/services/sla/evaluate_applied_sla_service.rb`, `enterprise/app/models/{sla_policy, applied_sla, custom_role}.rb`.

---

## 5. Frontend

**Vue:** SLA policy builder under `dashboard/routes/dashboard/settings/sla/`, custom role builder under `dashboard/routes/dashboard/settings/custom-roles/` (permission checkbox list matching the model's `PERMISSIONS` whitelist), SLA breach indicators on the conversation list/detail view.

---

## 6. Test coverage (as it exists today)

~33 spec files. Representative: `spec/enterprise/models/{sla_policy,applied_sla,custom_role}_spec.rb`, `spec/enterprise/jobs/sla/*_spec.rb` (all three fan-out jobs), `spec/enterprise/services/sla/evaluate_applied_sla_service_spec.rb`, `spec/enterprise/controllers/api/v1/accounts/{sla_policies,custom_roles}_controller_spec.rb`, `spec/enterprise/policies/*_policy_spec.rb` (custom-role-gated authorization checks across many resources).

**Coverage gaps observed:** none significant — the three-stage job fan-out and the evaluation service both have direct specs, which is the part most likely to have subtle bugs (timing/threshold edge cases).

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, Sidekiq (3-stage SLA job fan-out via `sidekiq-cron`), PostgreSQL array column (`custom_roles.permissions` — not jsonb, a plain Postgres text array)
- No external dependency for either feature

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Same policy applied to the same conversation twice | Blocked by unique index `(account_id, sla_policy_id, conversation_id)` |
| One conversation's SLA evaluation fails/errors | Isolated to its own `ProcessAppliedSlaJob` — doesn't abort the account-wide or global sweep |
| Custom role granted a permission outside the whitelist | Blocked by `validates :permissions, inclusion: { in: PERMISSIONS }` |
| SLA policy deleted while conversations still reference it | `has_many :conversations, dependent: :nullify` — conversations lose the SLA link rather than being destroyed |

---

## 9. Open gaps / notes

- None significant — both features are well-scoped, well-tested, and the SLA job fan-out pattern (accounts → applied SLAs → individual evaluation) is a solid reference for any future per-conversation scheduled evaluation work.
