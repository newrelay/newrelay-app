# FRD: Webhooks & Integrations

**Status:** Shipped
**Module:** OSS core
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** Two related outbound mechanisms — **Webhooks** (account/inbox-configured URLs that receive a JSON payload on domain events like `conversation_created`, `message_created`) and **Integration Hooks** (per-account connections to a registry of external apps — OpenAI, Dialogflow, Slack, Dashboard Apps, etc. — each with its own settings schema).

**Who uses it:** Admins (configure webhook URLs / connect integration apps), external systems (receive webhook payloads, or provide the connected service).

---

## 2. How it works

### Webhooks
1. A `Webhook` is a URL (validated as a real http/https URL, unique per account) with a `subscriptions` array (which event types to receive — defaults to all eight standard events: `conversation_status_changed`, `conversation_updated`, `conversation_created`, `contact_created`, `contact_updated`, `message_created`, `message_updated`, `webwidget_triggered`) and `webhook_type` (`account_type` — fires for all inboxes, or `inbox_type` — scoped to one inbox).
2. `WebhookListener` subscribes to the same domain events as `ReportingEventListener`/`AutomationRuleListener` (see [06-automation-rules.md](06-automation-rules.md), [13-reports.md](13-reports.md)) — this event-dispatcher pattern is used consistently across the codebase for "something happened, fan out to N independent concerns" rather than each concern polling or being called directly.
3. Each handler builds a payload from the record's own `webhook_data`/`webhook_sendable?` methods (defined on `Conversation`/`Message` themselves — the model owns its own webhook serialization shape) merged with `event: <event_name>` and, for update events, `changed_attributes`.
4. `deliver_webhook_payloads(payload, inbox)` fans the payload out to every matching `Webhook` for that inbox/account via `WebhookJob` (Sidekiq) — actual HTTP delivery is async, not inline with the triggering request.
5. A separate `InstallationWebhookListener` handles instance-level (not per-account) webhook delivery — e.g. for the platform operator's own monitoring, distinct from customer-configured webhooks.
6. `AgentBots::WebhookJob` is a distinct delivery path specifically for agent-bot-owned inboxes (see [04-inboxes.md](04-inboxes.md) `agent_bot_inbox`) — bots receive the same kind of event payload to decide how to respond.

