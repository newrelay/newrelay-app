# FRD: Inboxes

**Status:** Shipped
**Module:** OSS core (channel polymorphism), Enterprise (WhatsApp calling, capacity policies)
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** The routing/config layer that owns a channel connection (WhatsApp, email, web widget, etc.) and defines how conversations coming through it behave — auto-assignment, working hours, CSAT, greetings.

**Who uses it:** Admins (create/configure), agents (assigned as inbox members), the assignment/automation engine (reads config at conversation-create time).

---

## 2. How it works

1. An inbox `belongs_to :channel, polymorphic: true` — the actual channel record (`Channel::WebWidget`, `Channel::Email`, `Channel::Whatsapp`, etc.) holds provider-specific config; the inbox holds cross-channel behavior config.
2. On create, `InboxesController#create_channel` builds the right `Channel::*` record based on `channel_type` param, then wraps it in an `Inbox`.
3. Agents/teams are attached via `inbox_members` (join table) — only members (or all agents if unrestricted) see the inbox's conversations, per account role settings.
4. Assignment behavior: `enable_auto_assignment` + `auto_assignment_config` (jsonb) drive whether/how new conversations get an assignee; Enterprise inboxes can additionally link an `AssignmentPolicy` (round-robin or fair-distribution, configurable `fair_distribution_limit`/`window`) via `inbox_assignment_policy`.
5. Working hours: `working_hours_enabled` + `timezone` + `out_of_office_message` gate the "we'll reply during business hours" contact-facing message; actual hour ranges live in `working_hours` table (see WorkingHour FRD, not yet written).
6. CSAT: `csat_survey_enabled` + `csat_config` (jsonb, template/questions) controls whether a satisfaction survey message is sent on resolution.
7. Bot handoff: `has_one :agent_bot_inbox` / `agent_bot` — an inbox can be fully or partially bot-owned; `set_agent_bot`/`agent_bot` endpoints manage this.
8. Webhooks/integration hooks scoped to the inbox (`has_many :webhooks, :hooks`) fire on inbox events (new message, status change) to external URLs/apps.
9. `lock_to_single_conversation` forces one open conversation per contact per inbox (used by channels like WhatsApp where threading matters).

---

## 3. Data model

**Table:** `inboxes`
```
inboxes
  - account_id: integer, not null
  - channel_id, channel_type: polymorphic ref to Channel::*
  - name: string, not null
  - enable_auto_assignment: boolean, default true
  - auto_assignment_config: jsonb, default {}
  - greeting_enabled: boolean, greeting_message: string
  - working_hours_enabled: boolean, timezone: string default "UTC", out_of_office_message: string
  - enable_email_collect: boolean, default true
  - csat_survey_enabled: boolean, csat_config: jsonb (not null, default {})
  - allow_messages_after_resolved: boolean, default true
  - lock_to_single_conversation: boolean, default false
  - portal_id: bigint (nullable, help-center link)
  - sender_name_type: integer  # enum friendly:0 professional:1
  - business_name: string
```

**Relationships:** `belongs_to :account, :portal (optional), :channel (polymorphic)`; `has_many :campaigns, :contact_inboxes, :inbox_members, :conversations, :messages, :webhooks, :hooks`; `has_many :contacts, through: :contact_inboxes`; `has_many :members, through: :inbox_members, source: :user`; `has_one :inbox_assignment_policy → assignment_policy`; `has_one :agent_bot_inbox → agent_bot`.

**Related tables:** `assignment_policies` (`assignment_order` enum, `conversation_priority` enum `earliest_created/longest_waiting`, `fair_distribution_limit`, `fair_distribution_window`, `enabled`), `inbox_assignment_policies` (join), `inbox_members` (join to `users`), `inbox_capacity_limits` (Enterprise, per-agent max open conversations for the inbox).

---

## 4. Backend / API

**Routes** (`config/routes.rb`):
| Method | Path | Controller#action |
|---|---|---|
| GET | `/inboxes` | `inboxes#index` |
| POST | `/inboxes` | `inboxes#create` |
| GET/PATCH/DELETE | `/inboxes/:id` | `inboxes#show/update/destroy` |
| GET | `/inboxes/:id/assignable_agents` | `inboxes#assignable_agents` |
| GET | `/inboxes/:id/campaigns` | `inboxes#campaigns` |
| GET/POST | `/inboxes/:id/agent_bot`, `/set_agent_bot` | `inboxes#agent_bot/set_agent_bot` |
| DELETE | `/inboxes/:id/avatar` | `inboxes#avatar` |
| POST | `/inboxes/:id/sync_templates` | `inboxes#sync_templates` (WhatsApp templates) |
| GET | `/inboxes/:id/health` | `inboxes#health` |
| POST | `/inboxes/:id/register_webhook` \| `/reset_secret` | `inboxes#*` |
| Enterprise | `/inboxes/:id/conference` (create/destroy/token), `/enable_whatsapp_calling`, `/disable_whatsapp_calling` | Enterprise controllers |
| `/inbox_members` | create/show/update/destroy | `inbox_members#*` |

**Models/services:** `app/models/inbox.rb`, `inbox_member.rb`, `inbox_assignment_policy.rb`, `assignment_policy.rb`; enterprise concern `Concerns::AssignmentPolicy` mixed in via `include_mod_with`.

---

## 5. Frontend

**Vue:** inbox settings pages under `dashboard/routes/dashboard/settings/inbox/` (channel-specific config forms per `channel_type`).

**Store:** `store/modules/inboxes.js`, `inboxAssignableAgents.js`, `inboxMembers.js`, `store/modules/inboxes/`.

**States handled:** per-channel setup wizard steps, connection health/error, working-hours toggle, CSAT config form.

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/inbox_spec.rb` | validations, associations |
| `spec/models/inbox_member_spec.rb`, `agent_bot_inbox_spec.rb` | membership/bot linkage |
| `spec/policies/inbox_policy_spec.rb` | authorization |
| `spec/factories/inboxes.rb`, `inbox_assignment_policies.rb`, `inbox_capacity_limits.rb`, `inbox_members.rb` | test data |

**Coverage gaps observed:** no dedicated `AssignmentPolicy` model spec found directly (only factories) — confirm assignment-order/fair-distribution logic is tested elsewhere (e.g. `spec/services/conversations/assignment_service_spec.rb`) before assuming it's untested.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails STI/polymorphic associations (`Channel::*`), Sidekiq (health checks, template sync), PostgreSQL `jsonb` for flexible config
- Frontend: Vue 3 + Vuex, per-channel setup wizards

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Channel reauth needed (e.g. token expired) | `reauthorize_and_update_channel` path in controller handles re-auth flow on update |
| Auto-assignment with no available agents | Falls through to unassigned; behavior governed by `AssignmentService`, not the inbox model itself |
| `lock_to_single_conversation` inbox, contact messages again after resolve | Existing open/resolved conversation reused instead of a new one (channel-processor level) |
| Deleting an inbox with active conversations | `dependent: :destroy_async` cascades conversation/message deletion — no soft-archive path observed |

---

## 9. Open gaps / notes

- No soft-delete/archive for inboxes — deletion is destructive (`destroy_async` cascade). Confirm this matches product expectations before treating as a gap vs. intended.
- Assignment-order and fair-distribution logic tested where, exactly, needs confirming (likely `assignment_service_spec.rb`, not yet cross-checked here).
