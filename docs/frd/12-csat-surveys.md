# FRD: CSAT Surveys

**Status:** Shipped
**Module:** OSS core
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** A 1-5 satisfaction rating sent to the contact automatically when their conversation is resolved (if the inbox has it enabled), captured as a special `input_csat` message and stored as a `CsatSurveyResponse` for reporting.

**Who uses it:** Contacts (rate their support experience), admins (view CSAT reports, review notes on individual responses), AI (Captain analyzes CSAT trends).

---

## 2. How it works

1. `CsatSurveyListener#conversation_status_changed` fires on every conversation status change; if the new status is `resolved`, it calls `CsatSurveyService#perform`.
2. `CsatSurveyService.should_send_csat_survey?` gates the send on four conditions: conversation is resolved and not a tweet, the inbox has `csat_survey_enabled`, no CSAT message already sent for this conversation, and the account's survey rules allow it.
3. Delivery method depends on channel state, in priority order:
   - WhatsApp channel with an approved CSAT template → send via WhatsApp template message
   - Twilio WhatsApp with an approved template → send via Twilio template
   - Otherwise, if still within the messaging window (`conversation.can_reply?`) → send an in-conversation `input_csat` message via `MessageTemplates::Template::CsatSurvey`
   - Otherwise (can't message the contact at all) → log an internal "CSAT not sent" activity message instead of failing silently
4. The contact responds via a public, unauthenticated endpoint (`GET/PATCH /survey/responses` or `public/api/v1/csat_survey`) — `Public::Api::V1::CsatSurveyController#update` writes the rating + optional `feedback_message`, gated by `check_csat_locked` (can't re-answer once submitted).
5. Separately, `CsatSurveyListener#message_updated` catches the case where the `input_csat` message itself gets updated (contact submits via the in-chat widget) and runs `CsatSurveys::ResponseBuilder` to materialize the `CsatSurveyResponse` record from the message's `content_attributes`.
6. Admins can add internal `csat_review_notes` to a response after the fact (tracked with `review_notes_updated_at`/`review_notes_updated_by_id`) — a QA/coaching layer separate from the rating itself.
7. `Captain::CsatUtilityAnalysisService` / `CsatUtilityAnalysisService` (AI) analyzes CSAT data for insights (exact output not verified here).

---

## 3. Data model

**Table:** `csat_survey_responses`
```
csat_survey_responses
  - account_id, conversation_id, message_id, contact_id: bigint, not null
  - rating: integer, not null (1-5)
  - feedback_message: text
  - assigned_agent_id: bigint (User, optional — agent on the conversation at resolve time)
  - csat_review_notes: text
  - review_notes_updated_at: datetime
  - review_notes_updated_by_id: bigint (User)
```
Unique index on `message_id` — one response per CSAT message (can't double-submit against the same prompt).

**Related columns:** `inboxes.csat_survey_enabled` (boolean), `inboxes.csat_config` (jsonb — template/question config), `messages.content_type = input_csat` (the survey prompt itself lives as a message).

---

## 4. Backend / API

**Routes:**
| Method | Path | Controller#action |
|---|---|---|
| GET | `/csat_survey_responses` | `csat_survey_responses#index` (admin dashboard list) |
| GET | `/csat_survey_responses/metrics` | `csat_survey_responses#metrics` |
| GET | `/csat_survey_responses/download` | `csat_survey_responses#download` (CSV export) |
| GET/POST | `/inboxes/:id/csat_template` | `inbox_csat_templates#show/create` (WhatsApp template config), `+ /analyze` |
| GET/PATCH | `/survey/responses/:id` (public) | `survey/responses_controller` |
| GET/PATCH | `/csat_survey` (public) | `public/api/v1/csat_survey_controller` |

**Engine:** `app/listeners/csat_survey_listener.rb`, `app/services/csat_survey_service.rb`, `app/builders/csat_surveys/` (`ResponseBuilder`), `app/services/message_templates/template/csat_survey.rb`, `app/services/whatsapp/csat_template_service.rb`, `lib/captain/csat_utility_analysis_service.rb`.

---

## 5. Frontend

**Vue:** CSAT report/dashboard under `dashboard/routes/dashboard/settings/reports/` (or a dedicated CSAT report view); per-response review-notes editor; inbox settings CSAT config form (`inbox_csat_templates`).

**Contact-facing:** the survey prompt renders as a special message bubble (`content_type: input_csat`) inside the widget/channel, or as a WhatsApp template message outside the widget.

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/csat_survey_response_spec.rb` | validations |
| `spec/policies/csat_survey_response_policy_spec.rb`, `spec/enterprise/policies/...` | authorization |
| `spec/listeners/csat_survey_listener_spec.rb` | trigger-on-resolve, message-updated response capture |
| `spec/services/csat_survey_service_spec.rb` | send-decision logic, channel priority |
| `spec/services/whatsapp/csat_template_service_spec.rb` | WhatsApp template send |
| `spec/services/message_templates/template/csat_survey_spec.rb` | in-chat template |
| `spec/builders/csat_surveys/` | response builder |
| `spec/controllers/public/api/v1/csat_survey_controller_spec.rb` | public submit endpoint |
| `spec/controllers/api/v1/accounts/csat_survey_responses_controller_spec.rb`, `spec/enterprise/controllers/.../csat_survey_responses_controller_spec.rb` | dashboard list/metrics/download |
| `spec/controllers/api/v1/accounts/inbox_csat_templates_controller_spec.rb` | template config |
| `spec/lib/captain/csat_utility_analysis_service_spec.rb`, `spec/services/csat_template_utility_analysis_service_spec.rb` | AI analysis |

**Coverage gaps observed:** none significant — very thorough coverage across the send-decision tree, response capture, and reporting.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, Sidekiq (async send via listener → job path), WhatsApp Cloud API/Twilio (template-based CSAT delivery), LLM (Captain analysis service — see [33-captain-ai.md], not yet written)
- No external survey tool — fully in-house

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Conversation resolved but messaging window closed and no approved template | `create_csat_not_sent_activity_message` — logs internally instead of failing |
| Contact tries to resubmit an already-answered survey | Blocked by `check_csat_locked` in the public controller |
| Conversation resolved twice (re-resolved) | `csat_already_sent?` check prevents duplicate survey sends |
| WhatsApp template not yet approved by Meta | Falls through to next channel-appropriate method rather than erroring |

---

## 9. Price / plan gating

**Gating type:** Mixed — CSAT surveys have no dedicated `feature_key` (ungated in practice); review notes are Business-only.
**`feature_key`(s):** `csat_review_notes` (premium). No `csat` key in `config/features.yml`.

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | surveys yes; review notes no | — | |
| Standard | surveys yes; review notes no | — | |
| Business | yes | — | `csat_review_notes` on |
| Enterprise | yes | negotiated | |

**Credits / usage:** none
**Enforced by:** `account.feature_enabled?('csat_review_notes')` after `ReconcilePlanFeaturesService`
**Source:** `lib/seeders/plan_feature_limit_seeder.rb` (`PREMIUM_ONLY_FEATURES` includes `csat_review_notes`)

---

## 10. Open gaps / notes

- None significant found — this is another well-covered, well-guarded subsystem (send-priority fallback chain is a nice pattern worth reusing elsewhere).