### Integration Hooks
7. `config/integration/apps.yml` is the registry of available integrations — a YAML file, not a DB table, so adding a new integration type is a config change plus (usually) a new settings schema, not a migration. Each entry declares `id`, `logo`, `i18n_key`, optional `action` (external redirect path, e.g. OAuth), `hook_type` (`account`/`inbox`), `allow_multiple_hooks`, and `settings_json_schema` (backend validation, JSON Schema format) / `settings_form_schema` (frontend form rendering, VueFormulate schema) — **the settings form is data-driven from this one YAML entry**, not a hand-built Vue form per integration.
8. `Integrations::Hook` is the actual per-account connection row: `app_id` (references the YAML registry, not a DB foreign key), `hook_type`, `reference_id`/`access_token` (external account linkage), `settings` (jsonb, validated against that app's `settings_json_schema`), `status` (`disabled`/`enabled`).
9. Uniqueness is conditional: one hook per `(account_id, app_id)` **unless** that app's YAML config sets `allow_multiple_hooks` (e.g. `webhooks`/`dashboard_apps` allow multiple; `openai` explicitly does not).
10. `POST .../hooks/:id/process_event` is a generic inbound-event endpoint for integrations that need to receive callbacks (as opposed to webhooks, which only send).

---

## 3. Data model

**Table:** `webhooks`
```
webhooks
  - account_id, inbox_id (optional): integer
  - url: text (unique per account_id, http/https validated)
  - webhook_type: integer   # enum account_type:0 inbox_type:1
  - subscriptions: jsonb, default [8 standard event names]
  - name, secret: string
```

**Table:** `integrations_hooks`
```
integrations_hooks
  - account_id, inbox_id (optional): integer
  - app_id: string          # references config/integration/apps.yml, not a DB FK
  - hook_type: integer      # enum account:0 inbox:1
  - status: integer         # enum disabled:0 enabled:1
  - reference_id, access_token: string
  - settings: jsonb, default {}   # validated against the app's settings_json_schema
```

**Registry (not a table):** `config/integration/apps.yml` — one entry per integration (webhooks, dashboard_apps, openai, and others — Slack/Dialogflow/etc. per the file's fuller contents, not individually enumerated here).

---

## 4. Backend / API

**Routes:**
| Method | Path | Controller#action |
|---|---|---|
| GET/POST | `/webhooks` | `webhooks#index/create` |
| PATCH/DELETE | `/webhooks/:id` | `webhooks#update/destroy` |
| GET | `/integrations/apps` | `integrations/apps#index/show` |
| GET/POST/PATCH/DELETE | `/integrations/hooks/:id` | `integrations/hooks#*` |
| POST | `/integrations/hooks/:id/process_event` | inbound callback endpoint |
| POST | `/integrations/webhooks` (platform-level, no account scope) | `integrations/webhooks#create` |

**Engine:** `app/listeners/{webhook_listener, installation_webhook_listener}.rb`, `app/jobs/webhook_job.rb`, `app/jobs/webhooks/` , `app/jobs/agent_bots/webhook_job.rb`, `app/models/{webhook, integrations/hook, integrations/app}.rb`.

---

## 5. Frontend

**Vue:** webhook management under `dashboard/routes/dashboard/settings/integrations/webhook/` (URL + subscription checkboxes); integration app gallery + per-app settings form under `.../integrations/` — the settings form is rendered dynamically from each app's `settings_form_schema` (VueFormulate) rather than being a bespoke component per integration.

---

## 6. Test coverage (as it exists today)

~22 spec files. Representative: `spec/models/{webhook, integrations/hook}_spec.rb`, `spec/listeners/{webhook_listener, installation_webhook_listener}_spec.rb`, `spec/jobs/webhook_job_spec.rb`, `spec/jobs/agent_bots/webhook_job_spec.rb`, `spec/controllers/api/v1/accounts/{webhooks, integrations/hooks, integrations/apps}_controller_spec.rb`.

**Coverage gaps observed:** none significant — reasonable coverage across model, listener, job, and controller layers for both mechanisms.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, Sidekiq (`WebhookJob` — async HTTP delivery), YAML-based integration registry (no database migration needed to add a new integration's metadata), JSON Schema (settings validation)
- Frontend: VueFormulate-driven dynamic settings forms

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Same URL registered twice for one account | Blocked by unique index `(account_id, url)` |
| Integration app installed twice when not allowed | Blocked by conditional uniqueness validation (`unless allow_multiple_hooks`) |
| Webhook delivery target is down/times out | Handled inside `WebhookJob` (Sidekiq's own retry semantics apply) — payload isn't lost on first failure, though exact retry/backoff count wasn't verified here |
| Message not eligible for webhook delivery (e.g. private note) | `message.webhook_sendable?` gate prevents dispatch before it ever reaches the job |
| Integration's settings don't match its declared schema | Rejected via `settings_json_schema` validation before the hook is saved |

---

## 9. Open gaps / notes

- `WebhookJob`'s retry/backoff behavior on delivery failure wasn't directly inspected — worth confirming if webhook reliability becomes a support issue.
- The full `config/integration/apps.yml` list (which specific third-party integrations exist beyond `webhooks`/`dashboard_apps`/`openai`) wasn't fully enumerated in this pass.

---

## Phase 5 complete — FRD program summary

This closes out the planned 5-phase program from [README.md](README.md): 22 FRDs covering every major Chatwoot/newrelay feature area. Recurring cross-cutting findings worth a follow-up pass:
- **Billing** ([20-billing-subscription.md](20-billing-subscription.md)) has the thinnest test coverage relative to its risk (money, webhooks, commission math) — highest-priority gap found.
- **Reputation Management** ([15-reputation-management.md](15-reputation-management.md)) — the gated feedback funnel and OAuth/token handling have no direct specs found.
- **Macros** ([07-macros.md](07-macros.md)) — unclear whether a failing action mid-batch aborts the rest of a bulk run.
- Everything else reviewed (Automation Rules, Campaigns, CSAT, Reports, Help Center, Captain AI, SLA/Custom Roles, Comment-to-DM's core pipeline, Webhooks/Integrations) is solidly built and tested.
