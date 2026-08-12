# 📖 FEATURE BIBLE: Subscription & Billing Management (v2 — Single Provider)

> **Purpose of this doc:** Is single file mein feature ka poora context hai — kya hai, kyun hai, kaise kaam karega, aur AI coder ko exactly kya instruct karna hai.

**Status:** `Draft / In Progress`
**Owner:** Chandresh
**Last updated:** 2026-07-15
**Related module:** Enterprise Billing, Razorpay International Payment Gateway, Super Admin Controls
**Supersedes:** v1 (dual Stripe + Razorpay design)

---

## 0. WHY THIS VERSION CHANGED

v1 mein Stripe (international) + Razorpay (domestic) dual-provider plan tha. Do issues mile:

1. **Compliance risk:** Newrelay ek Indian-registered entity hai. Stripe ne apna India PA-CB (Payment Aggregator–Cross Border) licence July 2024 mein surrender kar diya — matlab Indian entity ke liye Stripe se cross-border payments legally lena ab clean path nahi raha.
2. **Unnecessary complexity:** Razorpay ka International Payment Gateway product ab full PA-CB + domestic licence dono rakhta hai — ek hi provider se India aur international dono customers serve ho sakte hain, auto-eFIRC generation ke saath (FEMA/GST export compliance).

**Decision:** Single provider — **Razorpay (Domestic + International Payment Gateway)**. Dual-provider Strategy pattern hata diya; provider abstraction layer ab bhi rakha hai (future flexibility ke liye) but sirf ek active implementation ke saath.

⚠️ **Action item before build starts:** Razorpay sales/compliance team se apne exact use case (SaaS subscriptions, India + US/UK customers, recurring card + UPI Autopay) directly confirm karo. Licensing/compliance status fast change hota hai.

---

## 1. WHAT — Feature Summary

**One-liner:** A single-provider (Razorpay) subscription billing system where Super Admins define plans with multi-currency pricing, and Account Admins subscribe, manage payment methods, and track usage — with India and international customers both served through one integration.

**Elevator pitch:** The Subscription and Billing feature introduces a billing engine built on Razorpay's International Payment Gateway, covering domestic (UPI, cards, netbanking) and cross-border (international cards, Apple Pay, Google Pay) payments in one stack. Super Admins configure plans and per-currency pricing without deployments. Account Admins subscribe, upgrade/downgrade with proration, and see real-time usage against their quota.

---

## 2. WHY — Problem & Justification

**Problem statement:** Hardcoded plans (`CHATWOOT_CLOUD_PLANS`) block dynamic pricing. Serving India and international customers through two separate providers (as originally planned) doubles integration, webhook, reconciliation, and compliance surface area — and one of the two providers (Stripe) is not a compliant path for an Indian merchant entity doing cross-border collection.

**Who needs this:**
1. **Super Admins** — centralized plan/pricing control, MRR visibility, no code deploys for pricing changes.
2. **Account Administrators (Front Admin)** — self-serve plan selection, checkout, usage visibility, and clean upgrade/downgrade.

**What happens without it:** Plan changes need engineering time; without proper compliance documentation (eFIRC), export income from international SaaS customers becomes a manual accounting/CA headache — directly relevant since Newrelay is GST-registered in Jodhpur.

