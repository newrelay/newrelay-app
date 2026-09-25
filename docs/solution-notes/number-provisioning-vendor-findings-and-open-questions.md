# Number Provisioning — Vendor Findings, Issues, and Open Questions

> **Status:** Draft · **Owner:** TBD (Product/Eng) · **Initiative:** India + US virtual number reseller launch · **Related docs:** [telnyx-twilio-parity-frd.md](telnyx-twilio-parity-frd.md) (source FRD, §6a/§6b/PRD-18/19) · [telnyx-virtual-number-purchase-implementation-spec.md](telnyx-virtual-number-purchase-implementation-spec.md) (§2b provider interface, §2c/§2d Exotel/Plivo research) · [adr-exotel-india-sms-provider.md](adr-exotel-india-sms-provider.md) (Exotel-as-SMS-adapter decision) · [number-provisioning-reseller-architecture-design.md](number-provisioning-reseller-architecture-design.md) (architecture) · [telnyx-voice-architecture-design.md](telnyx-voice-architecture-design.md) (PRD-10 Voice, out of scope here) · **Branch:** `feature/phone-reseller`
>
> **Why this doc exists separately:** the four docs above already cover the Telnyx-parity FRD, the purchase implementation spec, the Exotel ADR, and the architecture design. This doc captures a distinct research pass — live vendor outreach (a real Exotel sales call), independent review/complaint research across four vendors, live Exotel API testing beyond what the ADR covered, and the first working `NumberProvisioning` code — that isn't folded into those documents yet. Treat this as input to update them, not a replacement for any of them.

## 1. Vendor issue research (independent reviews, not vendor marketing)

Reviewed public complaint/review data (Trustpilot, G2, Capterra, ComplaintsBoard, Glassdoor) for every provider under consideration, specifically to find failure patterns marketing pages don't mention. Not exhaustive — one research pass each, same discipline the ADR used for Exotel/Plivo.

| Vendor | Core risk pattern found | Independent verification |
|---|---|---|
| **Plivo** | Accounts deactivated without warning or explanation; accounts flagged/blocked during routine audits with no clear reason; surprise billing for messages that never delivered; no formal uptime SLA | Capterra, GetVoIP, Trustpilot reviews; StatusGator: 5,154+ recorded outages over 11 years |
| **Exotel** | Slow support turnaround — reported cases of ~1 week per ticket (2 days to acknowledge, 2 days to diagnose, 3 to resolve); several Trustpilot reviews describe support as responsive pre-payment, unresponsive after | G2, Trustpilot, SelectHub reviews |
| **Telnyx** | Same account-flagging/deactivation pattern as Plivo (accounts suspended within minutes over sub-$1 negative balances, repeated flag/unblock cycles); KYC process reported "completely broken" for some users; mid-2026 reliability wobbles incl. a Cloudflare-linked outage | Trustpilot, ComplaintsBoard — but weighed against a strong **4.7★ / 600+ G2 reviews** aggregate, suggesting these are a vocal minority, not the norm |
| **Voicelink** (Elision Group, `voicelink.co.in`) | No independent customer review platform has a populated review page for the actual product (SoftwareSuggest: zero reviews); one Glassdoor **employee** review alleges the parent company "has done fraud with both employees and clients" — unverified, single-source, and from a disgruntled-employee-skewed platform, not a documented customer incident | Glassdoor (Elision TechnoLab, 3.7★/41 reviews aggregate), G2 seller page. **Correction:** an initial check conflated this vendor with an unrelated US company also named "VoiceLink Communications" (a hosted-PBX-for-small-business product, 4 G2 reviews) — that data does **not** apply to Elision's product and was discarded once the name collision was found |

**Net read:** none of the four are clean. Plivo's pattern (unexplained deactivation) is the most disqualifying for a customer-facing number. Telnyx's similar pattern is offset by a much larger, mostly-positive review base. Exotel's risk is slow support, not capability loss. Voicelink's risk is an absence of independent verification plus one unverified allegation — a different risk shape than "documented failures," not necessarily safer.

