# Exotel Pricing Research — Virtual Numbers, SMS, Voice

> Notion note: same publishing blocker as the other Telnyx/reseller docs — this workspace has used all its free blocks and needs a plan upgrade before new Notion pages can be created. This lives in the repo instead.

| Field | Value |
|---|---|
| Researched | 2026-09-28 |
| Purpose | Feed real cost numbers into the reseller margin/billing design (PRD-19) before further build work on `feature/phone-reseller` |
| Related | [adr-exotel-india-sms-provider.md](adr-exotel-india-sms-provider.md) · [telnyx-twilio-parity-frd.md](telnyx-twilio-parity-frd.md) Appendix B · [number-provisioning-vendor-findings-and-open-questions.md](number-provisioning-vendor-findings-and-open-questions.md) |

Every figure below is labeled by confidence, per this project's "do not guess" rule — Exotel does not publish a full public rate card, so several numbers below are secondary-source estimates, not confirmed facts. Treat anything marked **UNCONFIRMED** as a number to verify with Exotel Sales before it's used in a real billing calculation, not as ground truth.

## 1. Virtual number (ExoPhone) rental — CONFIRMED, official docs

Source: [Purchase ExoPhone](https://developer.exotel.com/docs/exophones/api-reference/purchase-number) — the official API reference's example response.

- **₹499.00 / month**, field name `rental_price`, currency `INR`, in the worked example for a purchased number.
- The **search** endpoint ([Available ExoPhones](https://developer.exotel.com/docs/exophones/api-reference/available-numbers)) also returns a `rental_price` field per candidate number — meaning **rental price can vary by number**, not a single flat rate. Its example response shows `"0.000000"`, which reads as a placeholder value in the docs, not a real price — don't treat it as "some numbers are free."
- Practical implication for the `NumberProvisioning::ExotelProvider#search` response shape: capture `rental_price` per result, the same way the wholesale cost needs to flow through for Telnyx — this is the number `provider_cost_cents` on `NumberProvisioning::Order` should be populated from.

## 2. Number types available (India)

Source: [Number Types & Virtual Numbers FAQ](https://developer.exotel.com/docs/faqs/number-types) (official docs).

| Type | Format | Use case |
|---|---|---|
| Landline DID | `080-XXXXXXX` (city STD code) | Local presence, inbound IVR |
| Mobile Virtual Number | `9XX-XXXXXXX` | Two-way SMS/voice, number masking |
| Toll-Free | `1800-XXX-XXXX` | Inbound-heavy support |
| Vanity | `1800-XXX-1234` | Marketing/brand recall |

The docs state toll-free numbers carry **higher per-minute inbound charges** than DID numbers (the business pays for all inbound minutes on toll-free), but don't give a number — see §4.

**Country coverage correction**: the `AvailablePhoneNumbers` API path takes an `iso_country_code`, and its examples list **`IN`, `MY`, `SG`** — India, Malaysia, and Singapore. Every doc in this thread so far (FRD, ADR, architecture design) treated Exotel as India-only. That may still be right for this project's scope, but it isn't a platform limitation — worth a note if Southeast Asia ever comes up.

## 3. SMS pricing — PARTIALLY CONFIRMED

Source: [SMS Pricing](https://developer.exotel.com/docs/sms-support/sms-pricing) (official docs).

**What the official docs confirm:**
- Billing model is per-message, tiered by monthly volume: ≤10,000 (standard rate), 10,001–100,000 (volume discount), 100,001–1,000,000 (enterprise tier), 1,000,000+ (custom). No rupee amount is given for any tier — the docs explicitly defer to "Exotel Sales" or the account dashboard for actual rates.
- Rate also depends on SMS type (transactional / promotional / OTP), message length (multi-part costs more), and encoding (Unicode costs more per part).
- **Not charged**: failed pre-submission messages, DND-blocked promotional SMS, DLT-rejected messages.
- **No inbound SMS pricing is mentioned anywhere in the official docs** — this is a real gap, not an oversight in my research. See §5.

**UNCONFIRMED, secondary sources only**: third-party aggregator pages (CloudTalk, DialNexa — not Exotel) cite **~₹0.18 per SMS at the 100,000+ volume tier**. This number does not appear on any exotel.com or developer.exotel.com page I could find — treat it as a rough ballpark for modeling, not a number to bill against.

## 4. Voice call pricing — UNCONFIRMED, no official source found

I could not find a current official Exotel page publishing per-minute call rates (the pricing pages gate this behind "contact sales" / a dashboard login). Secondary-source figures being circulated (CloudTalk blog, industry benchmark blogs) cite, as historical/estimated numbers:

- Local incoming (DID): **~₹0.40/min**
- Inter-circle incoming: **~₹0.75/min**
- Toll-free inbound: **~₹1.20–2.50/min** (industry-benchmark estimate, not Exotel-specific)

None of these are confirmed against an official Exotel source. Given this project's number-provisioning scope is SMS-first (§6a), this matters less right now than §1 and §3, but flagging it since voice cost will matter if §6b (AI Voice Agent) gets re-scoped to route India through Exotel per the vendor-findings doc's Open Question 1.

## 5. Inbound SMS — still genuinely unknown

This is the most important gap for PRD-19's billing design. The ADR already flags that inbound SMS requires an Exotel account-manager conversation to enable at all (not self-serve) — this research adds that **the price for it isn't published either**, on top of it not being self-serve. Both facts point the same direction: inbound SMS on Exotel needs a real sales conversation before it can be relied on for a Phase 1 launch, not just an API integration effort. This maps directly onto the ADR's existing Follow-up item #5 ("identify who owns starting the Exotel account-manager conversation") — that conversation now also needs to resolve pricing, not just enablement.

## 6. The "Business Phone System" plans are a different product — don't reuse these numbers for reseller costing

Source: [exotel.com/pricing/business-phone-system](https://exotel.com/pricing/business-phone-system/) (official page).

| Plan | Price | Validity | Included rental credit | Credits | Virtual numbers | Agents |
|---|---|---|---|---|---|---|
| Dabbler | ₹9,999 | 5 months | ₹4,999 | 5,000 | 1 | 3 |
| Believer | ₹19,999 | 11 months | ₹10,499 | 9,500 | 2 | 6 |
| Influencer | ₹49,499 | 11 months | ₹10,499 | 39,000 | 10 | Unlimited |

**This is a bundled, seat-based cloud-telephony/IVR product** (call center seats, agents, bundled credits) — not the wholesale, pay-as-you-go API pricing a reseller needs to compute `provider_cost_cents` and a margin on top. Under PRD-19's reseller model, NR needs the raw per-number/per-message wholesale rate (§1 and §3), not a bundled plan price. Including this table only so nobody later mistakes "Believer plan = ₹19,999" for "a number costs ₹19,999" — it doesn't map that way.

## 7. WhatsApp pricing (bonus — not asked for, but relevant to FRD/ADR open questions)

Same source as §6, since India WhatsApp Business Verification is already a known gap (per the vendor-findings doc):

| Conversation type | Price |
|---|---|
| Marketing | ₹0.86 |
| Utility | ₹0.115 |
| Authentication | ₹0.115 |
| Authentication (international) | ₹2.30 |
| Service | Free |
| + Exotel message fee | ₹0.06 |

## 8. What this means for the reseller/billing design

- `NumberProvisioning::ExotelProvider#search` should capture the per-number `rental_price` from the API response into `provider_cost_cents` on `NumberProvisioning::Order` — the field already exists in the schema, it just isn't populated from a real, confirmed source yet. This is now confirmed real, not a guess.
- SMS margin math cannot be finalized yet — the ~₹0.18/SMS figure is unconfirmed and inbound SMS has no published price at all. `Enterprise::NumberProvisioning::OrderBillingService`'s `margin_cents: 0` stub should stay stubbed until Exotel Sales confirms real per-SMS rates, not just until the API integration is built.
- The account-manager conversation the ADR already calls for (Follow-up #5) should now explicitly ask for: (a) inbound SMS enablement, (b) inbound SMS pricing, (c) confirmation of the ₹499/month ExoPhone rental figure as current, not just the example in the docs.

## Sources

- [Purchase ExoPhone — API Reference](https://developer.exotel.com/docs/exophones/api-reference/purchase-number)
- [Available ExoPhones — API Reference](https://developer.exotel.com/docs/exophones/api-reference/available-numbers)
- [Number Types & Virtual Numbers FAQ](https://developer.exotel.com/docs/faqs/number-types)
- [SMS Pricing — Exotel Developer Docs](https://developer.exotel.com/docs/sms-support/sms-pricing)
- [Exotel Pricing — Business Phone System](https://exotel.com/pricing/business-phone-system/)
- [Exotel Plans & Pricing: Full Guide for 2026 — CloudTalk](https://www.cloudtalk.io/blog/exotel-pricing/) (secondary, unconfirmed figures only)
- [Exotel Pricing: Complete Guide for Indian Businesses 2026 — DialNexa](https://dialnexa.com/blogs/exotel-pricing/) (secondary, unconfirmed figures only)
