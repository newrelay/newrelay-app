# FRD: Macros

**Status:** Shipped
**Module:** OSS core
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** A saved, manually-triggered bundle of actions (assign, reply, label, resolve, etc.) an agent runs on one or more conversations with a single click — unlike Automation Rules, macros are agent-initiated, not event-triggered.

**Who uses it:** Agents (run on a conversation), admins (author/manage macros, control visibility).

---

## 2. How it works

1. A macro stores an ordered `actions` array (jsonb, same shape as Automation Rules: `{action_name, action_params}`) and a `visibility` (`personal` — only the creator sees/runs it, or `global` — whole account).
2. `created_by`/`updated_by` track authorship; `check_authorization` in the controller enforces that only the owner (or an admin) can edit/delete a `personal` macro.
3. Agent clicks "run macro" on a conversation → `POST /macros/:id/execute` with target `conversation_ids` → enqueues `MacrosExecutionJob` (Sidekiq, `queue_as :medium`) rather than running synchronously, so bulk-running across many conversations doesn't block the request.
4. The job loads the account's conversations by `display_id` and runs `Macros::ExecutionService#perform` per conversation.
5. `Macros::ExecutionService` extends the same shared `ActionService` base class as `AutomationRules::ActionService` (see [06-automation-rules.md](06-automation-rules.md)) — so most actions (`assign_agent`, `add_private_note`, `send_message`, `send_attachment`, `send_webhook_event`, plus inherited status/priority/label actions) behave identically between macros and automation rules, just invoked differently (click vs. event).
6. Macros can attach files (`has_many_attached :files`) for the `send_attachment` action, same pattern as automation rules.

---

## 3. Data model

**Table:** `macros`
```
macros
  - account_id: bigint, not null
  - name: string, not null
  - visibility: integer, default 0     # enum personal:0 global:1
  - created_by_id, updated_by_id: bigint (User)
  - actions: jsonb, default {}, not null   # array of {action_name, action_params}
```

**Relationships:** `belongs_to :account, :created_by (User), :updated_by (User)`; `has_many_attached :files`.

---

## 4. Backend / API

**Routes** (`config/routes.rb`):
| Method | Path | Controller#action |
|---|---|---|
| GET | `/macros` | `macros#index` |
| POST | `/macros` | `macros#create` |
| GET/PATCH/DELETE | `/macros/:id` | `macros#show/update/destroy` |
| POST | `/macros/:id/execute` | `macros#execute` → enqueues `MacrosExecutionJob` |

**Engine:** `app/services/macros/execution_service.rb` (extends `app/services/action_service.rb`); `app/jobs/macros_execution_job.rb` (queue: `medium`).

---

## 5. Frontend

**Vue:** macro builder + run picker under `dashboard/routes/dashboard/settings/macros/` (per git status, recently touched: `MacroProperties`, `MacrosTableRow` specs) and the in-conversation "run macro" dropdown in the conversation action panel.

**States handled:** personal-vs-global visibility indicator, running/executed toast, permission-gated edit for non-owned personal macros.

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/macro_spec.rb`, `spec/enterprise/models/macro_spec.rb` | validations, visibility enum, Enterprise extensions |
| `spec/services/macros/execution_service_spec.rb` (under `spec/services/macros/`) | action execution logic |
| `spec/controllers/api/v1/accounts/macros_controller_spec.rb` | CRUD + execute endpoint, authorization |

**Coverage gaps observed:** no dedicated `spec/jobs/macros_execution_job_spec.rb` found — the job's multi-conversation looping/error-isolation behavior (does one failing conversation abort the batch?) doesn't appear to be directly tested; confirm before assuming it's covered.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, Sidekiq (`MacrosExecutionJob`, `queue_as :medium`), ActiveStorage (attachments)
- Shares its action-execution engine with Automation Rules (`ActionService` base) — no separate dependency

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| `execute` called with no matching conversations | Job returns early (`return if conversations.blank?`), no error |
| Macro run across multiple conversations, one action fails on one conversation | Not explicitly isolated per-conversation in the job (unlike `AutomationRules::ActionService`, which rescues per-action) — a raised error in `ExecutionService#perform` would need checking against the actual `perform` method to confirm whether it's rescued the same way |
| Non-owner tries to edit a `personal` macro | Blocked by `check_authorization` |

---

## 9. Open gaps / notes

- Unlike `AutomationRules::ActionService#perform`, which wraps each action in its own `rescue`, it's not confirmed here whether `Macros::ExecutionService#perform` does the same per-action error isolation, or whether one bad action/conversation could abort the rest of a bulk macro run. Worth a quick code check before relying on "partial failure is safe" behavior.
- No job-level spec found for `MacrosExecutionJob` — flagged for follow-up.
