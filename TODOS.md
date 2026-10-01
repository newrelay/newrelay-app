# TODOS

## Comment-to-DM automation

### Generalize short-link infra

**What:** Extract `comment_automation_short_links` + its redirect controller into a feature-agnostic short-link service (e.g. `app/services/short_link/`) other modules can point at.

**Why:** No short-link precedent exists anywhere in this repo today (confirmed by full-repo grep during the 2026-09-01 CEO review of the comment-to-DM automation plan). Comment automation will be the first and only consumer at launch — generalizing now would be speculative.

**Context:** CEO review 2026-09-01, `docs/solution-notes/comment-to-dm-automation-prd.md` §11. Do this once a second real consumer (CRM, reputation, etc.) needs tracked redirects — not before.

**Effort:** M (human) → S (CC)
**Priority:** P3
**Depends on:** A second consumer actually needing it

## Reputation isolation

### ADR 0005 reputation tenant isolation

**What:** Write `docs/adr/0005-reputation-tenant-isolation.md` (Context / Decision / Consequences). Link from `docs/adr/README.md`.

**Why:** Other modules copy this checklist. Without an ADR the next person re-litigates RLS. The ADR must say QR is public-by-design, video/feedback/`/r/:token` are token-only, and the public sync route was **deleted** (not secret-gated).

**Context:** CEO 10A. Eng D10 deleted `/api/v1/reputation/sync/:id`. Do not document WebhookSecretable for this. Series already has 0001–0004.

**Effort:** S (human) → S (CC)
**Priority:** P2
**Depends on:** Isolation PR merged so the ADR matches shipped behavior

### Branded expired-token page

**What:** Small branded HTML page when `/r/:token`, video `new`, or feedback hits scheduled/completed. QR review form unchanged.

**Why:** Isolation PR 404s spent links. A customer with a used email sees a blank error instead of “you already submitted.”

**Context:** CEO 11A / T7. Public recorder still uses cdn.tailwindcss.com — do not redesign that page here.

**Effort:** M (human) → S (CC)
**Priority:** P2
**Depends on:** Isolation PR status gates

### `[reputation.isolation]` logs

**What:** On spent/missing token (and any leftover sync 404), log `[reputation.isolation] reason=... request_id=N`. Never log the raw token. Mock `deliver_mock` still logs `/r/:token` on purpose (eng D11).

**Why:** Greppable security events when a customer says the link is dead.

**Context:** CEO 8A / T8. Rails already logs 404 status. This is an explicit prefix.

**Effort:** S (human) → S (CC)
**Priority:** P2
**Depends on:** Isolation PR

### Optional job account_id guard

**What:** Keep `perform(record_id)`. If `account_id` is passed, no-op when the record’s account does not match. No arity rewrite (in-flight Sidekiq). Watch `VideoInsightsJob.perform_later(testimonial)` (GlobalID object).

**Why:** Defense in depth after a bug passes the wrong id. Public enqueue door is already gone (eng D10).

**Context:** CEO D16 / T10. Blast radius is internal (connect, cron, member sync).

**Effort:** M (human) → S (CC)
**Priority:** P3
**Depends on:** none required; cheaper after isolation PR

### Copy isolation contract to CRM, Captain, Inbox

**What:** After Reputation ships, run the same checklist on CRM deals, Captain, and Inbox jobs: dashboard `Current.account.association.find`, jobs must not take unauthenticated public ids, public/webhooks need a secret or token (or the public route is deleted on purpose).

**Why:** Those areas still rely on remembering `account_id`. One missed WHERE is another tenant's data.

**Context:** CEO review 2026-08-31 reduced "multi-tenancy on every module" to Reputation first. ADR 0005 (TODO above) is the copy-paste brief. Do not invent RLS or schema-per-tenant unless a later review reopens it.

**Effort:** M (human) → S (CC)
**Priority:** P3
**Depends on:** Isolation PR + ADR 0005

## Phone numbers

### Release purchased numbers after a long suspension

**What:** After an account has been suspended for a set time, release its purchased numbers back to Telnyx or Exotel and mark the order released.

**Why:** This plan holds the number through suspension, so the carrier keeps billing the platform. The customer who resubscribes may not get the same number back, which is why it is not in the buy flow.

**Context:** CEO review 2026-09-29, D15 and D27, on `feature/phone-reseller`. `Enterprise::Billing::GracePeriodEnforcerJob` suspends the account after 7 days and does not delete inboxes. Unpaid `billing_failed` numbers (no billing reference) are released in the buy plan. Paid numbers, including `inbox_pending` and numbers on a suspended account, are not. Start from `NumberProvisioning::Order` in `active` plus the account `suspended`. Verify the provider release API before coding. Do not invent it. The deadline is not chosen yet. 30 days was offered and rejected for this plan.

**Effort:** M (human) → S (CC)
**Priority:** P3
**Depends on:** A paid number existing, and a verified provider release call

### Convert number price into the subscription currency

**What:** When the provider currency and the account subscription currency differ, convert wholesale-plus-margin into the subscription currency instead of failing the charge.

