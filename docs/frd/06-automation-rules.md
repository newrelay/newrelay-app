# FRD: Automation Rules

**Status:** Shipped
**Module:** OSS core (event-driven), Enterprise (adds extra event types via `spec/enterprise/models/automation_rule_spec.rb`)
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** "If X happens, do Y" rules — when a conversation/message event fires and its conditions match, a set of actions run automatically (assign, label, reply, notify, etc.), with no agent involved.

**Who uses it:** Admins (author rules), the event system (evaluates/executes them on every relevant conversation/message event).

---

## 2. How it works

1. An automation rule is defined per-account with an `event_name` (the trigger), `conditions` (jsonb array of attribute/operator/value filters), and `actions` (jsonb array of `{action_name, action_params}`), plus `active` toggle.
2. Every real-time domain event (`conversation_created`, `conversation_updated`, `conversation_opened`, `conversation_resolved`, `message_created`) is broadcast through the app's event dispatcher (`app/dispatchers/async_dispatcher.rb`) and `AutomationRuleListener` (a registered listener singleton) receives it.
3. On event receipt, the listener loads only the account's **active** rules matching that `event_name` (`current_account_rules`), short-circuiting entirely if none exist (`rule_present?`).
4. Each candidate rule's `conditions` are evaluated against the conversation by `AutomationRules::ConditionsFilterService` — only if all conditions match does the rule proceed to actions.
5. Matching rules run through `AutomationRules::ActionService#perform`, iterating `actions` and calling the named action method (`assign_agent`, `add_label`, `change_status`, `send_email_transcript`, `send_attachment`, `send_webhook_event`, `add_private_note`, `send_email_to_team`, etc. — see full list in §4). Each action is wrapped in a rescue that reports to `ChatwootExceptionTracker` rather than aborting the whole rule.
6. Guard logic prevents infinite loops / noise: `performed_by_automation?` skips events caused by automation itself; `ignore_auto_reply_event?`/`ignore_message_created_event?` skip bot/system-generated messages from re-triggering `message_created` rules; `conversation_created`/`conversation_opened` are excluded from auto-reply-triggering paths.
7. `AutomationRules::ConditionValidationService` validates rule conditions at **save time** (admin UI), independent of the runtime filter service.
8. Rules can attach files (`has_many_attached :files`) used by the `send_attachment` action.
9. Rules can be cloned (`POST .../automation_rules/:id/clone`) to quickly derive variants.

---

## 3. Data model

**Table:** `automation_rules`
```
automation_rules
  - account_id: bigint, not null
  - name: string, not null
  - description: text
  - event_name: string, not null        # e.g. conversation_created, conversation_updated, message_created, conversation_opened, conversation_resolved
  - conditions: jsonb, default {}, not null   # array of {attribute_key, filter_operator, values}
  - actions: jsonb, default {}, not null      # array of {action_name, action_params}
  - active: boolean, default true, not null
```

**Relationships:** `belongs_to :account`; `has_many_attached :files` (ActiveStorage, for `send_attachment` action).

**No dedicated migration-time backfill** — new rules start `active: true` by default.

---

## 4. Backend / API

**Routes** (`config/routes.rb`):
| Method | Path | Controller#action |
|---|---|---|
| GET | `/automation_rules` | `automation_rules#index` |
| POST | `/automation_rules` | `automation_rules#create` |
| GET/PATCH/DELETE | `/automation_rules/:id` | `automation_rules#show/update/destroy` |
| POST | `/automation_rules/:id/clone` | `automation_rules#clone` |

**Engine:**
- `app/listeners/automation_rule_listener.rb` — subscribes to conversation/message domain events (registered in `app/dispatchers/async_dispatcher.rb`)
- `app/services/automation_rules/conditions_filter_service.rb` — runtime condition matching
- `app/services/automation_rules/condition_validation_service.rb` — save-time validation
- `app/services/automation_rules/action_service.rb` (extends shared `app/services/action_service.rb`) — executes actions

**Available actions** (from `ActionService` base + `AutomationRules::ActionService`): `mute_conversation`, `snooze_conversation`, `resolve_conversation`, `open_conversation`, `pending_conversation`, `change_status`, `change_priority`, `add_label`, `remove_label`, `assign_agent`, `assign_team`, `remove_assigned_agent`, `remove_assigned_team`, `send_email_transcript`, `send_attachment`, `send_webhook_event`, `send_message`, `add_private_note`, `send_email_to_team`.

**Trigger events:** `conversation_created`, `conversation_updated`, `conversation_opened`, `conversation_resolved`, `message_created`.

---

## 5. Frontend

**Vue:** rule builder under `dashboard/routes/dashboard/settings/automation/` — condition-row builder (attribute/operator/value), action-row builder, event-type selector.

**States handled:** empty rule list, save validation errors (from `ConditionValidationService`), clone confirmation, active/inactive toggle.

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/automation_rule_spec.rb`, `spec/enterprise/models/automation_rule_spec.rb` | model validations, Enterprise event extensions |
| `spec/listeners/automation_rule_listener_spec.rb`, `_labels_spec.rb`, `_old_spec.rb` | event → rule matching → action execution, label-specific behavior |
| `spec/services/automation_rules/conditions_filter_service_spec.rb` | condition matching logic |
| `spec/services/automation_rules/condition_validation_service_spec.rb` | save-time validation |
| `spec/services/automation_rules/action_service_spec.rb` | each action's execution |
| `spec/controllers/api/v1/accounts/automation_rules_controller_spec.rb` | CRUD + clone endpoint |

**Coverage gaps observed:** none obvious — this feature has unusually complete coverage across listener, services, and controller layers.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, custom in-process event dispatcher (`app/dispatchers/`, not a message queue — synchronous pub/sub within the request/job), ActiveStorage (attachments), Sidekiq (actions like email send run async where applicable)
- No external 3rd-party dependency — this is a fully internal rules engine

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Action raises an error mid-execution | Caught per-action, reported via `ChatwootExceptionTracker`, remaining actions in the rule still run |
| Rule triggered by its own automation-caused event | Skipped via `performed_by_automation?` to prevent loops |
| `message_created` fired by a bot/system message | Skipped via `ignore_message_created_event?` |
| `assign_agent` action targets an agent not in the inbox | Guarded by `agent_belongs_to_inbox?` check before assigning |
| `assign_team` action targets a team outside the account | Guarded by `team_belongs_to_account?` |
| No active rules for an event | Listener short-circuits immediately (`rule_present?`), no unnecessary work per event |

---

## 9. Price / plan gating

**Gating type:** Resource quota. The `automations` boolean is on for every self-serve plan; the cap is numeric.
**`feature_key`(s):** resource `automations`; boolean `automations` (all plans)

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | yes | 3 automations | |
| Standard | yes | 15 automations | |
| Business | yes | 100 automations | |
| Enterprise | yes | negotiated | `EnterpriseContract.negotiated_limit_overrides` can override |

**Credits / usage:** none
**Enforced by:** `Enterprise::Billing::ReconcilePlanFeaturesService` → `account.limits['automations']`
**Source:** `lib/seeders/plan_feature_limit_seeder.rb`

---

## 10. Open gaps / notes

- None significant found — this is one of the better-tested subsystems in the codebase. Worth using as the reference pattern (listener + condition service + action service split) when documenting Macros next, since Macros reuse the same `ActionService` base.
