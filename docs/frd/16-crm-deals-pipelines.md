# FRD: CRM (Deals, Pipelines, Companies, Tasks)

**Status:** Shipped (MVP scope per `docs/solution-notes/crm-deals-pipelines-prd.md`)
**Module:** newrelay custom — `Deal`/`Pipeline`/`PipelineStage`/`Task` are OSS-core models; `Company` is Enterprise-only
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** A lightweight sales CRM layered on top of Contacts — `Deal`s move through ordered `PipelineStage`s within a `Pipeline`, optionally linked to a `Contact`/`Company` and owned by an agent; `Task`s are simple to-dos linkable to contacts.

**Who uses it:** Agents/admins managing sales pipelines alongside support conversations — the differentiator being deals live next to the same Contact record used for support, not a separate CRM tool.

---

## 2. How it works

1. **One domain object, not three:** per the approved PRD, "Deals", "Pipelines", and "Opportunities" (as seen in the NewRelay-UI mock) are all views over the same `Deal` rows — a table view, a kanban-by-stage view, and an amount/close-date-focused table are just different renderings, not separate entities. This avoided building/maintaining duplicate schemas.
2. A `Pipeline` is a named, ordered container (`position`) of `PipelineStage`s; each stage has its own `position` (ordering within the pipeline), a `color`, and `is_won`/`is_lost` booleans marking terminal stages.
3. A `Deal` belongs to exactly one `pipeline` + `pipeline_stage`, and the model enforces `stage_belongs_to_pipeline` (custom validation) so a deal can't reference a stage from a different pipeline.
4. Optional links: `contact` (validated to belong to the same account — `contact_belongs_to_account`), `owner` (a `User`, validated `owner_belongs_to_account`), and `company` — **the `company` association only exists `if ChatwootApp.enterprise?`**, since `Company` itself is an Enterprise-only model (`enterprise/app/models/company.rb`) despite its `companies` table living in the core OSS schema. This is the cleanest example in the codebase of "OSS schema, Enterprise behavior" — the table is always there, but only Enterprise code paths populate/use it.
5. `DealsController#ensure_default_pipeline` (a `before_action`) auto-creates a default pipeline+stages for the account on first use, so deals work out of the box without a setup step.
6. Deal money is stored as `amount_cents` (integer) + `currency` (string, default `USD`) — avoids float rounding issues, standard Rails money pattern (not using a gem like `money-rails`, just a plain cents column).
7. `priority` enum (`low/medium/high`, default `medium`) and `probability` (0-100 integer) are simple fields, not a computed forecasting engine — matches the PRD's explicit non-goal of "no custom stage probability engines, forecasting, quoting, invoices."
8. `Task` is a separate, simpler concept — `belongs_to :assignee (User)`, `has_many :contacts, through: :contact_tasks` — a to-do linkable to one or more contacts, not tied to deals/pipelines at all.
9. Companies (Enterprise) have their own lifecycle — `Contacts::CompanyAssociationService`, migration jobs (`CompanyAccountBatchJob`, `CompanyBackfillJob`) suggest companies were backfilled/associated onto existing contacts after the feature shipped.

---

## 3. Data model

**Table:** `pipelines`
```
pipelines
  - account_id: bigint, not null
  - name: string, not null (unique per account_id)
  - position: integer, default 0
```

**Table:** `pipeline_stages`
```
pipeline_stages
  - account_id, pipeline_id: bigint, not null
  - name: string, not null (unique per pipeline_id)
  - position: integer, default 0
  - color: string, default "primary"
  - is_won, is_lost: boolean, default false
```

**Table:** `deals`
```
deals
  - account_id, pipeline_id, pipeline_stage_id: bigint, not null
  - contact_id, company_id, owner_id: bigint (all optional)
  - name: string, not null
  - amount_cents: bigint, default 0
  - currency: string, default "USD"
  - close_on: date
  - priority: integer, default 1     # enum low:0 medium:1 high:2
  - probability: integer, default 0  # 0-100
```

**Table:** `companies` (schema exists in OSS, model is Enterprise-only)
```
companies
  - account_id: bigint, not null
  - name: string, not null
  - domain: string (unique per account_id where present)
  - description: text
  - contacts_count: integer
  - additional_attributes, custom_attributes: jsonb
```

**Table:** `tasks` + `contact_tasks` (join to contacts)

---

## 4. Backend / API

