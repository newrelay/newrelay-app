# FRD: Campaigns

**Status:** Shipped
**Module:** OSS core
**Last updated:** 2026-09-07

> Note: this is the OSS "Campaigns" feature (proactive outbound messages via web widget/WhatsApp/SMS). Not to be confused with **Comment-to-DM Automation Campaigns** (a separate, newrelay-custom model — see Phase 4).

---

## 1. What it is

**One-liner:** Proactive outbound messaging — either a **one-off** broadcast to a defined audience (SMS/WhatsApp) or an **ongoing** rule-triggered widget message (e.g. "show this message if a visitor is on the pricing page for 10s").

**Who uses it:** Admins/marketers (author campaigns), the system (evaluates trigger rules for ongoing campaigns, or a scheduled job for one-off sends).

---

## 2. How it works

1. `campaign_type` enum splits behavior in two:
   - **`ongoing`**: lives on a Web Widget inbox, evaluated client-side/server-side against `trigger_rules` (jsonb — e.g. URL match, time-on-page) while a visitor is active; `trigger_only_during_business_hours` gates it to the inbox's working hours.
   - **`one_off`**: targets a fixed `audience` (jsonb — contact/label selection) on an SMS/WhatsApp inbox, optionally `scheduled_at` for future send.
2. `campaign_status` enum (`active / completed / processing`) tracks lifecycle — one-off campaigns move to `processing` while sending, `completed` once done.
3. For one-off sends, `Campaigns::TriggerOneoffCampaignJob` is the entry point (scheduled or manually triggered), which fans out to channel-specific senders: `Sms::OneoffSmsCampaignService`, `Twilio::OneoffSmsCampaignService`, `Whatsapp::OneoffCampaignService` — one service per provider, since each has different API shapes/rate limits.
4. Message personalization uses **Liquid templating** (`Liquid::CampaignTemplateService`) — `{{contact.name}}`, `{{agent.name}}`, `{{inbox.name}}`, `{{account.name}}` etc. resolve via drop classes before send; inline code spans (`` `...` ``) are protected from Liquid parsing via a raw-tag wrap.
5. For ongoing (widget) campaigns, a visitor-side trigger event (`campaign_triggered`) fires into `CampaignListener`, which calls `Campaigns::CampaignConversationBuilder` to create (or reuse) a conversation seeded with the campaign message, tagging it with campaign-sourced `additional_attributes`/`custom_attributes`.
6. A campaign's conversations are tracked via `has_many :conversations, dependent: :nullify` — deleting a campaign detaches (not deletes) its conversations.
7. `campaign_analytics` (a separate resource, `GET /campaign_analytics`) reports aggregate performance (sent/opened/replied, etc. — exact metrics not verified here).

---

## 3. Data model

**Table:** `campaigns`
```
campaigns
  - account_id, inbox_id: bigint, not null
  - display_id: integer, not null (per-account sequential)
  - title: string, not null
  - description: text
  - message: text, not null
  - sender_id: integer (User, optional)
  - enabled: boolean, default true
  - campaign_type: integer, default 0     # enum ongoing:0 one_off:1
  - campaign_status: integer, default 0   # enum active:0 completed:1 processing:2
  - trigger_rules: jsonb, default {}          # ongoing: URL/time/page-count conditions
  - trigger_only_during_business_hours: boolean, default false
  - audience: jsonb, default []               # one_off: target contacts/labels
  - scheduled_at: datetime
  - template_params: jsonb                    # WhatsApp template send params
```

**Relationships:** `belongs_to :account, :inbox`; `belongs_to :sender (User), optional: true`; `has_many :conversations, dependent: :nullify, autosave: true`.

---

## 4. Backend / API

**Routes:**
| Method | Path | Controller#action |
|---|---|---|
| GET/POST | `/campaigns` | `campaigns#index/create` |
| GET/PATCH/DELETE | `/campaigns/:id` | `campaigns#show/update/destroy` |
| GET | `/campaign_analytics` | `campaign_analytics#show` |
| GET | `/widget/campaigns` (public) | widget-facing campaign trigger check |

