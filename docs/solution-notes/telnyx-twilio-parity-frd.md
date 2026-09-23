# FRD — Telnyx as an Alternative Channel Provider (Twilio Parity)

> **Status:** Draft · **Owner:** TBD (Product) · **Initiative:** Reduce messaging/voice cost, add provider choice · **Target release:** TBD · **Jira epic:** TBD · **Figma:** TBD · **Implementation Spec:** Required (not yet written)
>
> Notion note: this FRD follows the NewRelay HQ PRD template (`Playground / 01 · Product & Strategy / 01 · Product Planning & Specs`). It could not be published to Notion directly — **the workspace has used all its free blocks and needs a plan upgrade** before new pages can be created there. Move this file's content into Notion once that's resolved.

## 1. Context / Problem

NR's only SMS / WhatsApp / Voice channel provider today is **Twilio**, integrated end-to-end (`Channel::TwilioSms`, enterprise Voice). Every workspace brings its own Twilio credentials (Account SID + Auth Token, or API Key + Secret) per inbox — NR does not hold a platform-level Twilio account.

**Telnyx** offers the same product surface (SMS/MMS, WhatsApp Business API, Programmable Voice via TeXML — a documented drop-in for TwiML) on its own carrier network, at roughly 40–50% lower published rates than Twilio (e.g. SMS ≈$0.004 vs Twilio's ≈$0.0083 per US message). Some prospects/customers already run Telnyx for other systems and want to bring those credentials into NR instead of provisioning Twilio.

No existing Notion page or ADR covers Telnyx or provider choice today — checked `Integrations & External Services` and the related Engineering Wiki pages; messaging-provider rows are unfilled `TBD` placeholders. This document is the first pass.

## 2. User / Job to be done

A **workspace admin** setting up an SMS, WhatsApp, or Voice inbox who wants to use their own Telnyx account instead of Twilio — for cost, an existing Telnyx relationship, or provider redundancy — without losing any capability the Twilio-backed inbox has today.

## 3. Objective

Offer Telnyx as a second, selectable channel provider for SMS, WhatsApp, and (enterprise) Voice inboxes, at functional parity with the existing Twilio integration — additive only, no change to how existing Twilio inboxes behave.

## 4. Success metric

**Primary:** a workspace can create a working SMS, WhatsApp, or Voice inbox on Telnyx with the same setup steps (± provider-specific fields) as Twilio, verified by sending/receiving a real message or call, within one sprint of GA.
**Guardrails:** zero regression in existing Twilio inbox behavior (message delivery rate, call success rate); no increase in webhook error rate account-wide after rollout.

## 5. User flow

Settings → Inboxes → Add Inbox → choose channel type (SMS / WhatsApp / Voice) → **choose provider: Twilio or Telnyx** (mirrors the provider selector `Sms.vue` / `Whatsapp.vue` already use) → enter Telnyx API Key + phone number / messaging profile ID → NR validates credentials live and auto-configures Telnyx's webhook URLs against that number/profile → inbox is ready to send/receive.

## 6. Requirements

**PRD-01 — Provider selector.** The existing provider selector on the SMS and WhatsApp channel-creation screens (`Sms.vue`, `Whatsapp.vue`) lists Telnyx alongside Twilio. The enterprise Voice channel form (`Voice.vue`) does the same, gated by the existing `channel_voice` feature flag.

**PRD-02 — Telnyx SMS/WhatsApp channel model.** A new channel record (mirrors `Channel::TwilioSms`) stores the Telnyx API Key, messaging profile ID / number, and `medium` (sms/whatsapp), encrypted the same way Twilio's `auth_token` is today.

**PRD-03 — Inbound message webhook.** A `/telnyx/callback`-style endpoint receives Telnyx's `message.received` webhook, verifies the Ed25519 signature (`telnyx-signature-ed25519` / `telnyx-timestamp` headers — different scheme than Twilio's, needs its own verifier), and creates/updates contact, conversation, and message records via a Telnyx equivalent of `Twilio::IncomingMessageService`.

