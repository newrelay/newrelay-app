# FRD: Conversations

**Status:** Shipped
**Module:** OSS core
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** A conversation is a thread of messages between a contact and an inbox — the central unit agents work from (assign, reply, resolve, tag, prioritize).

**Who uses it:** Agents, team admins, account admins (via dashboard); contacts (via widget/channel); agent bots and automations (programmatically).

---

## 2. How it works

1. A conversation is created when a contact first messages an inbox (via `ConversationBuilder`), or via API/dashboard "new conversation" (`components-next/NewConversation`).
2. It gets a per-account sequential `display_id`, starts `status: open`, and is optionally auto-assigned per the inbox's assignment policy (`AssignmentService`).
3. Incoming/outgoing messages append to it; `last_activity_at`, `contact_last_seen_at`, `agent_last_seen_at`, `waiting_since` and `first_reply_created_at` track SLA-relevant timestamps.
4. Agents act on it: assign/unassign, add labels, set priority (`low/medium/high/urgent`), snooze, resolve, mute (stop future auto-reopen), add private notes/mentions.
5. Status lifecycle: `open → resolved` (agent closes) / `open → pending` (bot flow) / `open → snoozed` (deferred, `snoozed_until`) → auto `reopen_snoozed_conversations_job` flips back to `open` when due.
6. Auto-resolution: `Account::ConversationsResolutionSchedulerJob` resolves conversations idle past the account's configured auto-resolve duration.
7. Typing status, unread counts, and presence are pushed over ActionCable (real-time) rather than polled.

---

## 3. Data model

**Table:** `conversations`
```
conversations
  - account_id: integer, not null
  - inbox_id: integer, not null
  - contact_id: bigint, not null
  - contact_inbox_id: bigint, not null
  - assignee_id: integer (User, nullable)
  - assignee_agent_bot_id: bigint (nullable)
  - team_id: bigint (nullable)
  - campcampaign_id: bigint (nullable)
  - status: integer, default 0   # enum open:0 resolved:1 pending:2 snoozed:3
  - priority: integer            # enum low:0 medium:1 high:2 urgent:3
  - display_id: integer, not null (per-account sequential)
  - uuid: uuid, unique, default gen_random_uuid()
  - identifier: string
  - additional_attributes: jsonb, default {}
  - custom_attributes: jsonb, default {}
  - cached_label_list: text
  - sla_policy_id: bigint (Enterprise)
  - snoozed_until, waiting_since, last_activity_at,
    contact_last_seen_at, agent_last_seen_at,
    assignee_last_seen_at, first_reply_created_at: datetime
```

**Relationships:** `belongs_to :account, :inbox, :contact, :contact_inbox`; optional `:assignee (User)`, `:assignee_agent_bot`, `:team`, `:campaign`; `has_many :messages, :mentions, :conversation_participants, :notifications, :reporting_events`; `has_one :csat_survey_response`; `has_many :attachments, through: :messages`.

**Key indexes:** unique `(account_id, display_id)`, unique `uuid`, composite `(account_id, inbox_id, status, assignee_id)` for the agent inbox-list query, plus separate indexes on `status`, `priority`, `waiting_since`, `first_reply_created_at`.

---

## 4. Backend / API

**Routes** (`config/routes.rb`, under `/api/v1/accounts/:account_id/conversations`):
| Method | Path | Controller#action | Auth/permission |
|---|---|---|---|
| GET | `/conversations` | `conversations#index` | account user |
| GET | `/conversations/meta` | `conversations#meta` | account user |
| GET | `/conversations/search` | `conversations#search` | account user |
| POST | `/conversations/filter` | `conversations#filter` | account user |
| GET | `/conversations/:id` | `conversations#show` | account user + inbox access |
| POST | `/conversations` | `conversations#create` | account user |
| PATCH | `/conversations/:id` | `conversations#update` | account user |
| DELETE | `/conversations/:id` | `conversations#destroy` | admin |
| POST | `/conversations/:id/toggle_status` | `conversations#toggle_status` | account user |
| POST | `/conversations/:id/toggle_priority` | `conversations#toggle_priority` | account user |
| POST | `/conversations/:id/mute` \| `/unmute` | `conversations#mute/unmute` | account user |
| POST | `/conversations/:id/transcript` | `conversations#transcript` | account user |
| POST | `/conversations/:id/custom_attributes` | `conversations#custom_attributes` | account user |
| GET | `/conversations/:id/attachments` | `conversations#attachments` | account user |
| nested | `/messages`, `/assignments`, `/labels`, `/participants`, `/direct_uploads`, `/draft_messages` | resp. controllers under `conversations/` | account user |

**Services/models:** `app/models/conversation.rb`, `app/builders/conversation_builder.rb` (creation), `app/services/conversations/assignment_service.rb`, `filter_service.rb`, `permission_filter_service.rb`, `message_window_service.rb`, `typing_status_manager.rb`, `app/finders/conversation_finder.rb`.