**Practical mitigation regardless of vendor chosen:** don't single-source a region's numbering through one provider without a failover path; keep only a small pre-paid balance during any trial period so an account-flagging incident can't cascade into an outage with no warning.

## 2. SIP trunk coverage — now confirmed per-provider, per-region

This directly extends [telnyx-twilio-parity-frd.md §6b](telnyx-twilio-parity-frd.md) (Telnyx + ElevenLabs SIP trunking, confirmed there) with the Exotel side, confirmed today via **direct vendor contact** (Exotel sales rep, Mohammed Fazil, phone call 2026-09-25):

| Provider | India SIP trunk | US SIP trunk |
|---|---|---|
| **Telnyx** | Not applicable to voice-agent use — Telnyx's India numbers (launched 2026-09-17) are voice-only in the basic-calling sense, per its own release note (already documented in the FRD) | **Confirmed working** (FRD §6b, ElevenLabs integration docs) |
| **Exotel** | **Confirmed working**, directly by an Exotel sales rep on a call — this is the first non-documentation confirmation for Exotel's SIP trunk claim | **Confirmed NOT available** — same call, same rep |

**Consequence:** neither provider covers both regions for an AI-voice-agent (ElevenLabs-via-SIP) use case. This is now a **hard constraint**, not a preference: India-region AI voice agent work must route through Exotel's SIP trunk; US-region AI voice agent work must route through Telnyx's. A single-provider SIP strategy for both regions does not exist between these two vendors.

**Not yet confirmed:** whether Exotel's SIP trunk claim for India holds the same "ElevenLabs is a documented, first-class integration" bar Telnyx has (Exotel does list ElevenLabs among 40+ integrations per its marketing site, and a dedicated `developer.exotel.com/docs/agentstream/elevenlabs-integration` guide exists — closer to Telnyx's level of documentation than initially assumed, but not live-tested end-to-end the way Telnyx's mechanics were per the Implementation Spec).

## 3. WhatsApp Business verification — a real failure mode, not just a missing feature

**Finding:** attempting to register a WhatsApp Business Account (WABA) on a Telnyx India number is a real risk of **outright verification failure**, not just "no SMS today." Meta's WhatsApp Business Platform requires SMS-or-voice OTP verification, and explicitly distrusts pure-VoIP-type numbers as an anti-abuse measure (Telnyx's own docs: a number failing the "active and able to receive calls or SMS (mobile numbers only)" check throws `"Calling APIs cannot be enabled for this phone number."`). Since Telnyx's India numbers are voice-only, this compounds the existing India-SMS gap (ADR) into an India-WhatsApp gap too.

**Consequence for the provider-routing design:** any India inbox needing WhatsApp Business must be provisioned on an Exotel (or Voicelink) number, never a Telnyx one — this should be an explicit constraint in the routing logic (§6 below), not just an SMS-specific one.

## 4. Outbound call mechanics — Exotel's two-leg model

Exotel's `Calls/connect` API is **two-legged**: it rings the `From` party first, and only bridges to the destination once that leg answers. Confirmed against Exotel's own developer docs (`POST /v1/Accounts/<sid>/Calls/connect`, `Url` param points to a Call Flow/App).

**Why this matters here:** for an AI voice agent (ElevenLabs as the `From` leg), this is transparent. For a **human agent** clicking "call" from inside NR, this means the agent's own leg rings first, then Exotel bridges to the customer — an extra step versus a single-leg direct dial. Worth surfacing in PRD-10/Voice UX discussions if human-agent outbound calling is ever built on Exotel specifically (Telnyx's `Call Control` API is single-leg by contrast, already implicit in the FRD's TeXML-based design).

## 5. Exotel technical limits and latency (concrete numbers, for capacity/UX planning)