**Business value:** One integration to maintain, one compliance flow (auto-eFIRC per transaction), lower dev/ops overhead than dual-provider, and demonstrated conversion improvements (Apple Pay at checkout lifted subscription conversion in Razorpay's own pilot data).

---

## 3. USER STORIES

- As a **Super Admin**, I want to **create, edit, and disable subscription plans with per-currency pricing**, so that I can price for India (INR) and international (USD) markets without code changes.
- As a **Super Admin**, I want to **view all active subscriptions, MRR, and churn**, so that I can track platform health.
- As an **Account Administrator**, I want to **view available plans in my local currency and subscribe**, so that checkout feels native regardless of region.
- As an **Account Administrator**, I want to **upgrade or downgrade my plan mid-cycle with fair proration**, so that I'm not overcharged or undercharged.
- As an **Account Administrator**, I want to **see my current plan, usage, and next billing date**, so that I know exactly where I stand.
- As an **Account Administrator**, I want **my failed payment to be retried automatically with a grace period**, so that I don't lose access instantly over a temporary card issue.

---

## 4. SCOPE

### ✅ In Scope
- Super Admin plan CRUD with **per-currency pricing** (not a single price field).
- Razorpay Subscriptions integration — UPI Autopay (domestic) + tokenized cards/Apple Pay/Google Pay (international).
- Webhook handling with **idempotency** (event dedup table).
- Proration on upgrade/downgrade.
- Dunning: automatic retry + grace period + notification on `past_due`.
- Account limits tracking enforced from a dedicated `subscriptions` table (not JSONB).
- Auto-generated invoice/receipt record per successful charge (GST-line-item ready).

### ❌ Out of Scope
- Self-hosted community edition (billing is Enterprise-only overlay).
- A second payment provider (documented as Phase 2 optionality below).
- Automated tax calculation engine (manual GST rate applied at invoice generation for now).

### 🔮 Future / Phase 2
- Add a second provider (e.g. PayU) behind the existing `Billing::Provider` interface **only if** a concrete business need arises (e.g. success-rate optimization, redundancy) — architecture supports it without a rewrite.
- Per-feature paywalls beyond usage limits.
- Real-time GST filing integration.

---

## 5. HOW IT ACTIVATES — Trigger & Lifecycle

**Activation trigger:** Super Admin publishes a plan → Account Admin selects plan on Billing page → checkout via Razorpay Checkout (hosted, PCI scope stays with Razorpay).

**Preconditions:**
- Environment is Chatwoot Cloud / Enterprise.
- Razorpay live API keys + webhook secret present.
- Razorpay merchant KYC + PA-CB approval confirmed (see dependency table).

**Lifecycle states (subscription-level, tracked in DB, not just provider-side):**
| State | Meaning | Next state trigger |
|---|---|---|
| `trialing` | Optional trial period active | Trial end → `active` or card charged |
| `pending` | Checkout/mandate created, awaiting first charge confirmation | Webhook: payment success/failure |
| `active` | Subscription live, plan applied | Renewal webhook / cancellation / payment failure |
| `past_due` | Charge failed, in dunning/retry window | Retry success → `active`; retries exhausted → `canceled` |
| `canceled` | Subscription ended (user or system initiated) | Resubscribe → new `subscriptions` row |

**Deactivation/rollback:** Cancel request → cancel in Razorpay → webhook confirms → local state updated. Never flip local state to canceled purely on the outbound API call succeeding; wait for/reconcile with the webhook to avoid drift if the API call succeeded but response was lost.

---

## 6. EXTERNAL DEPENDENCIES & LEAD TIME

| Dependency | Needed for | Who applies | Approval/setup time | Status | Blocker risk |
|---|---|---|---|---|---|
| Razorpay merchant KYC | All payments | Admin | 1-3 days | `pending` | High |
| Razorpay PA-CB confirmation (cross-border) | International customer billing | Admin | Confirm with Razorpay sales | `to verify` | High |
| Razorpay International Payment Gateway enablement | Apple Pay/Google Pay, intl cards | Admin | Confirm with Razorpay sales | `to verify` | Medium |
| Webhook secret | Verifying incoming events | Admin | Instant | `pending` | High |
| GST invoicing rule confirmation (CA sign-off) | Invoice generation correctness | Admin/CA | Days | `pending` | Medium |

**Action item:** Confirm with Razorpay directly (not just marketing pages) that the merchant account is fully enabled for both UPI Autopay recurring **and** international recurring cards before committing the architecture — this is the single biggest blocker-risk item.

---

## 7. DATA MODEL

**New tables (replacing the v1 JSONB-on-account approach):**

```
plans
  - id
  - name
  - description
  - limits: jsonb (e.g., { agents: 5, responses: 1000 })
  - active: boolean
  - created_at / updated_at

plan_prices                          -- one plan, many currencies
  - id
  - plan_id (FK)
  - currency (e.g. 'INR', 'USD')
  - amount
  - razorpay_plan_id                  -- Razorpay's own "plan" object per currency
  - billing_interval ('monthly'/'yearly')

subscriptions                        -- dedicated table, NOT accounts.custom_attributes
  - id
  - account_id (FK)
  - plan_id (FK)
  - plan_price_id (FK)                -- snapshot of the price they're actually paying (grandfathering)
  - razorpay_customer_id
  - razorpay_subscription_id
  - status (enum: trialing/pending/active/past_due/canceled)
  - current_period_start
  - current_period_end
  - trial_ends_at
  - canceled_at
  - created_at / updated_at

invoices                              -- one row per successful/failed charge
  - id
  - subscription_id (FK)
  - razorpay_payment_id
  - amount
  - currency
  - status (paid/failed/refunded)
  - gst_amount                        -- nullable, filled if applicable
  - invoice_number
  - issued_at

processed_webhook_events              -- idempotency guard
  - id
  - razorpay_event_id (unique index)
  - event_type
  - processed_at
```

**Why this differs from v1:** v1 stored subscription state in `accounts.custom_attributes` JSONB — no FK integrity, no history, race-condition-prone on concurrent webhook writes, and impossible to index for MRR/churn queries. A dedicated `subscriptions` + `invoices` table set fixes all four.

**Migration notes:** `CHATWOOT_CLOUD_PLANS` config becomes seed data for `plans` + `plan_prices`.

---

## 8. BACKEND / API

**Endpoints:**
| Method | Route | Purpose | Auth |
|---|---|---|---|
| `GET/POST` | `/super_admin/plans` | CRUD for plans + prices | Super Admin |
| `GET` | `/enterprise/api/v1/plans` | Fetch plans in requester's currency | Admin (Front) |
| `POST` | `/enterprise/api/v1/accounts/:id/checkout` | Create Razorpay subscription/checkout (idempotency-key required) | Admin (Front) |
| `POST` | `/enterprise/api/v1/accounts/:id/subscription/change_plan` | Upgrade/downgrade with proration | Admin (Front) |
| `POST` | `/enterprise/webhooks/razorpay` | Process Razorpay webhook events (idempotent) | Razorpay Sig |

**Background jobs:**
- `Billing::WebhookProcessorJob` — decouples webhook response time from DB writes; checks `processed_webhook_events` before doing anything.
- `Billing::DunningRetryJob` — scheduled retries for `past_due` subscriptions, escalating notification (email at each attempt, final warning before cancel).
- `Billing::InvoiceGeneratorJob` — creates an `invoices` row on each successful/failed payment webhook.

**External integrations:** `razorpay` ruby gem.

**Existing patterns to follow:**
- Keep a thin `Billing::Provider` interface even with one implementation (`Billing::Provider::Razorpay`) — costs almost nothing now, saves a rewrite if a second provider is ever added.
- All billing logic stays inside `enterprise/`.
- Webhook controller must read raw request body for signature verification — do not let a JSON-parsing middleware run first, or signature verification will fail.

---

## 9. FRONTEND / UI

**Screens/components touched:**
- **Super Admin:** `Plans` management dashboard — plan CRUD + per-currency price rows.
- **Front Admin:**
  - `app/javascript/dashboard/routes/dashboard/settings/billing/Index.vue`
  - Plan cards showing price in the account's detected/selected currency.
  - Upgrade/downgrade flow showing proration preview before confirming.
  - Payment method management (Razorpay's hosted checkout handles card/UPI capture — no raw card fields in our UI).

**States to handle:**
- Loading (fetching plans, processing checkout redirect).
- Empty state (no plans configured).
- Error (payment failed, gateway down, proration calculation failed).
- `past_due` banner with "update payment method" CTA.

---

## 10. FLOW — Step by Step

1. **Plan Creation (Super Admin):** Creates plan, adds a `plan_price` row per currency (INR + USD minimum), links Razorpay plan ID for each.
2. **Plan Selection (Front Admin):** Sees plans priced in their currency, selects one.
3. **Checkout:** Backend creates Razorpay subscription/customer with an idempotency key, redirects to Razorpay Checkout (UPI Autopay mandate or card tokenization depending on currency/region).
4. **Webhook:** Razorpay fires `subscription.activated`/`charged`. Handler checks `processed_webhook_events`, then creates/updates `subscriptions` row + `invoices` row.
5. **Upgrade/Downgrade:** Front Admin requests plan change → backend calculates proration via Razorpay API → confirms → updates `subscriptions.plan_price_id`.
6. **Failure path:** Charge fails → `past_due` → `DunningRetryJob` retries on schedule → success reactivates, exhaustion cancels.

**Acceptance criteria (Definition of Done):**
- [ ] Super Admin can create/disable plans with multiple currency prices.
- [ ] Front Admin sees dynamic, currency-correct plans.
- [ ] Checkout works for both UPI Autopay (India) and international card/Apple Pay/Google Pay.
- [ ] Webhooks are idempotent — replaying the same event twice causes no duplicate side effects.
- [ ] Upgrade/downgrade correctly prorates and updates plan_price_id.
- [ ] Failed payment triggers dunning retry + notification, not instant cancellation.
- [ ] Each successful/failed charge produces an `invoices` row.

---

## 11. EDGE CASES & FAILURE MODES

| Scenario | Expected behavior |
|---|---|
| Webhook signature invalid | 400, log, ignore payload |
| Duplicate webhook delivery (same event id) | Detected via `processed_webhook_events`, no-op |
| Razorpay API down during checkout | Graceful error: "Payment gateway unavailable, please try again" |
| Super Admin deletes an active plan | Soft-delete (`active: false`); existing subscriptions keep their `plan_price_id` snapshot |
| Super Admin changes a plan's price | New subscribers get new price; existing subscribers stay on their snapshotted `plan_price_id` until they change plans |
| Double-click on checkout button | Idempotency key on the checkout request prevents duplicate subscription/customer creation |
| Payment fails, then succeeds on retry | `past_due` → `active`, no duplicate invoice for the failed attempt beyond a `failed`-status record |
| Card expires mid-subscription | Razorpay account updater (if enabled) refreshes card; otherwise dunning flow + notification kicks in |

---

## 12. NON-FUNCTIONAL REQUIREMENTS

- **Security:** Webhook signatures verified on raw body. No card data touches our servers (Razorpay Checkout is hosted).
- **Scalability:** Webhooks processed async via Sidekiq; dunning retries scheduled, not synchronous.
- **Compliance:** Auto-eFIRC per international transaction (Razorpay-generated) stored/linked against the `invoices` row for CA/audit access.
- **Maintainability:** `Billing::Provider` interface kept thin even for a single implementation, to avoid a rewrite if a second provider is added later.

---

## 13. AI IMPLEMENTATION INSTRUCTIONS

**Tech stack constraints:** Rails + Vue.js + `razorpay` gem. All backend billing code lives in `enterprise/`.

**Files likely to touch:**
- `db/migrate/` — create `plans`, `plan_prices`, `subscriptions`, `invoices`, `processed_webhook_events`.
- `enterprise/app/models/enterprise/{plan,plan_price,subscription,invoice}.rb`
- `enterprise/app/controllers/super_admin/plans_controller.rb`
- `enterprise/app/services/enterprise/billing/provider/razorpay.rb`
- `enterprise/app/services/enterprise/billing/checkout_service.rb`
- `enterprise/app/services/enterprise/billing/proration_service.rb`
- `enterprise/app/services/enterprise/billing/dunning_service.rb`
- `enterprise/app/controllers/enterprise/webhooks/razorpay_controller.rb`
- `enterprise/app/jobs/enterprise/billing/{webhook_processor,dunning_retry,invoice_generator}_job.rb`
- `app/javascript/dashboard/routes/dashboard/settings/billing/Index.vue`
- `app/javascript/super_admin/` — new Vue routes for Plan + Price management

**Step-by-step build order:**
1. **Database & Models:** `plans`, `plan_prices`, `subscriptions`, `invoices`, `processed_webhook_events`.
2. **Super Admin CRUD:** Plan + per-currency price management UI/API.
3. **Checkout + Webhook pipeline:** Razorpay checkout service, webhook controller with idempotency check, `subscriptions`/`invoices` writes.
4. **Front Admin UI:** Currency-aware plan display, checkout redirect, current plan/usage view.
5. **Proration service:** Upgrade/downgrade calculation and plan_price_id update.
6. **Dunning service:** Retry schedule + notifications on `past_due`.

**Do NOT:**
- Do not store subscription state in `accounts.custom_attributes` — use the dedicated `subscriptions` table.
- Do not skip the `processed_webhook_events` idempotency check, even "to save time" — webhook duplication is not an edge case, it's expected behavior from Razorpay.
- Do not put billing logic in `app/` — keep it in `enterprise/`.
- Do not let a plan price edit retroactively change existing subscribers' price — always snapshot via `plan_price_id`.

---

## 14. ROLLOUT PLAN

- **Feature flag:** Bound to Chatwoot Cloud mode + Enterprise edition.
- **Rollout order:** Internal testing (both INR and USD test transactions) → Beta accounts (mix of India + international) → All users.
- **Success metric:** Successful payment completion rate across both UPI Autopay and international card/Apple Pay flows; dunning recovery rate on `past_due`.

---

## 15. OPEN QUESTIONS

- [ ] Confirmed with Razorpay: is the merchant account fully enabled for both domestic UPI Autopay recurring **and** international recurring cards under one dashboard, or do these need separate onboarding steps?
- [ ] Do we need a trial period at launch, or is that Phase 2?
- [ ] What's the dunning retry schedule (days between retries, total attempts before cancel)?
- [ ] Who owns GST rate correctness on the `invoices.gst_amount` field — engineering default or CA-provided rule?