**Engine:** `app/listeners/campaign_listener.rb`, `app/builders/campaigns/campaign_conversation_builder.rb`, `app/jobs/campaigns/trigger_oneoff_campaign_job.rb`, `app/services/sms/oneoff_sms_campaign_service.rb`, `app/services/twilio/oneoff_sms_campaign_service.rb`, `app/services/whatsapp/oneoff_campaign_service.rb`, `app/services/liquid/campaign_template_service.rb`.

---

## 5. Frontend

**Vue:** campaign builder under `dashboard/routes/dashboard/campaigns/` — separate flows for ongoing (widget trigger rule builder: URL match, time delay) vs. one-off (audience picker, schedule picker, channel selection).

**Widget SDK:** `app/javascript/sdk/` evaluates/receives ongoing campaign triggers client-side.

**States handled:** schedule-in-future vs. send-now, audience size preview, processing/completed status badges.

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/campaign_spec.rb` | validations, enums |
| `spec/controllers/api/v1/accounts/campaigns_controller_spec.rb`, `spec/enterprise/controllers/.../campaigns_controller_spec.rb` | CRUD, Enterprise extensions |
| `spec/controllers/api/v1/accounts/campaign_analytics_controller_spec.rb` | analytics endpoint |
| `spec/controllers/api/v1/widget/campaigns_controller_spec.rb` | widget-facing trigger check |
| `spec/listeners/campaign_listener_spec.rb` | trigger → conversation creation |
| `spec/builders/campaigns/campaign_conversation_builder_spec.rb` | conversation seeding |
| `spec/jobs/campaigns/trigger_oneoff_campaign_job_spec.rb` | one-off send job |
| `spec/services/sms/oneoff_sms_campaign_service_spec.rb`, `twilio/oneoff_sms_campaign_service_spec.rb`, `whatsapp/oneoff_campaign_service_spec.rb` | per-channel send logic |
| `spec/services/liquid/campaign_template_service_spec.rb` | Liquid personalization |

**Coverage gaps observed:** none significant — this feature has thorough per-layer coverage, similar to Automation Rules.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, Sidekiq (`TriggerOneoffCampaignJob`), **Liquid templating gem** (personalization), Twilio SDK (SMS), WhatsApp Cloud API/360dialog (via inbox's channel config)
- Frontend: Vue 3, widget SDK trigger evaluation

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| One-off campaign scheduled in the past / send fails mid-batch | Handled inside `TriggerOneoffCampaignJob`/per-channel service — exact partial-failure behavior not verified here |
| Ongoing campaign trigger with blank `campaign_id` | `CampaignListener#campaign_triggered` returns early (`return if campaign_display_id.blank?`) |
| Liquid template contains inline code (backticks) | Escaped via raw-tag wrapping before Liquid processing, so `{{...}}` inside code spans isn't rendered as a variable |
| Campaign deleted with active conversations | Conversations are nullified (campaign_id set to null), not deleted |

---

## 9. Price / plan gating

**Gating type:** Ungated boolean. No campaign-count quota in the matrix.
**`feature_key`(s):** `campaigns`, `whatsapp_campaign`

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | yes | — | |
| Standard | yes | — | |
| Business | yes | — | |
| Enterprise | yes | negotiated | |

**Credits / usage:** none in `PlanFeatureLimit` (WhatsApp template/carrier fees are outside this matrix)
**Enforced by:** `account.feature_enabled?('campaigns')` after `ReconcilePlanFeaturesService`
**Source:** `lib/seeders/plan_feature_limit_seeder.rb`

---

## 10. Open gaps / notes

- Exact `campaign_analytics` metrics (what's actually measured — sent count, reply rate, etc.) not verified against the controller/serializer in this pass.
- Partial-failure behavior of one-off bulk sends (does one failed recipient abort the batch?) not directly confirmed — worth checking if this becomes operationally important (e.g. large SMS blasts).