| Metric | Value | Source |
|---|---|---|
| Call setup latency (`Calls/connect`, synchronous) | ~700ms average, ~1.1s p95, **up to 30s worst case** — the API blocks on call origination before responding | Exotel support docs |
| Real-time media latency (AgentStream, WebSocket-based voice streaming) | Sub-20ms claimed, **<250ms end-to-end guaranteed** — a different metric than call-setup latency, relevant to AI-agent conversational responsiveness | Exotel product docs/blog |
| API rate limit | 100 requests/minute default, raisable on request | Exotel docs |
| Concurrent call limit | Account-specific, not published; exceeding it queues or rejects with busy signal / `Streaming_call_throttled` | Exotel docs |
| Webhook delivery | Retries on non-200 response — **handlers must be idempotent**, or duplicate call/SMS events will occur | Exotel docs |
| Smart-routing/Passthru response window | 2–3 seconds, or the call falls through to a timeout path | Exotel docs |

**Open item:** the 100 rpm default rate limit's scope (per master account vs. per sub-account) is unconfirmed — directly relevant to the reseller/white-label model in §7, since one high-volume customer shouldn't be able to throttle every other tenant sharing the master account.

## 6. Live Exotel API findings beyond the ADR's scope

The ADR ([adr-exotel-india-sms-provider.md](adr-exotel-india-sms-provider.md)) confirmed Exotel is two-way SMS-capable but gated behind manual account-manager enablement. Live-testing the actual `AvailablePhoneNumbers` search endpoint this session narrows that further:

- `GET /v2_beta/Accounts/{sid}/AvailablePhoneNumbers/IN/TollFree` → every result `capabilities.sms: false`. Expected — India toll-free numbers are structurally voice-only across all carriers, not an Exotel gap.
- `GET /v2_beta/Accounts/{sid}/AvailablePhoneNumbers/IN/Mobile` → **every one of ~70 results in this test also showed `capabilities.sms: false`**, despite being `number_type: "Mobile"`. This means the self-serve, no-account-manager-required number pool is voice-only in practice, reinforcing (with a concrete API symptom) the ADR's finding that inbound SMS is not available through ordinary self-serve provisioning at all — it requires the account-manager step regardless of which number type is searched.
- **Real pricing data point** (not previously in any doc): a Karnataka-circle Mobile ExoPhone costs **₹999/month rental** (a few listed at ₹1199), **₹0 one-time/setup cost**, and **₹1.30/min incoming** (some numbers ₹0.50/min, a few ₹0.00/min) — billed on a 60-second pulse. Useful as a real reference point for the ADR's and Architecture Design's currently-unfilled India pricing figures.
- **Not yet tried:** the `IncomingSMS=true` query filter documented on this same endpoint — would confirm whether *any* self-serve SMS-capable India number exists at all, or whether the filter simply returns empty. Worth running before the account-manager conversation (ADR Follow-up item 5) to know exactly what's being asked for.

## 7. White-label / reseller provisioning — provider comparison

Directly relevant to PRD-19's reseller model. Compared how each provider actually supports "NR holds the master account, provisions numbers per end-customer, applies its own markup, customer self-connects":

