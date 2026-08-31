# TODOS

## Reputation isolation

### Unique index on video testimonials per review request

**What:** Add a unique index on `reputation_video_testimonials.review_request_id` and make create return 200 when the row already exists (`RecordNotUnique` rescue). Check for duplicate rows before the migration.

**Why:** Two parallel POSTs with one live token can insert two videos. Eng review Step 0 cut this from the isolation PR.

**Context:** CEO 4A. Feedback submissions have a non-unique index on `reputation_review_request_id` (`idx_on_reputation_review_request_id_f7ad17c20e`) — same race, videos first. Friday test 7 is the spec. After token-required create, `review_request_id` should be present.

**Effort:** S (human) → S (CC)
**Priority:** P2
**Depends on:** Isolation PR (T1 token-required video create)

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

## Completed
