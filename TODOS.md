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

## Completed

### Unique index on video testimonials per review request

Unique index on `review_request_id` (NULLs allowed). Duplicate POSTs return 200 and keep one row. Migration deletes extra rows keeping the oldest.
