# FRD: Channels (overview)

**Status:** Shipped
**Module:** OSS core
**Last updated:** 2026-09-07

> This is an overview covering the channel abstraction and all channel types as one unit (per phased plan in `docs/frd/README.md`). Each channel type below can get its own deeper FRD later if needed (e.g. WhatsApp calling, Email piping).

---

## 1. What it is

**One-liner:** The provider-specific connection (WhatsApp, Email, Web Widget, Facebook, Instagram, Telegram, Line, TikTok, SMS/Twilio, Twitter, API) that an `Inbox` wraps — owns auth/provider config and both inbound (webhook) and outbound (API call) message plumbing.

**Who uses it:** Admins (connect/configure), the message pipeline (send/receive), external providers (webhook callers).

---

## 2. How it works

1. Each channel type is its own ActiveRecord model under `app/models/channel/*.rb`, each with its own table (`channel_whatsapp`, `channel_email`, `channel_facebook_pages`, etc.) — **not** single-table inheritance, just a shared polymorphic `channel` association from `Inbox`.
2. **Outbound:** sending a message calls into the channel-specific API client (e.g. WhatsApp Cloud API / 360dialog via `provider_config`, Twilio SDK for SMS, Facebook Graph API) — these live in `app/services/` (e.g. `Whatsapp::SendOnWhatsappService`-style services, exact names per channel) or directly on the channel model.
3. **Inbound:** each provider posts to a public (unauthenticated but signature/token-verified) webhook endpoint — `app/controllers/webhooks/*` — which resolves the target inbox (by phone number, bot token, page id, etc.), builds/updates the `Contact`/`ContactInbox`, and creates the `Message`.
4. WhatsApp and Instagram additionally require a GET verification handshake (`webhooks/whatsapp#verify`, `webhooks/instagram#verify`) for provider webhook subscription setup.
5. Provider credentials/config live in each channel's `provider_config` (jsonb) — never in the shared `Inbox` table — keeping per-provider secrets isolated.
6. WhatsApp specifically also stores `message_templates` (jsonb, synced via `POST /inboxes/:id/sync_templates`) since WhatsApp requires pre-approved templates for business-initiated messages.
7. The Web Widget channel is different in kind — no external provider; it's Chatwoot's own JS SDK (`app/javascript/sdk/`) talking directly to the account's own API/ActionCable.

---

## 3. Data model

**Per-channel tables** (all polymorphically targeted by `inboxes.channel_id/channel_type`):
```
channel_whatsapp     - account_id, phone_number (unique), provider, provider_config (jsonb), message_templates (jsonb)
channel_email        - account_id, email/imap/smtp config
channel_facebook_pages - account_id, page_id, page_access_token, ...
channel_instagram    - account_id, instagram-specific auth
channel_line         - account_id, line_channel_id, line_channel_secret
channel_telegram     - account_id, bot_token
channel_tiktok       - account_id, tiktok auth
channel_sms          - account_id, phone_number
channel_twilio_sms   - account_id, twilio account_sid/auth_token, phone_number
channel_twitter_profiles - account_id, twitter auth
channel_web_widgets  - account_id, widget config (welcome text, colors, pre-chat form)
channel_api          - account_id, webhook_url (generic inbound/outbound API channel)
```
(Exact columns per table not fully enumerated here — see `db/schema.rb` per table for the authoritative column list.)

---

## 4. Backend / API

**Public inbound webhook routes** (`config/routes.rb`, unauthenticated, provider-verified):
| Method | Path | Controller#action |
|---|---|---|
| GET/POST | `/webhooks/whatsapp/:phone_number` | `webhooks/whatsapp#verify` / `#process_payload` |
| GET/POST | `/webhooks/instagram` | `webhooks/instagram#verify` / `#events` |
| POST | `/webhooks/tiktok` | `webhooks/tiktok#events` |
| POST | `/webhooks/line/:line_channel_id` | `webhooks/line#process_payload` |
| POST | `/webhooks/telegram/:bot_token` | `webhooks/telegram#process_payload` |
| POST | `/webhooks/sms/:phone_number` | `webhooks/sms#process_payload` |
| GET/POST | `/webhooks/twitter` | `api/v1/webhooks#twitter_crc` / `#twitter_events` |
| POST | `/webhooks/shopify` | `webhooks/shopify#events` (commerce integration, not messaging) |
| POST | `/webhooks/stripe`, `/razorpay`, `/firecrawl` | billing/tooling webhooks (unrelated to messaging channels) |

**Authenticated per-account channel management:** `api/v1/accounts/:account_id/channels/twilio_channels_controller.rb` (Twilio-specific setup flow); most other channel creation goes through the generic `inboxes#create` (see [04-inboxes.md](04-inboxes.md)).

**Email piping:** ActionMailbox routes inbound email — see [02-messages.md](02-messages.md) `app/mailboxes/`.

---

## 5. Frontend

**Vue:** channel connection wizards under `dashboard/routes/dashboard/settings/inbox/channels/` (one form per channel type — OAuth connect buttons for FB/IG, phone number + API key forms for WhatsApp/Twilio, bot-token form for Telegram).

**Widget SDK:** `app/javascript/sdk/` (separate build, embeds on customer websites, talks to the Web Widget channel's API).

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/channel/*_spec.rb` (per channel) | model validations |
| `spec/controllers/webhooks/*_spec.rb` or `spec/requests/webhooks/*` (per provider — not individually enumerated here) | inbound webhook processing |
| `spec/channels/` | ActionCable channel specs (real-time, not messaging-channel) |

**Coverage gaps observed:** did not individually verify spec coverage per channel type in this pass — flag for a per-channel deep-dive FRD if a specific channel (e.g. WhatsApp) needs implementation-level detail.

---

## 7. Dev tools / dependencies actually used

- WhatsApp: Cloud API / 360dialog (via `provider_config`)
- SMS/Voice: Twilio SDK
- Facebook/Instagram: Facebook Graph API
- Telegram: Telegram Bot API
- Email: ActionMailbox + SMTP/IMAP
- Web Widget: Chatwoot's own SDK (`app/javascript/sdk/`) + ActionCable

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Webhook verification handshake fails (WhatsApp/Instagram) | Provider subscription setup fails at the platform's end, not silently accepted |
| Duplicate webhook delivery (provider retries) | Dedup relies on `source_id` at message-creation time (see [02-messages.md](02-messages.md) gap) |
| Provider token/credential expired | Reauthorization flow via `Inbox#reauthorize_and_update_channel` on the inbox update path |
| WhatsApp message outside 24h session window | Requires an approved template send instead of free-form text (WhatsApp platform rule, enforced by `message_templates`) |

---

## 9. Open gaps / notes

- This is an overview FRD covering 11 channel types at a summary level — per-channel column lists and webhook signature-verification details were not individually verified against `db/schema.rb`/each controller in this pass. Recommend a dedicated deep-dive FRD for WhatsApp specifically (highest complexity: calling, templates, 24h window) if that's a priority area.