| Provider | Reseller/white-label feature | Self-serve number connect | Margin/pricing control |
|---|---|---|---|
| **Telnyx** | **Managed Accounts** — purpose-built: NR is the "manager account," each customer gets a sub-account, and **pricing is inherited from the manager and hidden from the sub-account** (up to 1,000 managed sub-accounts by default) | **Embedded Number Search & Provisioning API** — customer searches/picks/activates a number inside NR's own UI, no manual work | Full — pricing hidden from the customer by design |
| **Twilio** | Subaccounts + "ISV" architecture — same underlying idea, but a **pattern NR would build**, not a productized "hide the price" feature like Telnyx ships | Doable via API, more engineering effort to replicate Telnyx's out-of-the-box behavior | Full, but more build cost |
| **Voicelink** | Explicit "Reseller plan" marketed directly at AI SaaS/voicebot platforms — "multiuser to manage and bill clients," "bulk DID resale," centralized client-activity view | **Not self-serve** — sales-quote, manual onboarding (24–48h per Voicelink's own FAQ) | Unclear — no public pricing to calculate against |
| **Exotel** | No dedicated reseller/white-label product found during this research pass | Not self-serve | Sales-quote |

**Implication:** if the reseller/white-label experience needs to be genuinely self-serve (customer picks a number inside NR with zero manual steps on NR's side), **Telnyx's Managed Accounts is the only checked option that ships this out of the box.** Exotel — the confirmed India SMS/SIP provider — has no equivalent; India reseller provisioning through Exotel would need NR to build its own sub-account/margin layer on top, mirroring the Twilio-ISV pattern rather than getting it for free.

## 8. `NumberProvisioning` wrapper — code status (this session)

Built on `feature/phone-reseller`, ahead of the Architecture Design's own illustrative Exotel code (which is explicitly marked "NOT yet verified" in that doc):

- `app/services/number_provisioning/provider.rb` — the interface (`search`, `order`), matching the shape already agreed in [number-provisioning-reseller-architecture-design.md](number-provisioning-reseller-architecture-design.md).
- `app/services/number_provisioning/telnyx_provider.rb` — calls Telnyx's documented `available_phone_numbers` / `number_orders` REST endpoints.
- `app/services/number_provisioning/exotel_provider.rb` — calls the **exact Exotel endpoints verified live** in §6 above (`AvailablePhoneNumbers/{country}/{type}`, `IncomingPhoneNumbers`), not just documentation-derived like the Architecture Design's draft.
- `app/services/number_provisioning.rb` — resolver: `NumberProvisioning.for(account:, country_code:)` routes `IN` → `ExotelProvider`, everything else → `TelnyxProvider`.
- Credentials follow the existing `account.hooks.find_by(app_id: ..., status: 'enabled').settings` pattern already live in `app/controllers/api/v1/accounts/integrations/exotel_controller.rb` (the existing, working Exotel voice-agent controller — OpenAI + ElevenLabs today), not a new credential-storage mechanism.

**Deliberately not implemented yet** (scope-matched to what's actually verified, not the Architecture Design's fuller interface): `reserve`, `lookup_requirements`, `submit_requirements`, `configure_webhook`. Adding these now would mean guessing at unverified API shapes — same discipline the ADR applies to its own "not yet confirmed" list.

**Known gap, not yet fixed:** `search()` currently returns each provider's **raw, unnormalized** response — Exotel returns `rental_price`, Telnyx returns `cost_information.monthly_cost`. A caller has to know which provider answered to read the price, which undercuts the point of a provider-agnostic interface. This is exactly where reseller markup logic needs to hook in, so it should be normalized (e.g. a common `{ phone_number:, monthly_price:, currency:, capabilities: }` shape) before any billing/markup work is built on top.

## 9. New open questions (additions to the FRD/ADR's existing lists, not replacements)

1. **Does the India-region AI Voice Agent (§6b in the FRD, currently scoped to Telnyx + ElevenLabs) need to be re-scoped to Exotel + ElevenLabs instead**, given Exotel's SIP trunk is confirmed working for India while Telnyx's India numbers are voice-only-in-the-basic-calling-sense? This wasn't a live option when §6b was written — needs a decision on whether §6b becomes provider-routed (India→Exotel, US→Telnyx) the same way §6a's SMS/number provisioning already is.
2. **Does the existing `app/controllers/.../exotel_controller.rb` (record-and-respond IVR pattern, not SIP) get replaced by a SIP-trunk-based integration, or do both coexist** — one for basic/cheap voice IVR, one for lower-latency AI conversation? Not decided; the two are architecturally different (webhook/record-based vs. SIP/streaming-based).
3. **Is the Voicelink "Reseller plan" worth a real sales conversation**, given it's the only vendor found with a reseller offering explicitly marketed at this exact use case (AI SaaS/voicebot platforms) — even though it's not self-serve? Not evaluated against Telnyx's Managed Accounts on cost, only on feature shape.
4. **Should `NumberProvisioning::Provider#search` be changed now to return a normalized price shape**, before any more adapters or callers are built on top of the current raw-passthrough behavior (§8)? Flagged as a real gap, not yet decided whether to fix immediately or defer until billing/markup work is actually scoped.
5. **Does Exotel's confirmed India SIP trunk change the Implementation Spec's Open Question 14 answer** (drop India SMS scope vs. voice-only vs. Exotel-adapter) — since Exotel can now plausibly serve both India SMS (pending account-manager enablement) *and* India voice/AI-agent needs through the same vendor relationship, strengthening the case for standing up that Exotel relationship once rather than evaluating it per-capability.

## Sources

[Plivo Capterra reviews](https://www.capterra.com/p/164618/Plivo/reviews/) · [Plivo GetVoIP reviews](https://getvoip.com/reviews/plivo/) · [Plivo StatusGator](https://statusgator.com/services/plivo) · [Exotel G2 reviews](https://www.g2.com/products/exotel-customer-communication-platform/reviews) · [Exotel Trustpilot](https://www.trustpilot.com/review/exotel.com) · [Telnyx Trustpilot](https://www.trustpilot.com/review/telnyx.com) · [Telnyx ComplaintsBoard](https://www.complaintsboard.com/telnyx-b164809) · [Voicelink G2 reviews](https://www.g2.com/products/voicelink/reviews) · [voicelink.co.in](https://voicelink.co.in/) · [Exotel AgentStream + ElevenLabs integration guide](https://developer.exotel.com/docs/agentstream/elevenlabs-integration) · [Exotel outbound Connect API](https://developer.exotel.com/docs/voice-v1/api-reference/outgoing-call-to-flow) · [Exotel Connect API response time](https://support.exotel.com/support/solutions/articles/3000083306-why-does-the-response-time-of-connect-api-vary-) · [Exotel sub-800ms latency blog](https://exotel.com/blog/achieve-low-latency-voice-ai-exotel/) · [Exotel AgentStream product page](https://exotel.com/products/agentstream-voice-streaming/) · [Exotel Voice API FAQs](https://developer.exotel.com/docs/faqs/voice-faqs) · [Exotel Available ExoPhones API](https://developer.exotel.com/docs/exophones/api-reference/available-numbers) · [Exotel Purchase ExoPhone API](https://developer.exotel.com/docs/exophones/api-reference/purchase-number) · [Telnyx Managed Accounts](https://telnyx.com/release-notes/managed-accounts) · [Telnyx Embedded Number Search](https://telnyx.com/use-cases/embedded-number-search-provisioning) · [Twilio ISV subaccounts guide](https://www.twilio.com/en-us/blog/isv-getting-started-with-twilio) · [Telnyx WhatsApp Business Calling requirements](https://support.telnyx.com/en/articles/14668631-enabling-whatsapp-business-calling-on-telnyx-numbers) · [GlobCall — virtual numbers for WhatsApp](https://globcall.com/blog/virtual-business-numbers-for-whatsapp-how-they-work-and-when-to-use-them) · [Telnyx India mobile numbers release note](https://telnyx.com/release-notes/india-mobile-numbers) · [Telnyx available phone numbers API](https://developers.telnyx.com/api-reference/phone-number-search/list-available-phone-numbers)

## Approval

| Gate | Who | Date |
|---|---|---|
| Reviewed against source FRD/ADR/Architecture Design for conflicts | TBD | TBD |
| Open questions (§9) triaged into FRD/ADR updates | TBD | TBD |
