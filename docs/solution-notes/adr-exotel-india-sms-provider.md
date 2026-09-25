# ADR — Exotel as the Second Number-Provisioning Adapter (India SMS)

> Notion note: same publishing blocker as the other Telnyx/reseller docs — this workspace has used all its free blocks and needs a plan upgrade before new Notion pages can be created. This is normally logged as an ADR plus a Decision Log row per NR's process; the Decision Log entry doesn't exist yet for the same reason.

| Field | Value |
|---|---|
| Status | **Proposed** — not Accepted. See "Why not Accepted yet" below; this is a real, load-bearing gate, not a formality. |
| Date | 2026-09-25 |
| Owner | TBD |
| Architecture Design | [number-provisioning-reseller-architecture-design.md](number-provisioning-reseller-architecture-design.md) §12 (flagged this ADR as required) |
| Source PRD | [telnyx-twilio-parity-frd.md](telnyx-twilio-parity-frd.md) §6a, PRD-19, Open Question 14 |
| Supersedes | None |

## Decision

Adopt **Exotel** as the second `NumberProvisioning::Provider` adapter, specifically to serve India, once Product confirms India stays in Phase 1's SMS scope at all (FRD Open Question 14). Telnyx remains the adapter for US. **Plivo was evaluated and rejected** — it is not an alternative under reconsideration, it is a closed line of inquiry.

## Context

PRD-19 committed NR to a reseller model where NR itself holds provider accounts and resells numbers to customers. Live testing found Telnyx has zero SMS-capable numbers in India — confirmed two ways: empirically (all five phone-number types, explicit `features[]=sms` filter, every result "no coverage") and against Telnyx's own product announcement (its India Mobile Numbers release note, 2026-09-17, scopes the feature to voice-only). That rules out Telnyx for India SMS regardless of account tier or plan upgrade — it isn't a limitation of the account tested, it's the product as shipped.

Two real alternatives were evaluated on their own merits, not assumed:
- **Plivo** — real CPaaS presence in India, a REST API shape that would have fit the existing `Provider` interface cleanly (explicit `sms_enabled`/`voice_enabled` booleans in search results, arguably better-designed than Telnyx's `features` array). Its own India SMS coverage page states **"Inbound SMS: Not Supported"** — outbound-only. This is a hard capability gap, not friction: no amount of API integration effort makes Plivo receive an SMS it structurally cannot receive.
- **Exotel** — India-based CPaaS, confirmed genuinely two-way SMS-capable (dedicated developer docs for inbound webhooks, real payload fields `From`/`Body`/`SmsSid`). The one real caveat: Exotel's own docs state inbound SMS requires **contacting an Exotel account manager to enable** — not a pure self-serve API flow.

## Options considered

**A. Exotel** (chosen)
- Benefit: the only checked candidate that actually delivers two-way SMS in India.
- Cost: manual account-manager enablement step breaks a fully self-serve onboarding story; reservation concept, DLT registration API shape, and regional endpoint choice (Singapore vs. Mumbai cluster) are all still unconfirmed — this adapter has had one research pass, not the live-testing rigor Telnyx got.

**B. Plivo**
- Benefit: search/order API shape was arguably cleaner than Telnyx's, and would have dropped in easily.
- Cost: cannot receive inbound SMS on an India number at all. Rejected outright — not a trade-off, a disqualification.

**C. Drop India from SMS scope entirely, or narrow it to Voice-only under PRD-10/§6b**
- Benefit: no second provider to build, test, or maintain a relationship with; avoids taking on Exotel's onboarding friction.
- Cost: doesn't deliver what §6a originally promised (India as a real SMS-provisioning country in Phase 1). This is the option that makes this ADR *unnecessary* — it's Product's call, not resolved here.

## Why this option

Between the two providers actually capable of the job (Plivo failed outright, so it's not really a two-way trade-off between A and B), Exotel is the only path that delivers the actual requirement — a customer's inbox that can receive SMS on an India number. The account-manager gate is real friction, but it's an onboarding-process cost, not a capability gap: once enabled, the API does what's needed. That's a materially different kind of problem than Plivo's, which no relationship-building or paperwork would fix.

## Consequences

- **Positive:** India can plausibly stay in Phase 1's SMS scope, via a second, real adapter — not a re-scope to voice-only or a dropped commitment.
- **Cost accepted:** onboarding a new India-serving customer's inbox now has a step that isn't purely self-serve API calls — someone (NR, presumably, since this is the reseller model) has to have or establish an Exotel account-manager relationship before inbound SMS works for real customers. This is an operational dependency, not just an engineering one.
- **Operational implication:** this adapter is the least-verified piece of the whole reseller platform. Unlike Telnyx (live-tested, gem-source-verified for the mechanics, even though its own blockers remain open), Exotel has had exactly one documentation research pass. Nothing here has been confirmed against a real Exotel account, a real search response, or a real order.

## Reversibility

**Two-way door at the architecture level, closer to one-way at the relationship level.** The provider-agnostic interface (Architecture Design §4) makes the Exotel adapter itself cheap to add, pause, or remove — no other component depends on Exotel existing. What's *not* cheap to reverse is any account-manager relationship or DLT registration effort NR invests in standing this up; unwinding that (if Exotel turns out unworkable after deeper testing) costs real operational time, not just a code revert.

## Follow-up

1. **Product must first decide** whether India stays in SMS scope at all (FRD Open Question 14) — this ADR is moot if the answer is "drop India" or "voice-only."
2. If India-via-Exotel is confirmed: live-test Exotel's search and order APIs against a real account, the same rigor Telnyx got (Implementation Spec §2a's treatment is the bar).
3. Confirm whether Exotel has a reservation concept (unconfirmed — Telnyx's docs explicitly call this out as a step; Exotel's docs did not, during this research pass).
4. Confirm Exotel's DLT registration API shape — the actual equivalent of Telnyx's regulatory-requirements flow for India-specific KYC/compliance.
5. Identify who owns starting the Exotel account-manager conversation, and get a real timeline for inbound SMS enablement before committing this to a sprint.
6. Build `ExotelProvider` per [number-provisioning-reseller-architecture-design.md](number-provisioning-reseller-architecture-design.md) §4's interface, once 2–5 are resolved.

## Approval

| Gate | Who | Date |
|---|---|---|
| ADR accepted | TBD | TBD |