**Routes:**
| Method | Path | Controller#action |
|---|---|---|
| GET/POST | `/pipelines` | `pipelines#index/create` |
| GET/PATCH/DELETE | `/pipelines/:id` | `pipelines#show/update/destroy` |
| GET/POST | `/deals` | `deals#index/create` |
| GET/PATCH/DELETE | `/deals/:id` | `deals#show/update/destroy` |
| GET/POST/PATCH/DELETE | `/companies` (Enterprise) | `enterprise/.../companies_controller#*` |
| — | `/tasks` | `tasks#*` |

**Models/services:** `app/models/{deal,pipeline,pipeline_stage,task,contact_task}.rb`, `enterprise/app/models/company.rb`, `enterprise/app/services/contacts/company_association_service.rb`, `enterprise/app/jobs/migration/{company_account_batch_job,company_backfill_job}.rb`.

---

## 5. Frontend

**Vue:** deal table + kanban board under `dashboard/routes/dashboard/deals/` (or similar), ported from `NewRelay-UI/src/views/{deals,pipelines,opportunities}/*` per the PRD — table view with board toggle, stage metric chips, deal drawer for detail/edit, drag-to-change-stage on the kanban board. Explicitly built on Relay design tokens, no `woot-*` legacy components, no hardcoded hex, no fabricated demo metrics in production.

**States handled:** empty pipeline (auto-created default), drag-drop stage change, deal drawer create/edit.

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/deal_spec.rb` | validations (`stage_belongs_to_pipeline`, account-scoping checks) |
| `spec/controllers/api/v1/accounts/deals_controller_spec.rb`, `spec/enterprise/controllers/.../deals_controller_spec.rb` | CRUD, `ensure_default_pipeline` behavior |
| `spec/services/pipelines/` | pipeline/stage logic |
| `spec/enterprise/models/company_spec.rb`, `contact_company_association_spec.rb` | Enterprise company model + contact linkage |
| `spec/enterprise/policies/company_policy_spec.rb` | authorization |
| `spec/enterprise/controllers/api/v1/accounts/companies_controller_spec.rb`, `companies_custom_role_spec.rb` | Enterprise controller + role-gated access |
| `spec/enterprise/services/contacts/company_association_service_spec.rb` | association logic |
| `spec/enterprise/jobs/migration/company_account_batch_job_spec.rb`, `company_backfill_job_spec.rb` | historical backfill jobs |
| `spec/enterprise/services/companies/` | additional company services |

**Coverage gaps observed:** no dedicated `spec/models/pipeline_spec.rb` or `pipeline_stage_spec.rb` found (pipeline logic tested indirectly via `spec/services/pipelines/` and the deal spec's stage-validation coverage) — likely fine given deal validations exercise the pipeline/stage relationship, but a direct model spec wasn't confirmed. No `spec/models/task_spec.rb` found either.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails — plain integer-cents money pattern (no `money-rails` gem), no forecasting/quoting library
- Frontend: Vue 3, drag-and-drop for kanban (likely `vuedraggable`, already a project dependency)
- No external CRM/sales-tool integration — fully in-house

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Account has no pipeline yet | `ensure_default_pipeline` before_action creates one automatically |
| Deal's stage doesn't belong to its pipeline | Blocked by `stage_belongs_to_pipeline` custom validation |
| Deal references a contact/owner/company from another account | Blocked by `contact_belongs_to_account`/`owner_belongs_to_account`/`company_belongs_to_account` validations |
| OSS (non-Enterprise) instance sets a `company_id` on a deal | Association doesn't exist in OSS mode (`if ChatwootApp.enterprise?` gate) — the field would be ignored/inert at the model layer |
| Pipeline deleted with deals still in it | Not confirmed — check `dependent:` option on `Pipeline has_many :deals` (not directly inspected in this pass) before assuming safe cascade |

---

## 9. Open gaps / notes

- Deletion cascade behavior for `Pipeline`/`PipelineStage` when deals still reference them wasn't directly confirmed — worth a quick check (`dependent: :restrict_with_error` vs `:destroy` vs nothing) since a dangling `pipeline_stage_id` would break the `stage_belongs_to_pipeline` invariant.
- No direct `pipeline_spec.rb`/`pipeline_stage_spec.rb`/`task_spec.rb` found — likely adequately covered indirectly, but not confirmed.
- This PRD explicitly deferred CSV import, deal templates, fabricated analytics/forecasting, and a separate Opportunity entity — worth checking with the user before treating any of those as "missing" rather than "intentionally out of scope."