**PRD-04 — Delivery status webhook.** A `/telnyx/delivery_status`-style endpoint consumes `message.sent` / `message.finalized` events and updates `Message#status`/`external_error`, mirroring `Twilio::DeliveryStatusService`.

**PRD-05 — Outbound send.** A `SendOnTelnyxService` (mirrors `Twilio::SendOnTwilioService`) sends SMS/MMS and WhatsApp messages, including template/content messages, and surfaces Telnyx API errors the same way Twilio errors surface today.

**PRD-06 — Webhook auto-configuration.** On inbox creation, NR writes the callback/status webhook URLs onto the customer's Telnyx messaging profile or number via the Telnyx API (mirrors `Twilio::WebhookSetupService`), so the admin never pastes a webhook URL into the Telnyx portal by hand.

**PRD-07 — WhatsApp templates.** WhatsApp Business Account (Meta) templates are fetched/synced from Telnyx and rendered through the same template-picker UI (`TemplateNormalizer.js`, `TemplateTypeDetector.js`) used for Twilio, generalized to parse Telnyx's template JSON shape alongside Twilio's Content API shape.

**PRD-08 — CSAT survey template.** The existing WhatsApp CSAT survey flow (`Twilio::CsatTemplateService`) works for Telnyx-backed WhatsApp inboxes.

**PRD-09 — Campaigns.** One-off SMS campaigns (`Campaign` model, `Twilio::OneoffSmsCampaignService`) work identically for Telnyx-backed SMS inboxes.