**Why:** Telnyx defaults to USD and Exotel to INR. A mismatch is `billing_failed` with no inbox, so a workspace on the other currency cannot buy the number.

**Context:** CEO review 2026-09-29, D20 and D29, on `feature/phone-reseller`. Provider currency is `NumberProvisioning::ProviderConfig` (Super Admin). There is no FX table in billing. Do not invent a rate. This TODO starts only after a rate source is chosen. Until then the failed charge and the Super Admin count are the behavior.

**Effort:** L (human) → M (CC)
**Priority:** P4
**Depends on:** A chosen FX source, and a paid number existing

## Voice agent

### Outbound calls from the voice agent

**What:** Let the voice agent place calls, not only answer the purchased number.

**Why:** Outbound is a different product from the inbound receptionist. India adds consent and do-not-call rules. A bad list becomes a spam complaint on the number the account just bought.

**Context:** CEO review 2026-09-30, voice-agent plan, on `feature/phone-reseller`. Inbound (SIP attach, transcript, minute billing, Relay AI as the brain, human handoff, India and US) is the accepted plan. Outbound was deferred. Do not bolt dialing onto the inbound trunk. Start only after inbound answers on a live call.

**Effort:** XL (human) → L (CC)
**Priority:** P3
**Depends on:** A proven inbound voice agent

### Test-call button

**What:** On the phone-number row, let an admin place one call to that number and hear the agent.

**Why:** The row can say the trunk is saved while callers still hit today's answering path. A test call is how an admin tells those apart without using a personal phone.

**Context:** CEO review 2026-09-30. Not part of the inbound plan. Do not turn this into an outbound campaign dialer. It places one call to the purchased number only.

**Effort:** M (human) → S (CC)
**Priority:** P3
**Depends on:** Slice 4, Relay AI actually answering

### Voice picker

**What:** Let the admin choose which ElevenLabs voice speaks for a number. The brain stays that inbox's Relay AI.

**Why:** The first version uses one default voice. A workspace will want a different one without a second prompt.

**Context:** CEO review 2026-09-30. A separate ElevenLabs prompt was rejected. This is speech only, not a second knowledge base.

**Effort:** M (human) → S (CC)
**Priority:** P3
**Depends on:** Slice 4

### After-hours schedule

**What:** Use Relay AI only outside business hours. During the day, ring a human.

**Why:** Some accounts want a night receptionist, not a replacement for the team.

**Context:** CEO review 2026-09-30. v1 is the agent whenever live answers are on, unless the platform kill switch or the per-number switch is off. Do not invent a calendar in the inbound plan. Time zone is the account's.

**Effort:** L (human) → M (CC)
**Priority:** P3
**Depends on:** Slice 4 and the handoff bridge

### Failed-call fallback audio

**What:** When the trunk or a Relay AI turn fails, play a real fallback prompt instead of silence.

**Why:** v1 records `voice_agent_reply_timeout` and `voice_agent_reply_invalid` and does not invent the words. The caller can still hear dead air.

**Context:** CEO review 2026-09-30. Do not build this until the slice 4 probe shows ElevenLabs can play a prompt on a failed hook. Do not mark the turn successful because fallback audio played.

**Effort:** M (human) → S (CC)
**Priority:** P2
**Depends on:** The slice 4 probe

### Post-call summary

**What:** After the transcript is stored, add a short summary at the top of that conversation.

**Why:** A long call is hard to scan. The team opens the inbox to see what the caller wanted.

**Context:** CEO review 2026-09-30. v1 stores the transcript only. The transcript stays the source of truth. A wrong summary must not replace it. No streaming mid-call lines.

**Effort:** M (human) → S (CC)
**Priority:** P3
**Depends on:** The post-call transcript webhook

### Per-account ElevenLabs minute caps

**What:** Cap how many agent seconds one account can consume on the shared ElevenLabs key.

**Why:** One platform key serves every customer. A noisy account, or a vendor rate limit, fails turns as `voice_agent_rate_limited` and can starve other numbers. A cap built before real usage events would be a made-up number.

**Context:** CEO review 2026-09-30. v1 names `voice_agent_rate_limited` and does not build the cap. Start from vendor usage-event ids once minute billing is verified.

**Effort:** M (human) → S (CC)
**Priority:** P2
**Depends on:** Verified usage events

### Settings list touch targets

**What:** Raise outline buttons on settings lists to at least 44px tall.

**Why:** Connect on the phone-number row matches Upload documents, and that button is 32px. A thumb can miss it. Changing only Connect would make the two actions on that page look unrelated.

**Context:** Design review 2026-09-30, voice-agent plan. The voice-agent row keeps the existing `h-8` outline `RelayButton`. This is a settings-wide pass, not part of the voice agent. Start from `SettingsListRow` actions such as Upload documents and Connect.

**Effort:** S (human) → S (CC)
**Priority:** P3
**Depends on:** Nothing in the voice agent

## Completed

### Unique index on video testimonials per review request

Unique index on `review_request_id` (NULLs allowed). Duplicate POSTs return 200 and keep one row. Migration deletes extra rows keeping the oldest.