**Background jobs:** `Conversations::ActivityMessageJob`, `Conversations::ReopenSnoozedConversationsJob` (cron), `Conversations::ResolutionJob`, `Conversations::UpdateMessageStatusJob`, `Conversations::UserMentionJob`, `Account::ConversationsResolutionSchedulerJob`, `ConversationReplyEmailJob`.

**Real-time:** broadcasts over ActionCable (`ConversationsChannel` equivalents) for status/typing/unread updates — not polling.

---

## 5. Frontend

**Vue:** `app/javascript/dashboard/modules/conversations/` (main inbox/conversation view), `components-next/NewConversation/` (compose new), `components-next/ConversationWorkflow/`, `components-next/Conversation/` (message bubbles, next-gen).

**Store:** `app/javascript/dashboard/store/modules/conversations/` (`actions.js`, `getters.js`, `helpers.js`), plus satellite modules `conversationPage.js`, `conversationLabels.js`, `conversationMetadata.js`, `conversationSearch.js`, `conversationStats.js`, `conversationTypingStatus.js`, `conversationUnreadCounts.js`, `conversationWatchers.js`, `contactConversations.js`.

**States handled:** empty inbox, loading list/skeleton, per-conversation loading, error toast on action failure, permission-gated actions (assign/delete require role).

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/conversation_spec.rb` | validations, enums, scopes, associations |
| `spec/policies/conversation_policy_spec.rb` | authorization rules |
| `spec/finders/conversation_finder_spec.rb` | filter/search query building |
| `spec/builders/conversation_builder_spec.rb` | creation flow, contact/inbox resolution |
| `spec/jobs/conversations/reopen_snoozed_conversations_job_spec.rb` | snooze auto-reopen |
| `spec/jobs/account/conversations_resolution_scheduler_job_spec.rb` | auto-resolve scheduling |
| `spec/jobs/conversation_reply_email_job_spec.rb` | reply-by-email job |
| `spec/mailers/conversation_reply_mailer_spec.rb`, `agent_notifications/conversation_notifications_mailer_spec.rb` | outbound mail |
| `spec/enterprise/models/conversation_spec.rb`, `spec/enterprise/policies/conversation_policy_spec.rb` | Enterprise overrides (SLA-related) |
| `app/javascript/dashboard/store/modules/conversations/specs/*` | frontend store actions/getters |

**Coverage gaps observed:** no dedicated request spec found directly under `spec/requests` for the conversations controller actions (`toggle_status`, `mute`, `custom_attributes`) — worth confirming via `spec/controllers` before assuming untested.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, PostgreSQL (`jsonb` for attributes), Sidekiq (all `Conversations::*Job`), ActionCable (real-time push)
- Frontend: Vue 3 + Vuex, `vue-router`
- No external 3rd-party API for this feature itself (channels handle that separately)

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Snoozed conversation past `snoozed_until` | Cron job (`ReopenSnoozedConversationsJob`) flips back to `open` |
| Conversation idle past auto-resolve window | `ConversationsResolutionSchedulerJob` resolves it |
| Bot-owned conversation reopened by contact reply | `pending_to_open_by_bot?` in controller decides re-open vs stay pending |
| Duplicate `display_id` | Prevented by unique index `(account_id, display_id)` at DB level |
| Assignee removed from inbox/account | `assignee_id` becomes orphaned reference — no cascading unassign observed in model callbacks (worth verifying) |

---

## 9. Price / plan gating

**Gating type:** Mixed — core conversation UI is ungated; count and retention are resource quotas; two related flags are Business-only.
**`feature_key`(s):** resource `conversations`, `data_retention_months`; boolean `auto_resolve_conversations` (all plans); `conversation_required_attributes`, `advanced_assignment` (premium)

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | yes | 200 conversations; 1 month retention | |
| Standard | yes | 2,000 conversations; 6 months retention | |
| Business | yes | 20,000 conversations; 12 months retention | `conversation_required_attributes` and `advanced_assignment` enabled |
| Enterprise | yes | negotiated | `EnterpriseContract.negotiated_limit_overrides` can override quotas |

**Credits / usage:** none
**Enforced by:** `Enterprise::Billing::ReconcilePlanFeaturesService` → `account.limits['conversations']` / `account.limits['data_retention_months']` (purged by `Internal::PurgeExpiredConversationsJob`); premium flags via `account.feature_enabled?`
**Source:** `lib/seeders/plan_feature_limit_seeder.rb` (Hobby / Standard / Business). Enterprise is negotiated via `EnterpriseContract`.

---

## 10. Open gaps / notes

- No explicit request-spec coverage found for several controller actions (`mute`, `custom_attributes`, `toggle_priority`) — confirm before treating as tested.
- Assignee-removal cascade behavior not verified against code; flagged for follow-up, not a confirmed bug.