**PRD-10 — Voice (enterprise).** Inbound/outbound PSTN calling, agent conference pickup, browser-based agent calling, call recording, and optional transcription all work for a Telnyx-backed Voice inbox, using TeXML (Telnyx's documented TwiML-compatible call-control markup) in place of TwiML, and a Telnyx WebRTC client in place of `@twilio/voice-sdk`.

**PRD-11 — Auth model.** Telnyx uses a single API Key (not an SID + token pair) — the credential form and validation step reflect this simpler shape rather than reusing Twilio's two-field layout verbatim.

**PRD-12 — No impact to existing Twilio inboxes.** Every existing Twilio-backed inbox, campaign, template, and call flow continues to work unmodified; Telnyx is purely additive.

**PRD-13 — UI/helper parity.** Inbox badges, icons, and type-detection helpers (`inboxMixin.js`, `helper/inbox.js`, `components-next/icon/provider.js`) recognize Telnyx-backed inboxes the same way they recognize Twilio ones today (`isATelnyxChannel`, etc.).

**PRD-14 — i18n.** All new user-facing strings are added to `en.yml` (backend) and `en.json` (frontend) only, per NR i18n convention.

## 6a. AI Voice Agent — Telnyx number + ElevenLabs (separate use case)

This was missed in the original draft. It is **not** Twilio-parity work — Twilio has no equivalent NR uses today — and it's architecturally unrelated to §6's PRD-10 (enterprise Voice/TeXML), so it's broken out here rather than folded into PRD-10.

**What it is:** a Telnyx virtual phone number connected via **SIP trunking** (an FQDN-type SIP Connection on Telnyx, pointed at `sip.rtc.elevenlabs.io`) directly to an **ElevenLabs Conversational AI** agent. Telnyx supplies the number and telephony network; ElevenLabs supplies the AI — speech-to-text, the conversational model, and text-to-speech voice — and answers/places the call itself. Confirmed via ElevenLabs' own Telnyx integration docs.

**How it differs from PRD-10's enterprise Voice:** PRD-10 is Twilio-parity — a human agent answers via NR's UI, bridged through TeXML/Call Control the same way Twilio Voice works today. This is a different shape entirely: **NR is not in the call-control loop.** Once the SIP trunk is configured, the call goes straight from Telnyx to ElevenLabs; NR's role is provisioning the number and the SIP connection, not handling the audio or conversation.

**PRD-15 — Number + SIP connection provisioning.** An admin can provision a Telnyx virtual number and configure the SIP trunk to an ElevenLabs agent from within NR (Settings, likely under a new "AI Voice Agent" inbox/channel type, or an extension of the existing Voice channel flow) — without needing to hand-configure it in the Telnyx or ElevenLabs portals directly.

**PRD-16 — ElevenLabs credential storage.** This requires **ElevenLabs API credentials in addition to Telnyx credentials** — a separate third-party integration, encrypted at rest the same way Telnyx/Twilio credentials are today. Not yet in this FRD's dependency list (§13) prior to this addition.

**PRD-17 — Call visibility (open question, see §15 item 5).** Whether these AI-agent calls should appear in NR's inbox as a Conversation (matching NR's "unified inbox across channels" product thesis), or stay entirely inside ElevenLabs with no NR-side record, is **not yet decided** — flagged rather than assumed, since it changes the architecture significantly (ingesting ElevenLabs' own post-call webhook/transcript vs. building nothing on the NR side beyond provisioning).

## 7. Acceptance criteria

- Given an admin on the Add Inbox screen, when they choose SMS/WhatsApp and select Telnyx as the provider, then they see Telnyx-specific credential fields (API Key, number/profile ID) instead of Twilio's.
- Given valid Telnyx credentials, when the admin submits the form, then NR validates the credentials against the Telnyx API, creates the inbox, and auto-configures the webhook URLs on Telnyx — with a clear inline error if validation fails (invalid key, wrong permissions, number not found).
- Given a Telnyx-backed SMS/WhatsApp inbox, when a customer sends an inbound message, then it appears in the NR inbox within the same latency bounds as a Twilio message today.
- Given an outbound message sent from a Telnyx-backed inbox, when Telnyx reports `message.finalized` with a failure, then the message shows a failed/error state with the provider's error reason, same as Twilio failures do today.
- Given a Telnyx-backed WhatsApp inbox, when an admin opens the template picker, then approved WhatsApp templates fetched from Telnyx render and send correctly.
- Given a Telnyx-backed Voice inbox (enterprise, `channel_voice` enabled), when an agent places or receives a call, then the call connects, can be picked up via conference, and — if recording is enabled — a recording is attached to the conversation afterward.
- Given an existing Twilio-backed inbox, when this feature ships, then its behavior, webhooks, and stored credentials are unchanged.
- Permissions: only account admins can add or edit a Telnyx (or Twilio) channel, matching current inbox-creation permissions.

## 8. Use cases / examples

- A workspace with an existing Twilio SMS inbox adds a second, independent Telnyx SMS inbox for a different number/line of business.
- A new workspace with no Twilio relationship sets up WhatsApp entirely on Telnyx.
- An enterprise customer already using Telnyx for SIP trunking elsewhere in their stack adds a Telnyx Voice inbox in NR to consolidate billing.
- A workspace wants an always-on AI receptionist: they provision a Telnyx number in NR, connect it to an ElevenLabs Conversational AI agent, and the agent answers calls 24/7 without a human agent involved (PRD-15/16).

## 9. Edge cases

- Invalid or revoked Telnyx API Key at credential-entry time and later at send time (key rotated after inbox creation).
- Webhook signature verification failure (Ed25519) — must reject, not silently accept.
- Same phone number configured on both a Twilio inbox and a Telnyx inbox (should be prevented/flagged, same as duplicate-number handling today).
- WhatsApp template rejected or pending Meta approval — UI must reflect status, not just "missing."
- Telnyx STOP/opt-out is automatic on their side; confirm NR's own opt-out handling doesn't double-process or conflict.
- TeXML call-control edge cases where Telnyx's implementation diverges from Twilio's TwiML (Telnyx's compatibility is not 100% verified against every verb NR's TwiML controller uses — flagged as an implementation-phase spike, not assumed).
- Rate limiting / throughput differences between the two providers affecting campaign send speed.
- Existing Twilio-only UI components (`Twilio.vue`, `twilioChannel.js`) are hard-coded to Twilio's field set — must be generalized without breaking current Twilio flows.

## 10. In scope

- SMS (two-way, MMS, delivery status) via Telnyx SMS API.
- WhatsApp via Telnyx WhatsApp Business API (Meta WABA-backed, same model as Twilio's WhatsApp).
- Enterprise Voice (PSTN calling, conferencing, browser calling, recording) via Telnyx Voice API / TeXML.
- Webhook auto-configuration on inbox creation.
- WhatsApp template sync/send, CSAT survey templates, one-off SMS campaigns for Telnyx-backed inboxes.
- **AI Voice Agent (Telnyx number + ElevenLabs Conversational AI)** — see §6a below. This is a second, distinct Telnyx use case, not Twilio-parity work: a Telnyx virtual number bridged via **SIP trunking** to an ElevenLabs Conversational AI agent, which answers/places calls and speaks with ElevenLabs voices.

## 11. Explicitly out of scope

- Migrating or porting existing Twilio numbers/inboxes to Telnyx (a separate, later initiative if pursued).
- Telnyx Verify (2FA/OTP) — NR doesn't use Twilio Verify today, so no parity requirement.
- Telnyx Email API, RCS, Fax, IoT/eSIM, Edge Compute, Number Lookup, Number Reputation, Branded Calling/STIR-SHAKEN, Virtual Cross Connects/Cloud VPN — none of these have a current Twilio counterpart in NR's codebase.
- Twilio Flex, Studio, TaskRouter, Sync, Serverless Functions, Video — not used by NR today, so not a Telnyx migration concern.
- Telnyx-side number provisioning (buying new numbers through NR) — mirrors today's BYO-number approach for Twilio; NR configures webhooks on numbers the customer already owns.
- **Correction from an earlier draft of this FRD:** SIP Trunking and Telnyx's AI Inference/Agents were previously listed here as fully out of scope. That was wrong — SIP trunking is now **in scope**, narrowly, for the AI Voice Agent use case (§6a). It remains out of scope for anything else (no general customer-owned-PBX support).

## 12. Analytics / instrumentation

- Inbox-creation event tagged with `channel_provider: telnyx | twilio`.
- Message send/delivery events tagged by provider, to compare delivery success rate Telnyx vs Twilio.
- Voice call events tagged by provider.
- If a cost-reporting dashboard exists, split messaging/voice spend by provider so the cost-savings hypothesis in Section 1 can actually be measured.

## 13. Dependencies & constraints

- Needs a Telnyx developer/sandbox account for build and QA (owner TBD — see Open Questions).
- **New, added with §6a:** needs an ElevenLabs account/API credentials for build and QA, separate from the Telnyx sandbox above — a second third-party dependency this FRD didn't originally list.
- Telnyx WhatsApp requires Meta Business verification, same dependency Twilio WhatsApp already has today — no new compliance surface, but still a per-customer onboarding step.
- Enterprise Voice gating today is a single `feature_enabled?('channel_voice')` flag; needs to keep working for a Telnyx-backed voice channel too (not fork into a Twilio-only flag).
- Encrypted credential storage pattern already exists (`Channel::TwilioSms#auth_token`) and should be reused for the Telnyx API Key.
- Template normalization code (`TemplateNormalizer.js`, `TemplateTypeDetector.js`, `TemplateConstants.js`) is currently Twilio-shaped and needs a compatible extension, not a parallel rewrite.
- Per the NR process, an integration of this size — new provider, new webhooks, changes across SMS/WhatsApp/Voice/Campaigns/Templates — likely also requires an **Architecture Design** and a **Technical Implementation Spec** before implementation starts; this FRD is the PRD stage only.
- Voice (Phase 3) now has a first-pass Architecture Design: [telnyx-voice-architecture-design.md](telnyx-voice-architecture-design.md) — Draft, unapproved. SMS (Phase 1) and WhatsApp (Phase 2) don't have one yet.

## 14. Rollout

Feature-flagged (`channel_provider_telnyx`), phased by complexity and risk:

| Phase | Scope | Exit criteria |
|---|---|---|
| **Phase 0 — Spike** | Confirm TeXML covers every TwiML verb NR's voice controller uses (conference bridging, status/recording callbacks); confirm Telnyx sandbox account access. | Written go/no-go on Voice scope; sandbox credentials in hand. |
| **Phase 1 — SMS** | `Channel::TelnyxSms` (or equivalent) model, inbound/outbound webhooks, delivery status, provider selector on `Sms.vue`, campaigns. Internal/beta workspaces only, behind the feature flag. | Inbound + outbound SMS verified end-to-end; delivery-status parity confirmed against a Twilio control inbox for 1–2 weeks. |
| **Phase 2 — WhatsApp** | WhatsApp Business API via Telnyx, template sync/send, CSAT survey template, provider selector on `Whatsapp.vue`. | Template sync verified against a live Meta WABA; CSAT flow sends correctly. |
| **Phase 3 — Voice (enterprise)** | PSTN calling, browser calling (Telnyx WebRTC SDK), conferencing, recording/transcription, provider selector on `Voice.vue`. Only if Phase 0 spike is green. | Call success rate at parity with Twilio for 1–2 weeks in beta. |
| **Phase 4 — GA** | Feature flag removed/defaulted on for all workspaces; docs and onboarding updated. | All phases signed off; no open P1/P2 bugs. |

Each phase ships to a small set of beta workspaces before widening, per NR's standard rollout practice.

## 15. Open questions

1. Generalize the existing Twilio-only Vue components (`Twilio.vue`, `twilioChannel.js`) into provider-agnostic components, or build parallel Telnyx-specific ones? (Lean: generalize — `Sms.vue`/`Whatsapp.vue` already have a provider-selector pattern built for this.)
2. Who owns the Telnyx sandbox/developer account used for build and QA?
3. Confirm TeXML's real coverage of every TwiML verb NR's voice controller currently relies on (conference bridging, status callbacks) before committing Voice to phase 1 — needs a technical spike.
4. Does Product want Telnyx Verify (2FA) evaluated in a follow-up, given NR doesn't use Twilio Verify today? Marked out of scope here pending confirmation.
5. **AI Voice Agent call visibility (PRD-17):** should a Telnyx+ElevenLabs AI call create a Conversation in NR's inbox (transcript ingested via ElevenLabs' post-call webhook/API), or does it stay entirely inside ElevenLabs with NR only provisioning the number/trunk? Lean: make it visible in the inbox — NR's core pitch is a unified inbox across channels, and an AI phone call customers can't see alongside their other conversations undercuts that. Needs Product confirmation before this becomes a real requirement rather than a lean.
6. Is the AI Voice Agent (§6a) meant to connect to NR's own existing "AI Agents / automation" product module (Playground's product modules list), i.e. should the *same* AI Agent that handles chat/email conversations also answer phone calls through this integration — or is this a standalone ElevenLabs-branded capability unrelated to NR's own AI Agent concept? Architecturally very different answers; not yet decided.
7. Sequencing: does the AI Voice Agent (§6a) ship as part of Phase 3 (Voice) in §14, as its own phase, or independently of the Twilio-parity phases entirely, given it doesn't depend on PRD-01 through PRD-14 at all? Not yet placed in the rollout table.

