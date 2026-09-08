# FRD: Messages

**Status:** Shipped
**Module:** OSS core
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** A single unit of communication inside a conversation — text, structured bot content, attachment, or system activity note.

**Who uses it:** Contacts (incoming), agents/bots (outgoing), the system itself (activity messages like "conversation assigned to X").

---

## 2. How it works

1. Every message belongs to exactly one `conversation` (and denormalized `account`/`inbox` for query speed).
2. `message_type` distinguishes direction/kind: `incoming` (from contact), `outgoing` (from agent/bot), `activity` (system log entry, e.g. status change), `template` (WhatsApp template send).
3. `content_type` distinguishes payload shape: plain `text`, bot-only input widgets (`input_text`, `input_select`, `input_csat`, `form`, `cards`), `article` (help-center link), `incoming_email`, `integrations`, `sticker`, `voice_call`.
4. `content_attributes` (JSON store) carries type-specific extras (`submitted_email`, `items`, `translations`, `in_reply_to`, `deleted`, `data` for voice calls) without schema changes.
5. Outbound delivery status is tracked via `status` enum (`sent → delivered → read`, or `failed`), updated by channel-specific delivery webhooks (e.g. WhatsApp/Twilio callbacks) via `Messages::StatusUpdateService`.
6. Inbound email arrives through `app/mailboxes/*` (ActionMailbox) which creates the message; inbound channel webhooks (WhatsApp, FB, etc.) create messages via their respective `Channel::*` inbox processors.
7. `private: true` marks internal notes (not sent to contact) — same table, filtered in UI/API.
8. On-demand translation (`POST .../messages/:id/translate`) and resend of failed sends (`POST .../messages/:id/retry`) are explicit controller actions, not automatic.
9. `Messages::MentionService` scans outgoing/private message content for `@agent` mentions and creates `Mention` records + notifications.

---

## 3. Data model

**Table:** `messages`
```
messages
  - account_id, inbox_id, conversation_id: integer/bigint, not null
  - message_type: integer, not null   # enum incoming:0 outgoing:1 activity:2 template:3
  - content_type: integer, default 0  # enum text/input_*/cards/form/article/incoming_email/input_csat/integrations/sticker/voice_call
  - status: integer, default 0        # enum sent:0 delivered:1 read:2 failed:3
  - content: text (max 150,000 chars)
  - processed_message_content: text (max 150,000 chars)
  - private: boolean, default false
  - source_id: text                   # external message id (for dedupe/status callbacks)
  - sender_type/sender_id: polymorphic (User, Contact, AgentBot)
  - content_attributes: json, default {}
  - external_source_ids: jsonb, default {}   # e.g. slack ts
  - additional_attributes: jsonb, default {}
  - sentiment: jsonb, default {}
```

**Relationships:** `belongs_to :account, :inbox, :conversation`; `belongs_to :sender, polymorphic: true, optional: true`; `has_many :attachments`; `has_one :csat_survey_response`; `has_many :notifications`.

**Notable indexes:** GIN trigram index on `content` (full-text-ish search), GIN index on `additional_attributes->campaign_id`, composite `(conversation_id, account_id, message_type, created_at)` for the conversation timeline query. `default_scope` orders by `created_at asc`.

---

## 4. Backend / API

**Routes** (nested under a conversation, `config/routes.rb`):
| Method | Path | Controller#action |
|---|---|---|
| GET | `.../messages` | `conversations/messages#index` |
| POST | `.../messages` | `conversations/messages#create` |
| PATCH | `.../messages/:id` | `conversations/messages#update` (API-channel only, `ensure_api_inbox`) |
| DELETE | `.../messages/:id` | `conversations/messages#destroy` |
| POST | `.../messages/:id/retry` | `conversations/messages#retry` |
| POST | `.../messages/:id/translate` | `conversations/messages#translate` |

**Services:** `app/services/messages/in_reply_to_message_builder.rb`, `mention_service.rb`, `new_message_notification_service.rb`, `send_email_notification_service.rb`, `status_update_service.rb`, `markdown_renderer_service.rb` (+`markdown_renderers/`), `webhook_content_normalizer.rb`.

**Inbound email:** `app/mailboxes/` (ActionMailbox routing) — `default_mailbox.rb`, `reply_mailbox.rb`, `imap/`.

**Jobs:** `UpdateSlackMessageJob` (syncs edits to linked Slack thread).

**Real-time:** message create/update broadcasts over ActionCable to the conversation room.

---

## 5. Frontend

**Vue:** message list/composer inside `components-next/Conversation/` and `components-next/message/bubbles/` (per-content-type bubble rendering — text, article, form, voice_call, etc.), legacy `components/widgets/WootWriter/` (editor).

**Store:** actions live under `store/modules/conversations/actions.js` (message CRUD dispatched per-conversation), `conversationTypingStatus.js` for composer state.

**States handled:** sending/optimistic pending state, failed-with-retry, read-receipt ticks, translation loading.

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/message_spec.rb` | validations, enums, scopes, content_attributes store |
| `spec/finders/message_finder_spec.rb` | message list/query building |
| `spec/presenters/message_content_presenter_spec.rb` | per-content-type presentation |
| `spec/helpers/message_format_helper_spec.rb` | formatting helpers |
| `spec/jobs/update_slack_message_job_spec.rb` | Slack sync job |

**Coverage gaps observed:** no dedicated request/controller spec found for `messages#create/update/destroy/retry/translate` under `spec/requests` — confirm before assuming those actions are covered.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, ActionMailbox (inbound email), Sidekiq, PostgreSQL (`jsonb`, `pg_trgm` extension for content search)
- Frontend: Vue 3, ProseMirror-based rich text editor (`prosemirror-*` deps) for the composer
- Real-time: ActionCable

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Outbound send fails at channel/provider | `status: failed`, `content_attributes[:external_error]` set; agent can `retry` |
| Message already translated | `already_translated_content_available?` short-circuits repeat translation calls |
| Editing a message on a non-API channel | Blocked — `ensure_api_inbox` restricts `update` to API-channel inboxes |
| Attachment limit exceeded | `before_add: :validate_attachments_limit` callback rejects the add |
| Duplicate inbound webhook delivery | Dedup relies on `source_id` (indexed) at the channel-processing layer, not enforced by a DB unique constraint on `messages.source_id` itself |

---

## 9. Price / plan gating

**Gating type:** Ungated. Messages have no own `PlanFeatureLimit` row; they inherit conversation count and retention.
**`feature_key`(s):** none for messages themselves. Related: resource `conversations`, `data_retention_months`; boolean `voice_recorder` (all plans)

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | yes | 200 conversations; 1 month retention | |
| Standard | yes | 2,000 conversations; 6 months retention | |
| Business | yes | 20,000 conversations; 12 months retention | |
| Enterprise | yes | negotiated | `EnterpriseContract` can override |

**Credits / usage:** none (Captain compose tasks are billed under [18-captain-ai.md](18-captain-ai.md), not per message)
**Enforced by:** same conversation/retention limits as [01-conversations.md](01-conversations.md)
**Source:** `lib/seeders/plan_feature_limit_seeder.rb`

---

## 10. Open gaps / notes

- No unique DB constraint on `source_id` — duplicate-message dedup for retried webhooks appears to be application-level only; worth verifying against the relevant `Channel::*` inbox processor before relying on it.
- Controller-level test coverage for message actions not confirmed; flagged for follow-up.
