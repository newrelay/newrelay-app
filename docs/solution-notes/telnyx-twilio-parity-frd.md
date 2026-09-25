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

## 6a. Virtual number purchase — buy a Telnyx number from inside NR

> **🚨 Blocking finding — CONFIRMED, not just observed (2026-09-24): Telnyx has no SMS-capable numbers in India, and this is by design, not an account-tier quirk.** Live API test: searched all five Telnyx phone number types for India (`local`, `mobile`, `toll_free`, `national`, `shared_cost`) with `features[]=sms` — every single one returned `"No coverage found in the specified country based on the provided search parameters"` (error 10015). **Cross-checked against Telnyx's own product announcement** — [Telnyx's "India Mobile Numbers" release note](https://telnyx.com/release-notes/india-mobile-numbers), dated **2026-09-17** (roughly a week before this check, a genuinely new launch) — which scopes the entire feature to **"Two-way voice calling: Make and receive calls on Indian mobile numbers within India."** No SMS or MMS is mentioned anywhere in Telnyx's own announcement of the feature. This rules out the "maybe it's just this account's tier" possibility from the earlier live test — it's not a limitation of one account, it's the actual scope of what Telnyx shipped for India. **This breaks §6a's stated premise for India** — India was added to *Phase 1 — SMS* specifically for SMS provisioning, and Telnyx India numbers are voice-only. **Decision needed:** either India comes out of Phase 1's SMS scope entirely, or Phase 1's definition of "India" narrows to a Voice-only capability (which would then logically belong under PRD-10/§6b's Voice work, not §6a's SMS-provisioning flow) — see the updated Open Question at the end of this section.
>
> **🚨 Second blocking finding, same test account, same day: three of the four core provisioning calls are account-tier-gated.** `regulatory_requirements` lookup and `number_reservations.create` both returned `"Feature not permitted at this account level"` (error 10038). `number_orders.create` returned `"Only 1 order is allowed at your account level"` (error 10039) when actually attempted (with explicit purchase confirmation) against a real, available, $0-listed US number — no charge occurred, the order was rejected outright. **This account tier cannot exercise search → reserve → order as a full flow at all.** Whether this is specific to this one test account (a free/trial tier, or one that already has an order on it) or representative of what a real NR customer's own Telnyx account would need is unknown — this needs checking against the Telnyx dashboard for this account, and/or against Telnyx's published plan-tier documentation, before assuming Phase 1's flow works on whatever tier NR's own reseller-model account (PRD-19) would be provisioned at.

Its own section (not just a bullet in §6's requirement list) because it's a genuinely new capability, not Twilio-parity work — Twilio-backed inboxes never had this, BYO-only, unchanged. **Now in Phase 1.** This corrects §10/§11 and the Appendix A table below, which an earlier draft of this FRD marked out of scope/BYO-only.

**What it is:** an admin setting up a Telnyx-backed SMS inbox can search for and purchase a **new** Telnyx number **from inside NR**, instead of only entering a number they already own in their own Telnyx account. BYO remains supported alongside this — additive, not a replacement path. Full technical process (exact API endpoints, order lifecycle) is in Appendix E.

**Country selector, confirmed by the requester: two options, not one hardcoded country.** Phase 1 supports **US** and **India**, chosen explicitly by the admin — not a single country baked into the backend. This directly resolves Open Question 8 below, and changes its answer: India numbers carry real KYC/regulatory requirements (confirmed against Telnyx's own India documentation — address + ID verification, restricted to four authorized telecom districts: Mumbai City, Gurugram, Noida, Bangalore), so Phase 1 **cannot** fully defer the regulatory-document flow the way a US-only scope would have let it. See the updated Appendix E and Open Question 8 for what this means concretely.

**PRD-18 — Number search, order & auto-configuration.**
1. Admin picks a country (US or India — Phase 1's fixed allowlist, not free text) and enters optional area code/locality (or, for India, one of the four authorized telecom districts); NR calls Telnyx's number-search API and shows matching available numbers.
2. Admin picks one; NR places an order via Telnyx's number-order API.
3. **US numbers:** typically no regulatory requirements — activates in seconds, inbox immediately usable.
4. **India numbers:** carry KYC requirements by default — address + ID verification, and the number must be tied to one of four authorized telecom districts (Mumbai City, Gurugram, Noida, Bangalore). The order sits in a pending/under-review state until the admin supplies the required documents and Telnyx approves them; this is not a rare edge case for India the way it is for most US numbers, it's the normal path.
5. Once active, PRD-06's webhook auto-configuration runs against the newly-owned number automatically — no separate manual step.

**PRD-19 — Reseller model, confirmed by the requester (major correction to the credential model this FRD is built on).** Purchased numbers (PRD-18) are **not** BYO the way every other Telnyx capability in this FRD is. NR provisions them under **NR's own Telnyx master account**, marks up Telnyx's wholesale cost, and bills the customer through NR's own billing/subscription system. The customer never enters their own Telnyx credentials for a purchased number, and never deals with Telnyx directly for it. This is a second, parallel credential model that exists only for PRD-18/PRD-19 — every other Telnyx capability in this FRD (SMS BYO, WhatsApp, Voice, the number *search* itself) still uses the customer's own Telnyx account.

**Why this is a bigger deal than it sounds, and probably needs its own Architecture Design before implementation:**
- **A new platform-level secret.** NR now holds one Telnyx API key that can act on behalf of *every* customer using this feature — a materially different security blast radius than a BYO key scoped to one customer's own account. Compromise of this one credential affects every reseller-model number across every NR account, not one customer's Telnyx account.
- **Multi-tenant number ownership.** Telnyx sees one account (NR's) holding numbers for many different NR customers. NR's backend must enforce that isolation itself — nothing about Telnyx's own account boundary does it for us anymore, unlike BYO where each customer's Telnyx account is naturally isolated from every other customer's.
- **A new billing dependency this FRD has never touched.** Whatever NR's actual billing/subscription system is (not yet identified in this FRD — see Open Question 10) needs a new recurring line item: Telnyx's wholesale cost + NR's margin, tied to a specific number, that has to reconcile with the number's lifecycle (see next point).
- **A real lifecycle question with no answer yet:** what happens to a purchased number when the customer's NR subscription lapses, downgrades, or is cancelled? Does NR release the number back to Telnyx's inventory (losing it, and losing continuity for the customer if they resubscribe)? Keep it reserved for some grace period? This didn't exist as a question anywhere else in this FRD, because BYO numbers are the customer's own property regardless of their NR subscription status.
- **Process implication:** per NR's own process (this doc's parent skill), a change that introduces a shared platform credential, crosses into billing/subscription ownership, and changes a tenant-isolation model this significantly is squarely in "two+ modules, shared contract, tenant/data ownership" territory — the tier that requires an **Architecture Design** (and likely an **ADR**, since a platform-owned reseller credential is expensive to reverse once real customer numbers exist under it) before a Technical Implementation Spec, the same gate used for the Voice work. The existing [Implementation Spec for §6a](telnyx-virtual-number-purchase-implementation-spec.md) was written *before* this decision and does not yet reflect it — flagged there, not silently left stale.

## 6b. AI Voice Agent — Telnyx number + ElevenLabs (separate use case)

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
- Given an admin searching for a number by country/area code, when results come back, then they see real, currently-purchasable numbers from Telnyx (not a stale/cached list) with their type (local/toll-free) and whether they carry regulatory requirements.
- Given a purchased number that needs regulatory documents, when the admin hasn't submitted them yet, then the inbox/number shows a clear "action needed" state (not "ready" and not "failed") with a way to submit the required info.
- Given a number order that completes successfully, when activation finishes, then PRD-06's webhook auto-configuration runs against it automatically, with no separate manual step for the admin.

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
- A number order (PRD-18) sits in a pending/under-review state waiting on regulatory documents — the inbox exists but isn't usable yet; UI must show this clearly rather than looking broken or silently failing.
- A number order is rejected (bad/expired documents) or hits its submission deadline and auto-cancels — admin needs a clear path to see why and retry, not a dead-end inbox.
- Two admins on the same account try to purchase the same searched number at the same time (Telnyx-side race, not NR's to prevent, but NR's error surfacing needs to handle "number no longer available" gracefully).

## 10. In scope

- SMS (two-way, MMS, delivery status) via Telnyx SMS API.
- WhatsApp via Telnyx WhatsApp Business API (Meta WABA-backed, same model as Twilio's WhatsApp).
- Enterprise Voice (PSTN calling, conferencing, browser calling, recording) via Telnyx Voice API / TeXML.
- Webhook auto-configuration on inbox creation.
- WhatsApp template sync/send, CSAT survey templates, one-off SMS campaigns for Telnyx-backed inboxes.
- **Virtual number purchase via the Telnyx API** (§6a, PRD-18) — buying a new Telnyx number from inside NR, not just BYO. In Phase 1.
- **AI Voice Agent (Telnyx number + ElevenLabs Conversational AI)** — see §6b below. This is a second, distinct Telnyx use case, not Twilio-parity work: a Telnyx virtual number bridged via **SIP trunking** to an ElevenLabs Conversational AI agent, which answers/places calls and speaks with ElevenLabs voices.

## 11. Explicitly out of scope

- Migrating or porting existing Twilio numbers/inboxes to Telnyx (a separate, later initiative if pursued).
- Telnyx Verify (2FA/OTP) — NR doesn't use Twilio Verify today, so no parity requirement.
- Telnyx Email API, RCS, Fax, IoT/eSIM, Edge Compute, Number Lookup, Number Reputation, Branded Calling/STIR-SHAKEN, Virtual Cross Connects/Cloud VPN — none of these have a current Twilio counterpart in NR's codebase.
- Twilio Flex, Studio, TaskRouter, Sync, Serverless Functions, Video — not used by NR today, so not a Telnyx migration concern.
- ~~Telnyx-side number provisioning (buying new numbers through NR)~~ — **reversed, see §6a/PRD-18.** An earlier draft of this FRD said this mirrors Twilio's BYO-only approach and was out of scope. It's now in scope, Phase 1: NR provisions new Telnyx numbers directly via Telnyx's number-search/order API, in addition to (not instead of) BYO.
- Provisioning new **Twilio** numbers through NR remains out of scope — Twilio stays BYO-only, unchanged (PRD-12). This is a Telnyx-only capability, not retrofitted onto the existing Twilio flow.
- **Correction from an earlier draft of this FRD:** SIP Trunking and Telnyx's AI Inference/Agents were previously listed here as fully out of scope. That was wrong — SIP trunking is now **in scope**, narrowly, for the AI Voice Agent use case (§6b). It remains out of scope for anything else (no general customer-owned-PBX support).

## 12. Analytics / instrumentation

- Inbox-creation event tagged with `channel_provider: telnyx | twilio`.
- Message send/delivery events tagged by provider, to compare delivery success rate Telnyx vs Twilio.
- Voice call events tagged by provider.
- If a cost-reporting dashboard exists, split messaging/voice spend by provider so the cost-savings hypothesis in Section 1 can actually be measured.

## 13. Dependencies & constraints

- Needs a Telnyx developer/sandbox account for build and QA (owner TBD — see Open Questions).
- **New, added with §6b:** needs an ElevenLabs account/API credentials for build and QA, separate from the Telnyx sandbox above — a second third-party dependency this FRD didn't originally list.
- **New, added with PRD-18, now settled (see §16):** number provisioning has a real dependency this FRD didn't originally scope — regulatory-requirement handling. Since Phase 1 confirmed supports both US and India (not US-only), and India numbers require KYC (address/ID, four-district restriction) as their normal path rather than a rare edge case, Phase 1 **must** include a real document-submission UI — it can no longer be deferred entirely the way a US-only scope would have allowed.
- Telnyx WhatsApp requires Meta Business verification, same dependency Twilio WhatsApp already has today — no new compliance surface, but still a per-customer onboarding step.
- Enterprise Voice gating today is a single `feature_enabled?('channel_voice')` flag; needs to keep working for a Telnyx-backed voice channel too (not fork into a Twilio-only flag).
- Encrypted credential storage pattern already exists (`Channel::TwilioSms#auth_token`) and should be reused for the Telnyx API Key.
- Template normalization code (`TemplateNormalizer.js`, `TemplateTypeDetector.js`, `TemplateConstants.js`) is currently Twilio-shaped and needs a compatible extension, not a parallel rewrite.
- Per the NR process, an integration of this size — new provider, new webhooks, changes across SMS/WhatsApp/Voice/Campaigns/Templates — likely also requires an **Architecture Design** and a **Technical Implementation Spec** before implementation starts; this FRD is the PRD stage only.
- Voice (Phase 3) now has a first-pass Architecture Design: [telnyx-voice-architecture-design.md](telnyx-voice-architecture-design.md) — Draft, unapproved. WhatsApp (Phase 2) doesn't have one yet.
- §6a (virtual number purchase, PRD-18) now has a Technical Implementation Spec: [telnyx-virtual-number-purchase-implementation-spec.md](telnyx-virtual-number-purchase-implementation-spec.md) — Draft, unapproved, **and now partially superseded** by the item below.
- **PRD-19's reseller model (any provider, not just Telnyx) now has its own Architecture Design: [number-provisioning-reseller-architecture-design.md](number-provisioning-reseller-architecture-design.md)** — Draft, unapproved. This is where the real data-model decisions now live (provider-agnostic order table, per-provider Channel tables kept as-is, platform credentials via `GlobalConfig`). The Implementation Spec's §2b/§2c/§2d research (Telnyx, Exotel, Plivo) is folded into this document rather than duplicated.

## 14. Rollout

Feature-flagged (`channel_provider_telnyx`), phased by complexity and risk:

| Phase | Scope | Exit criteria |
|---|---|---|
| **Phase 0 — Spike** | Confirm TeXML covers every TwiML verb NR's voice controller uses (conference bridging, status/recording callbacks); confirm Telnyx sandbox account access. | Written go/no-go on Voice scope; sandbox credentials in hand. |
| **Phase 1 — SMS** | `Channel::TelnyxSms` (or equivalent) model, inbound/outbound webhooks, delivery status, provider selector on `Sms.vue`, campaigns, **number search & provisioning (PRD-18)**. Internal/beta workspaces only, behind the feature flag. | Inbound + outbound SMS verified end-to-end; delivery-status parity confirmed against a Twilio control inbox for 1–2 weeks; at least one number provisioned end-to-end through NR (not BYO) with webhooks auto-configured. |
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
6. Is the AI Voice Agent (§6b) meant to connect to NR's own existing "AI Agents / automation" product module (Playground's product modules list), i.e. should the *same* AI Agent that handles chat/email conversations also answer phone calls through this integration — or is this a standalone ElevenLabs-branded capability unrelated to NR's own AI Agent concept? Architecturally very different answers; not yet decided.
7. Sequencing: does the AI Voice Agent (§6b) ship as part of Phase 3 (Voice) in §14, as its own phase, or independently of the Twilio-parity phases entirely, given it doesn't depend on PRD-01 through PRD-14 at all? Not yet placed in the rollout table.
8. **Partially resolved by PRD-19:** provisioning a number now definitely costs the workspace money via NR's own billing (not just informationally) — a cost-confirmation step before purchase is no longer optional, it's required by construction. What's still open: exact confirmation UX (single click vs. itemized checkout-style breakdown showing Telnyx cost + margin separately vs. one bundled price).
9. Is the Phase 1 country allowlist fixed at exactly US + India, or does the search/order UI need to be built so a third country is a config change, not a code change? Not yet decided — affects whether "US, IN" is hardcoded in the allowlist or data-driven.
10. **New, with PRD-19: what is NR's actual billing/subscription system?** This FRD has never needed to touch billing before — every other capability configures a resource the customer already owns and pays for themselves. Needs identifying (Stripe? something else?) before the Implementation Spec can specify the actual recurring-charge integration, not just describe it conceptually.
11. **New, with PRD-19: numbering margin — flat markup or percentage, and set where?** A platform-wide constant, configurable per plan tier, or per-account? Not decided. Affects whether this is a one-line config value or a real pricing-management feature.
12. **New, with PRD-19: number lifecycle on subscription lapse/cancellation.** Does NR release a purchased number back to Telnyx's inventory when the paying subscription ends, hold it for a grace period, or something else? No answer yet — this risk didn't exist under the BYO model, where the number was always the customer's own regardless of their NR subscription.
13. ~~Does this reseller sub-flow need its own Architecture Design before the Implementation Spec is finalized?~~ **Resolved 2026-09-25** — yes, and it's written: [number-provisioning-reseller-architecture-design.md](number-provisioning-reseller-architecture-design.md). Draft, unapproved — the design questions it makes (provider-agnostic order table, keep Channel tables per-provider, platform credentials via `GlobalConfig`) still need review, but the document itself is no longer missing.
14. **🚨 Blocking — narrowed to a real product decision (2026-09-24, refined 2026-09-25): does India stay in Phase 1's SMS scope at all, given Telnyx has zero SMS-capable numbers there?** Confirmed two ways — live API test, and Telnyx's own India Mobile Numbers release note (2026-09-17), which scopes the launch to voice-only. **The "maybe it's account-tier-specific" possibility is ruled out.** Three real paths, one candidate provider for (c) now checked and ruled out, one confirmed viable with a caveat:
    - **(a)** Drop India from §6a's SMS scope entirely, keep Phase 1 SMS as US-only.
    - **(b)** Keep India, but as a **Voice-only** capability under PRD-10/§6b instead of §6a.
    - **(c)** Keep India in SMS scope via a different provider. **Two candidates checked:** ~~Plivo~~ — ruled out, its own India coverage page states inbound SMS is not supported at all (outbound-only, a hard capability gap, not friction). **Exotel** — confirmed genuinely two-way SMS-capable for India, but inbound SMS requires **manually contacting an Exotel account manager to enable**, not a pure self-serve API flow (Implementation Spec §2c/§2d has the full comparison).
    
    (c)-via-Exotel is the strongest option checked so far, but "strongest" here means "the only one that isn't a hard capability gap" — it still carries an account-manager dependency that doesn't fit a fully self-serve onboarding story. **This choice now has a written ADR:** [adr-exotel-india-sms-provider.md](adr-exotel-india-sms-provider.md), Status **Proposed** (deliberately not Accepted — it's gated on this very Product decision, not a formality). This is now a Product decision, not an engineering one — needs an answer before the Implementation Spec's India-specific SMS work is worth continuing in any single direction.
15. **Is the "Feature not permitted... refer to telnyx.com/upgrade" response on the `regulatory_requirements` lookup (confirmed live, 2026-09-24) an account-tier gate that goes away on a paid/upgraded Telnyx plan, or a genuine API restriction?** Directly affects whether Open Question 14(c) above and the KYC-lookup UX improvement from the Implementation Spec (§14.7 there) are buildable at all without a Telnyx plan upgrade first.
16. **🚨 Blocking, live-tested (2026-09-24), narrowed on retry: what Telnyx account tier does a real NR customer (or NR itself, under PRD-19's reseller model) actually need for this whole feature to work?** Number reservations are tier-gated (error 10038). A real, explicitly-confirmed order attempt against an available $0-listed US number was rejected with "only 1 order allowed at your account level" (error 10039) — no charge occurred. **Retried after the account's existing order was deleted from the Telnyx dashboard — identical error, unchanged, against a different (freshly searched) number.** Deleting the prior order did not free up the quota. This is a meaningful narrowing: it reads as a genuine lifetime/plan-tier cap ("this account may place 1 order, ever, on this plan"), not a "you have one active/unfulfilled order in the queue" limit. Needs: (a) comparing against Telnyx's published plan tiers to find which one actually lifts this cap (not just "upgrade and see"), (b) re-running this same test flow on an upgraded account before treating §6a's search→order design as validated end-to-end. Confirmed correct at the request/response-shape level (per the earlier gem-source verification) but **still not confirmed to actually complete a purchase on any account tested so far — two independent attempts, same result.**

## 16. Decisions / approvals

| Decision / Gate | Owner | Date |
|---|---|---|
| **Coexist, not replace** — Telnyx is added as an additional provider option; Twilio is not removed or deprecated. Confirmed directly by the requester, not just assumed. | Product (via chat) | 2026-09-23 |
| **§6a (virtual number purchase) ships in Phase 1**, alongside SMS — not deferred to a later phase. Confirmed directly by the requester. | Product (via chat) | 2026-09-23 |
| **Purchased numbers (PRD-18/19) are reseller-model, not BYO** — NR's own Telnyx master account, marked up, billed through NR's own subscription system. Confirmed directly by the requester. This is a genuine exception to the BYO-credential pattern the rest of this FRD (and the Coexist decision above) is built on — it applies only to purchased numbers, not to SMS/WhatsApp/Voice/BYO-Telnyx generally. Open questions 10–13 (billing system, margin config, lifecycle, process gate) are not yet resolved — this decision confirms the *model*, not every detail of it. | Product (via chat) | 2026-09-23 |
| **Phase 1 country scope: US and India, admin-selectable — not a single hardcoded country.** Confirmed directly by the requester, correcting an earlier draft that hard-forced `country_code: 'US'` server-side. Consequence: Phase 1 must include a real KYC/regulatory-document submission flow for India (not deferrable), since India requires it as the normal path, not a rare edge case. | Product (via chat) | 2026-09-23 |
| **Number provisioning gets a provider-agnostic interface (service layer only), Telnyx as the first adapter behind it.** Confirmed directly by the requester, as a direct response to the two live-tested Telnyx blockers (account-tier order cap, no India SMS) — not general-purpose future-proofing. Database schema stays Telnyx-named for now; only the service layer abstracts. Design is in the [Implementation Spec §2b](telnyx-virtual-number-purchase-implementation-spec.md). This is the third structural change to stack on the original §6a design (after PRD-19's reseller model and the two live-tested blockers) and independently strengthens the case for an Architecture Design before implementation — see Implementation Spec Open Question 11. | Product (via chat) | 2026-09-24 |
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
| Auth: Account SID+Token or API Key+Secret | Twilio Account credentials | `Channel::TwilioSms` fields | Telnyx API Key (single key) | Simpler — one field, not a pair. **Exception:** purchased numbers (PRD-19) use NR's own platform Telnyx key, not a customer-entered one — see §6a. This row describes the BYO path only. |
| Number provisioning | N/A — BYO Twilio number only, never implemented | Not implemented today | Telnyx Number Search + Order API (`available_phone_numbers`, `number_orders`) | **In scope, Phase 1 (PRD-18)** — a genuinely new capability, not parity work, since Twilio-backed inboxes never had this either. See Appendix E. |

**Twilio features NR does *not* use today** (so no Telnyx parity is required): Flex, Studio, TaskRouter, Verify/2FA, Authy, Video, Sync, Serverless Functions.

**Telnyx features with no current Twilio counterpart in NR** (out of scope per Section 11): RCS, Fax API, Email API, IoT SIM/eSIM, Edge Compute (Functions/Inference/KV/SQL/Object Storage), Number Lookup, Number Reputation, Deepfake Detection, Branded Calling/STIR-SHAKEN, Virtual Cross Connects/Cloud VPN.

**What is SIP Trunking, and why does §6b need it?**

- Connects a phone system to the public telephone network (PSTN) over the internet via the SIP protocol — the modern replacement for physical analog/PRI phone lines.
- Normally lets a customer plug their own PBX, call-center platform, or UCaaS system directly into the carrier network — and NR's Twilio-parity Voice work (PRD-10) doesn't need this, since it uses the declarative TwiML/TeXML model instead (Voice API handles call logic via webhooks, no customer-owned PBX involved).
- **Correction:** an earlier draft of this document said "there's nothing for SIP trunking to plug into" in NR's architecture. That was true for PRD-10 (human-agent Voice) but wrong for the AI Voice Agent use case (§6b): ElevenLabs' Conversational AI *is* the thing SIP trunking plugs into. ElevenLabs' own integration guide confirms the connection is SIP trunking (an FQDN-type Telnyx SIP Connection pointed at `sip.rtc.elevenlabs.io`), not TeXML/Call Control.
- So: SIP trunking is in scope narrowly for §6b, and still out of scope for general customer-owned-PBX support (that remains a real non-goal — NR isn't becoming a PBX-integration platform).

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
| Local phone number (US) | $1.15 / month | $1.00 / month (list price) — **live-tested US search results actually showed $0.00/mo** for the specific numbers returned (2026-09-24); real per-number cost varies, don't treat either figure as a firm number | Directionally cheaper, exact figure varies by number |
| Toll-free number | $2.00 / month | Comparable (not itemized separately in Telnyx's public pricing) | Needs confirmation during Phase 0 spike |
| Mobile number (India) | N/A — Twilio India coverage not evaluated in this FRD | **$8.50 upfront + $8.50/month, live-confirmed (2026-09-24)** — and this number can't actually be used for SMS (see §6a's blocking finding), only voice/fax | Meaningfully more expensive than the ~$1/mo figure this FRD's "illustrative savings" language (§Appendix B intro) implicitly assumed applied everywhere — it doesn't; India is its own, much higher, price point |
| A2P 10DLC brand registration | $4 one-time | $4.50 one-time | Set by The Campaign Registry (TCR), not the provider — roughly the same either way |
| A2P 10DLC campaign registration | $10–15 / month per campaign | ~$10 / month per campaign (standard use case) + a one-time $15 vetting fee on new registrations | Roughly comparable, also TCR-driven |

**Illustrative monthly cost at NR's current usage shape** — for a workspace sending/receiving a mix of SMS and voice minutes, the biggest swing is **Voice** (~76–86% cheaper on Telnyx) and **SMS** (~47–49% cheaper); WhatsApp savings are smaller since Meta's own conversation fee is the larger cost component and is identical on both platforms. Exact savings depend on each workspace's actual message/minute volume — Section 12's per-provider cost analytics exist specifically to measure this once Telnyx inboxes are live, rather than relying on this list-rate estimate.

## Appendix C — Packages / SDKs to add

Mirrors the existing Twilio entries in `Gemfile` and `package.json` (see Section 6, PRD-02/PRD-10). No packages are removed — these are additive, same as the rest of this FRD.

| Layer | Existing Twilio package | New Telnyx package | Notes |
|---|---|---|---|
| Backend (Ruby) | `gem 'twilio-ruby'` (`Gemfile:107`, resolved `7.6.0` in `Gemfile.lock`) | `gem "telnyx", "~> 5.168.0"` — [official Ruby SDK](https://github.com/team-telnyx/telnyx-ruby) (exact Gemfile line per the gem's own README), requires **Ruby ≥ 3.2.0** | Confirm against `.ruby-version` before adding — a version floor bump would affect the whole app, not just this feature. Covers SMS/MMS/WhatsApp/Voice/Call Control/Number Management REST calls, same role `twilio-ruby` plays today. Confirmed it also covers §6a/PRD-18 directly: `client.available_phone_numbers.list(filter: {...})` (search) and `client.number_orders.create(...)` (order) are both first-class resources — no separate library needed for number provisioning. Ships typed errors (`Telnyx::Errors::APIError` + per-status subclasses), built-in retry with exponential backoff, and connection pooling out of the box — see the Implementation Spec's §2a for how these get used. |
| Frontend — browser calling (JS) | `"@twilio/voice-sdk": "^2.12.4"` (`package.json:61`) | `@telnyx/webrtc` — [official WebRTC SDK](https://www.npmjs.com/package/@telnyx/webrtc), `npm install @telnyx/webrtc` | Drop-in role-equivalent to `twilioVoiceClient.js`'s use of `@twilio/voice-sdk`'s `Device`; exposes a `TelnyxRTC` client instead. |
| Auth model difference | Twilio: JWT **Access Token** minted per-call via `Twilio::JWT::AccessToken` + `VoiceGrant` (`TokenService`) | Telnyx: authenticates via a **SIP Connection** (username/password, or a JWT created the same way) | `enterprise/app/services/voice/provider/twilio/token_service.rb` needs a Telnyx-specific counterpart — not a drop-in, since the credential shape differs (SIP Connection vs. Access Token). |

## Appendix D — AI Voice Agent (Telnyx + ElevenLabs) technical facts

Backing research for §6b, PRD-15/16/17.

- **Integration mechanism:** SIP trunking, not TeXML/Call Control. Confirmed by ElevenLabs' own Telnyx integration docs and Telnyx's release notes announcing the ElevenLabs TTS/agent integration (March 2026).
- **Telnyx-side setup:** create an FQDN-type SIP Connection; inbound routing points at `sip.rtc.elevenlabs.io` (destination format `+E.164`, TCP transport); a purchased Telnyx number is linked to that connection; outbound calls (ElevenLabs placing a call back through the trunk) use digest auth credentials on the connection.
- **ElevenLabs-side setup:** configured separately in ElevenLabs' own portal/API (their docs reference a separate SIP trunking guide) — this FRD does not yet have those exact steps, only that they exist and are required.
- **Who handles the call:** ElevenLabs' platform, entirely — inbound calls route Telnyx → ElevenLabs' origination URI; ElevenLabs is the AI brain and voice. NR is not in this call-control path at all unless PRD-17 (call visibility) is built.
- **Telnyx also ships its own competing "Voice AI Agents" product** (native, not ElevenLabs) — not what was asked for here, but worth knowing it exists as an alternative if ElevenLabs isn't a hard requirement; not evaluated further in this FRD.
- **Not confirmed:** whether ElevenLabs sends call data/transcripts to a webhook NR could ingest (their SIP trunking docs don't cover this — would need ElevenLabs' separate Conversational AI API/webhook docs, relevant to PRD-17/Open Question 6).

## Appendix E — Number search & provisioning process (PRD-18)

Backing research and full process detail for PRD-18. This is a genuinely new capability — Twilio-backed inboxes never had it (BYO-only, unchanged) — not a parity item.

**API surface (Telnyx REST, v2):**

| Step | Endpoint | Purpose |
|---|---|---|
| 1. Search | `GET /v2/available_phone_numbers` | Find purchasable numbers. `country_code` is required; `locality` (city), `administrative_area` (state/region), and `features` (sms/voice/mms/fax capability) narrow results. |
| 2. Reserve (new, resolves the staleness risk below) | `POST /v2/number_reservations` | Holds a specific searched number exclusively for **30 minutes**. Extendable another 30 minutes via `POST /v2/number_reservations/{id}/actions/extend`. Confirmed via Telnyx's own docs — the search API's own getting-started guide explicitly calls this out as the step between search and order. |
| 3. Order | `POST /v2/number_orders` | Places an order for one or more numbers **returned by a prior search** — you can't order an arbitrary number string, only ones the search API just returned (or reserved). |
| 4. Requirements (conditional) | Regulatory requirement submission, surfaced via the order's `requirements` array | Only for number types/countries that need it (see below) — submitted *after* the order exists, not before. |
| 5. Status | `GET /number_order_phone_numbers`, or Number Order Notification webhooks | Tells the integrator when a number transitions from pending to active (or fails/is cancelled). |

**SDK check:** the `telnyx` gem (Appendix C) covers the confirmed calls directly as first-class resources — `client.available_phone_numbers.list(filter: { country_code:, ... })` for step 1, `client.number_orders.create(phone_numbers: [...])` for step 3. Confirmed against the gem's own README examples. The reservation call (step 2) hasn't had its exact gem method name checked yet — same "verify before coding" treatment as the other not-yet-confirmed calls in the Implementation Spec. No extra library needed beyond the `telnyx` gem either way; NR's backend service for PRD-18 is a thin wrapper around these calls plus the requirements/status handling, same shape as every other `Voice::Provider::Telnyx::*` / `Twilio::*` service in this codebase.

**Full lifecycle (updated to include reservation):**
1. Admin enters search criteria (country required; area code/city optional) → NR calls the search endpoint → shows results with number type and whether each one carries regulatory requirements.
2. Admin picks a number → NR reserves it (30-minute exclusive hold) — this is what makes "someone else bought it while you were filling out the form" a non-issue for the normal case, rather than something the UI just has to apologize for after the fact.
3. Admin confirms (cost-confirmation step, Open Question 8) → NR places the order against the reserved number.
4. Order enters **`pending`**. If the number type/country has no regulatory requirements (commonly: US local numbers), it activates in seconds — no further action.
5. If it does have requirements (India, always), the order carries a substatus per number: `requirement-info-pending` (nothing submitted yet) → `requirement-info-under-review` (submitted, awaiting Telnyx's vetting) → either `approved` (proceeds to activation) or `requirement-info-exception` (rejected, needs correction and resubmission). There's a submission **deadline**; miss it and the order auto-cancels. If the admin's KYC document flow takes longer than 30 minutes from reservation, the reservation needs the extend call — the reservation and the requirements deadline are two separate timers, not the same one.
6. The number reaches a terminal state — `success` (activated) or `failure` — via its own `status` field. **Correction (confirmed against the gem's real source):** "cancelled" is not a value of that `status` field at all; it lives on a separate `requirements_status` field instead (which also carries the pending/under-review/rejected states from step 5). An earlier draft of this FRD implied a single unified "order status" that included cancelled — that's not how Telnyx actually models it, per the Implementation Spec's data-model section.
7. On `success`, PRD-06's existing webhook auto-configuration service runs against the newly-active number — same as it would for a BYO number today.

**What this means for Phase 1 (confirmed: US + India, §16):** these are two genuinely different flows, not one flow with a country dropdown bolted on. A US number is a fast, synchronous-feeling path — search, pick, done, active in seconds. An India number always goes through KYC — the admin must supply an address + ID and select one of the four authorized telecom districts (Mumbai City, Gurugram, Noida, Bangalore), then wait on Telnyx's review — a multi-step, possibly multi-day, document-upload-and-status-tracking experience that doesn't exist anywhere else in NR's product today. Phase 1 has to build both, not just the happy path.

**India-specific detail:** Telnyx's own India documentation describes KYC as address + valid ID (national ID, passport, or local equivalent), and geographic/mobile numbers are only available tied to one of the four authorized telecom districts — not any Indian address. NR's district-selection UI (search step) needs to constrain to those four, not offer a free-text city field the way US locality search can.

**Sources:** [Telnyx Products](https://telnyx.com/products) · [Telnyx Pricing](https://telnyx.com/pricing) · [Telnyx WhatsApp Pricing](https://telnyx.com/pricing/whatsapp) · [Telnyx 10DLC Fees](https://support.telnyx.com/en/articles/5634625-10dlc-fees-and-charges) · [Telnyx vs Twilio comparison](https://www.courier.com/integrations/compare/telnyx-vs-twilio) · [Telnyx TeXML vs TwiML](https://telnyx.com/telnyx-texml-vs-twilio-twiml) · [Telnyx SMS API](https://telnyx.com/products/sms-api) · [Telnyx WhatsApp quickstart](https://developers.telnyx.com/docs/messaging/whatsapp/quickstart) · [Telnyx Verify API pricing](https://telnyx.com/pricing/verify-api) · [Telnyx Ruby SDK](https://github.com/team-telnyx/telnyx-ruby) · [Telnyx WebRTC JS SDK](https://www.npmjs.com/package/@telnyx/webrtc) · [Twilio Pricing](https://www.twilio.com/en-us/pricing) · [Twilio SMS Pricing (US)](https://www.twilio.com/en-us/sms/pricing/us) · [Twilio Pricing Breakdown 2026](https://automationatlas.io/answers/twilio-pricing-explained-2026/) · [ElevenLabs ↔ Telnyx integration](https://elevenlabs.io/agents/integrations/telnyx) · [ElevenLabs Telnyx SIP trunking docs](https://elevenlabs.io/docs/conversational-ai/phone-numbers/telephony/telnyx) · [Telnyx ElevenLabs TTS integration release note](https://telnyx.com/release-notes/tts-neural-voices-elevenlabs-integration) · [Telnyx native Voice AI Agents](https://telnyx.com/products/voice-ai-agents) · [Telnyx available phone numbers API](https://developers.telnyx.com/api/numbers/list-available-phone-numbers) · [Telnyx number orders lifecycle](https://developers.telnyx.com/docs/numbers/phone-numbers/number-orders) · [Telnyx Ruby gem on RubyGems](https://rubygems.org/gems/telnyx) · [Telnyx India mobile numbers release note](https://telnyx.com/release-notes/india-mobile-numbers) · [Telnyx country-specific requirements/ToS](https://telnyx.com/country-specific-requirements-terms-and-conditions-of-service) · [Telnyx numbers getting-started guide](https://developers.telnyx.com/docs/numbers/phone-numbers/getting-started) · [Telnyx number reservations](https://developers.telnyx.com/docs/numbers/phone-numbers/number-reservations)