## 16. Decisions / approvals

| Decision / Gate | Owner | Date |
|---|---|---|
| **Coexist, not replace** — Telnyx is added as an additional provider option; Twilio is not removed or deprecated. Confirmed directly by the requester, not just assumed. | Product (via chat) | 2026-09-23 |
| PRD approved | TBD | TBD |

---

## Appendix — Twilio usage in the codebase vs. Telnyx equivalent

| Capability used today | Twilio product | Code location(s) | Telnyx equivalent | Parity notes |
|---|---|---|---|---|
| Two-way SMS send/receive | Programmable Messaging (SMS) | `Channel::TwilioSms`, `Twilio::SendOnTwilioService`, `Twilio::IncomingMessageService`, `/twilio/callback` | SMS API | Full parity; Telnyx auto-handles STOP opt-out server-side |
| MMS / media attachments | Programmable Messaging (MMS) | `IncomingMessageService` (`MediaUrl0..9`), `SendOnTwilioService` | MMS API | Full parity |
| Delivery status callbacks | Messaging status webhooks | `Twilio::DeliveryStatusService`, `/twilio/delivery_status` | `message.sent` / `message.finalized` webhooks | Full parity; Ed25519-signed (not HMAC) — new verifier needed |
| WhatsApp messaging | Twilio WhatsApp (Meta WABA-backed) | `Channel::TwilioSms` (`medium: whatsapp`), `WhatsappIdentifierHelper` | WhatsApp Business API (also Meta WABA-backed) | Full parity; both require Meta Business verification |
| WhatsApp Content Templates | Twilio Content API | `Twilio::TemplateSyncService`, `TemplateProcessorService`, `TemplateNormalizer.js` | Telnyx WhatsApp templates (Meta template passthrough) | New sync/normalize logic needed; template JSON shape differs |
| WhatsApp CSAT survey template | Twilio Content API | `Twilio::CsatTemplateService` / `CsatTemplateApiClient` | Telnyx WhatsApp templates | Same as above |
| One-off SMS campaigns | Programmable Messaging | `Twilio::OneoffSmsCampaignService`, `Campaign` model | SMS API | Full parity |
| Outbound/inbound PSTN voice | Programmable Voice | enterprise `Voice::Provider::Twilio::Adapter`, `/twilio/voice/call` | Voice API + TeXML | Full parity; TeXML documented as a TwiML drop-in |
| Browser-based agent calling | Twilio Voice JS SDK + Access Tokens | `twilioVoiceClient.js`, `TokenService` (`Twilio::JWT::AccessToken`) | Telnyx WebRTC SDK | New client + token/JWT service needed |
| Call conferencing (agent pickup) | Twilio Conference | `ConferenceService`, `/twilio/voice/conference_status` | Voice API conferencing | Full parity |
| Call recording + transcription | Twilio Recording API | `RecordingAttachmentService`, recording-status webhook | Voice API recording | Full parity |
| TwiML App auto-provisioning | Twilio TwiML Apps | `VoiceWebhookSetupService`, `VoiceTeardownService` | Telnyx voice app/number config API | New provisioning service needed |
| Webhook auto-config on customer's number | Twilio number/messaging service config API | `WebhookSetupService` | Telnyx Messaging Profile / number webhook config API | Full parity, different API shape |
| Auth: Account SID+Token or API Key+Secret | Twilio Account credentials | `Channel::TwilioSms` fields | Telnyx API Key (single key) | Simpler — one field, not a pair |
| Number provisioning | N/A — BYO Twilio number only | Not implemented today | Telnyx Global Numbers API (optional, future) | Out of scope — mirrors current BYO approach |

**Twilio features NR does *not* use today** (so no Telnyx parity is required): Flex, Studio, TaskRouter, Verify/2FA, Authy, Video, Sync, Serverless Functions.

**Telnyx features with no current Twilio counterpart in NR** (out of scope per Section 11): RCS, Fax API, Email API, IoT SIM/eSIM, Edge Compute (Functions/Inference/KV/SQL/Object Storage), Number Lookup, Number Reputation, Deepfake Detection, Branded Calling/STIR-SHAKEN, Virtual Cross Connects/Cloud VPN.

**What is SIP Trunking, and why does §6a need it?**

- Connects a phone system to the public telephone network (PSTN) over the internet via the SIP protocol — the modern replacement for physical analog/PRI phone lines.
- Normally lets a customer plug their own PBX, call-center platform, or UCaaS system directly into the carrier network — and NR's Twilio-parity Voice work (PRD-10) doesn't need this, since it uses the declarative TwiML/TeXML model instead (Voice API handles call logic via webhooks, no customer-owned PBX involved).
- **Correction:** an earlier draft of this document said "there's nothing for SIP trunking to plug into" in NR's architecture. That was true for PRD-10 (human-agent Voice) but wrong for the AI Voice Agent use case (§6a): ElevenLabs' Conversational AI *is* the thing SIP trunking plugs into. ElevenLabs' own integration guide confirms the connection is SIP trunking (an FQDN-type Telnyx SIP Connection pointed at `sip.rtc.elevenlabs.io`), not TeXML/Call Control.
- So: SIP trunking is in scope narrowly for §6a, and still out of scope for general customer-owned-PBX support (that remains a real non-goal — NR isn't becoming a PBX-integration platform).

## Appendix B — Pricing comparison (only the capabilities NR uses)

List-rate, pay-as-you-go pricing, US unless noted. Both vendors offer volume/committed-plan discounts off these list rates.

| Line item | Twilio | Telnyx | Telnyx savings |
|---|---|---|---|
| SMS — outbound (US) | $0.0079 / msg | $0.004 / msg | ~49% cheaper |
| SMS — inbound (US) | $0.0075 / msg | $0.004 / msg | ~47% cheaper |
| MMS | Included in Programmable Messaging (~$0.02/msg typical) | Included in SMS API rate above | Comparable, priced per message part on both |
| Voice — outbound (US) | $0.014 / min | $0.002 / min | ~86% cheaper |
| Voice — inbound (US) | $0.0085 / min | $0.002 / min | ~76% cheaper |
| WhatsApp messaging | $0.005 / msg (Twilio) + Meta's $0.0034–$0.0499 template/conversation fee | $0.004 / msg (Telnyx) + same Meta fee, passed through with **no markup** | ~20% cheaper on the platform fee; Meta's own fee is identical on both since Telnyx doesn't mark it up |
| WhatsApp calling | Priced under Voice API | $0.0025 / min + Meta passthrough | New Twilio product (2025) — direct rate not confirmed, flagged as an open question |
| Local phone number | $1.15 / month | $1.00 / month | ~13% cheaper |
| Toll-free number | $2.00 / month | Comparable (not itemized separately in Telnyx's public pricing) | Needs confirmation during Phase 0 spike |
| A2P 10DLC brand registration | $4 one-time | $4.50 one-time | Set by The Campaign Registry (TCR), not the provider — roughly the same either way |
| A2P 10DLC campaign registration | $10–15 / month per campaign | ~$10 / month per campaign (standard use case) + a one-time $15 vetting fee on new registrations | Roughly comparable, also TCR-driven |

**Illustrative monthly cost at NR's current usage shape** — for a workspace sending/receiving a mix of SMS and voice minutes, the biggest swing is **Voice** (~76–86% cheaper on Telnyx) and **SMS** (~47–49% cheaper); WhatsApp savings are smaller since Meta's own conversation fee is the larger cost component and is identical on both platforms. Exact savings depend on each workspace's actual message/minute volume — Section 12's per-provider cost analytics exist specifically to measure this once Telnyx inboxes are live, rather than relying on this list-rate estimate.

## Appendix C — Packages / SDKs to add

Mirrors the existing Twilio entries in `Gemfile` and `package.json` (see Section 6, PRD-02/PRD-10). No packages are removed — these are additive, same as the rest of this FRD.

| Layer | Existing Twilio package | New Telnyx package | Notes |
|---|---|---|---|
| Backend (Ruby) | `gem 'twilio-ruby'` (`Gemfile:107`, resolved `7.6.0` in `Gemfile.lock`) | `gem 'telnyx'` — [official Ruby SDK](https://github.com/team-telnyx/telnyx-ruby), currently `5.68.2`, requires **Ruby ≥ 3.2.0** | Confirm against `.ruby-version` before adding — a version floor bump would affect the whole app, not just this feature. Covers SMS/MMS/WhatsApp/Voice/Call Control/Number Management REST calls, same role `twilio-ruby` plays today. |
| Frontend — browser calling (JS) | `"@twilio/voice-sdk": "^2.12.4"` (`package.json:61`) | `@telnyx/webrtc` — [official WebRTC SDK](https://www.npmjs.com/package/@telnyx/webrtc), `npm install @telnyx/webrtc` | Drop-in role-equivalent to `twilioVoiceClient.js`'s use of `@twilio/voice-sdk`'s `Device`; exposes a `TelnyxRTC` client instead. |
| Auth model difference | Twilio: JWT **Access Token** minted per-call via `Twilio::JWT::AccessToken` + `VoiceGrant` (`TokenService`) | Telnyx: authenticates via a **SIP Connection** (username/password, or a JWT created the same way) | `enterprise/app/services/voice/provider/twilio/token_service.rb` needs a Telnyx-specific counterpart — not a drop-in, since the credential shape differs (SIP Connection vs. Access Token). |

## Appendix D — AI Voice Agent (Telnyx + ElevenLabs) technical facts

Backing research for §6a, PRD-15/16/17.

- **Integration mechanism:** SIP trunking, not TeXML/Call Control. Confirmed by ElevenLabs' own Telnyx integration docs and Telnyx's release notes announcing the ElevenLabs TTS/agent integration (March 2026).
- **Telnyx-side setup:** create an FQDN-type SIP Connection; inbound routing points at `sip.rtc.elevenlabs.io` (destination format `+E.164`, TCP transport); a purchased Telnyx number is linked to that connection; outbound calls (ElevenLabs placing a call back through the trunk) use digest auth credentials on the connection.
- **ElevenLabs-side setup:** configured separately in ElevenLabs' own portal/API (their docs reference a separate SIP trunking guide) — this FRD does not yet have those exact steps, only that they exist and are required.
- **Who handles the call:** ElevenLabs' platform, entirely — inbound calls route Telnyx → ElevenLabs' origination URI; ElevenLabs is the AI brain and voice. NR is not in this call-control path at all unless PRD-17 (call visibility) is built.
- **Telnyx also ships its own competing "Voice AI Agents" product** (native, not ElevenLabs) — not what was asked for here, but worth knowing it exists as an alternative if ElevenLabs isn't a hard requirement; not evaluated further in this FRD.
- **Not confirmed:** whether ElevenLabs sends call data/transcripts to a webhook NR could ingest (their SIP trunking docs don't cover this — would need ElevenLabs' separate Conversational AI API/webhook docs, relevant to PRD-17/Open Question 6).

**Sources:** [Telnyx Products](https://telnyx.com/products) · [Telnyx Pricing](https://telnyx.com/pricing) · [Telnyx WhatsApp Pricing](https://telnyx.com/pricing/whatsapp) · [Telnyx 10DLC Fees](https://support.telnyx.com/en/articles/5634625-10dlc-fees-and-charges) · [Telnyx vs Twilio comparison](https://www.courier.com/integrations/compare/telnyx-vs-twilio) · [Telnyx TeXML vs TwiML](https://telnyx.com/telnyx-texml-vs-twilio-twiml) · [Telnyx SMS API](https://telnyx.com/products/sms-api) · [Telnyx WhatsApp quickstart](https://developers.telnyx.com/docs/messaging/whatsapp/quickstart) · [Telnyx Verify API pricing](https://telnyx.com/pricing/verify-api) · [Telnyx Ruby SDK](https://github.com/team-telnyx/telnyx-ruby) · [Telnyx WebRTC JS SDK](https://www.npmjs.com/package/@telnyx/webrtc) · [Twilio Pricing](https://www.twilio.com/en-us/pricing) · [Twilio SMS Pricing (US)](https://www.twilio.com/en-us/sms/pricing/us) · [Twilio Pricing Breakdown 2026](https://automationatlas.io/answers/twilio-pricing-explained-2026/) · [ElevenLabs ↔ Telnyx integration](https://elevenlabs.io/agents/integrations/telnyx) · [ElevenLabs Telnyx SIP trunking docs](https://elevenlabs.io/docs/conversational-ai/phone-numbers/telephony/telnyx) · [Telnyx ElevenLabs TTS integration release note](https://telnyx.com/release-notes/tts-neural-voices-elevenlabs-integration) · [Telnyx native Voice AI Agents](https://telnyx.com/products/voice-ai-agents)
