# FRD: Billing & Subscription

**Status:** Shipped (Stripe path — legacy/platform), In transition (Razorpay is the intended sole provider going forward per compliance decision — see §2)
**Module:** Enterprise-only, newrelay-custom billing layer on top of Chatwoot Cloud's plan concept
**Last updated:** 2026-09-07

> Consolidated FRD covering Subscriptions, Payment Transactions, Coupons, Plan Feature Limits, Marketplace/Commission pricing, and Enterprise Contracts — one billing domain, 30+ services. See `docs/subscription-feature-bible-v2.md` for the full business/compliance rationale (in Hindi/English mix) behind the provider decision below; this FRD is the as-built technical reference.

---

## 1. What it is

**One-liner:** Per-account subscription billing supporting two relationship types — **platform** (a direct customer subscribing to a plan) and **marketplace** (an agency reselling to sub-accounts, with automatic commission split) — across two payment rails (Stripe, Razorpay), plus coupons, usage/feature limits per plan, and negotiated Enterprise contracts for large accounts.

**Who uses it:** Super Admins (define plans, commission rules, enterprise contracts), account admins (subscribe, manage payment method, view usage), agencies (marketplace relationship — sub-accounts billed through them with a commission cut).

---

## 2. How it works

### Why two providers exist in the schema, but one is the intended future
Per `docs/subscription-feature-bible-v2.md`: v1 was designed dual-provider (Stripe international + Razorpay domestic). That was revised — **Stripe surrendered its India cross-border payment-aggregator license in July 2024**, making it a compliance risk for newrelay (an India-registered/GST entity in Jodhpur) to keep using for cross-border collection. The decision (v2) is to consolidate on **Razorpay's International Payment Gateway** (handles both domestic UPI/cards/netbanking and cross-border cards/Apple Pay/Google Pay in one integration, with automatic eFIRC generation for FEMA/GST export compliance). **The code still carries both provider paths today** (`subscriptions.payment_provider` inclusion `[stripe, razorpay]`, parallel `stripe_*`/`razorpay_*` columns across most billing tables, a `Billing::PaymentGatewayRegistry` abstraction) — treat Stripe as the legacy/being-phased-out path, not the target architecture, when planning new billing work.

### Subscription relationship types
1. `Subscription.relationship_type` is either `platform` (direct customer) or `marketplace` (a `connected_account` — an agency — resells to this account, with `application_fee_amount` as the platform's cut of each charge, mirroring Stripe Connect / Razorpay Route's split-payment model).
2. `MarketplacePlanPrice` defines what an agency pays per plan (`agency_price`) vs. `commission_percent`/`platform_fee_amount`/`total_amount` — the actual math of how a marketplace sale splits between the platform and the reselling agency.
3. `CommissionRule` (`commission_percent`, `effective_from`) lets that split change over time per account without editing historical transactions — new rules apply from their effective date forward.

### Checkout & webhook flow
4. Separate checkout services exist per provider and per purpose: `PlanCheckoutService`/`RazorpayPlanCheckoutService` (standard plan subscribe), `Tier3CheckoutService` (a specific high-tier flow), `TopupCheckoutService`/`RazorpayTopupCheckoutService` (one-off credit purchases — ties to Captain AI's `credit_multiplier`, see [18-captain-ai.md](18-captain-ai.md)), `RazorpayMarketplaceCheckoutService` (agency-resold subscriptions), `EnterprisePaymentLinkService`/`RazorpayEnterprisePaymentLinkService` (negotiated-contract invoicing, not self-serve checkout).
5. `HandleStripeEventService`/`HandleRazorpayEventService` process provider webhooks (`POST /webhooks/stripe`, `/webhooks/razorpay`) — subscription status changes, payment success/failure, etc. — and write to `RecordPaymentTransactionService`/`RecordBillingActivityService`.
6. `SyncPaymentTransactionsService` reconciles `PaymentTransaction` rows against the provider's actual invoice/charge records (drift correction, not just webhook-driven).
7. `RazorpayConnectOnboardingService`/`ConnectOnboardingService` handle agency onboarding into the marketplace/split-payment relationship (KYC-style flow required by both providers for split payments).

### Coupons, limits, and enterprise contracts
8. `BillingCoupon` supports both percent-off and amount-off, `duration` (`once`/repeating/`forever`-style), `max_redemptions`/`times_redeemed`, and is synced to/from the provider (`stripe_coupon_id`/`razorpay_offer_id`) via `SyncBillingCouponService`; `ValidatePlanCouponService`/`ApplyBillingCouponService` handle checkout-time validation and application.
9. `PlanFeatureLimit` is a flat, plan-agnostic-key lookup table (`plan_key` + `feature_key` → `enabled`/`limit_value`) — the actual feature-gating mechanism read at runtime to decide whether an account's plan allows/limits a given feature (e.g. how many Reputation listings, Captain assistants, etc. an account can have). `ReconcilePlanFeaturesService` presumably syncs this table when plan definitions change.
10. `EnterpriseContract` is a fully out-of-band billing path for negotiated deals — `negotiated_price`, custom `billing_interval`, `collection_method` (defaults `send_invoice`, not automatic card charging), `payment_terms_days`, contract date range, `auto_renew`, and `negotiated_limit_overrides`/`negotiated_features` (jsonb) that override the standard `PlanFeatureLimit` table for that specific account.
11. `TenantRescueService`/`CancelCloudSubscriptionsService` handle account-level consequences of billing failure (grace period expiry, forced downgrade) — `subscriptions.grace_period_ends_at`/`cancel_at_period_end` drive this.
12. `BillingActivityLog` is an audit trail of billing-related actions/errors (`action`, `status` default `failed`, `error_class`, `message`, `metadata`) — every significant billing operation (checkout attempt, webhook processing failure, etc.) appears to log here regardless of success, given the default status is `failed` (i.e., explicit success logging must set status, absence implies something went wrong by default — worth confirming this default isn't accidentally under-logging successes).

---

## 3. Data model

```
subscriptions        (one per account, unique account_id)
  - stripe_customer_id/subscription_id, razorpay_subscription_id/customer_id
  - payment_provider: string  # 'stripe' | 'razorpay'
  - relationship_type: string # 'platform' | 'marketplace'
  - connected_account_id: bigint (the reselling agency, if marketplace)
  - application_fee_amount: decimal
  - status: string, default "trialing"
  - stripe_price_id/product_id, plan_name, subscribed_quantity
  - current_period_start/end, grace_period_ends_at, cancel_at_period_end

payment_transactions
  - account_id, stripe_customer_id/invoice_id/charge_id
  - amount, currency, status, billing_reason
  - hosted_invoice_url, invoice_pdf, paid_at
  - unique per stripe_invoice_id

billing_coupons
  - code (unique), name, discount_type (percent/amount), percent_off/amount_off, currency
  - duration, duration_in_months, max_redemptions, times_redeemed, redeem_by, active
  - applies_to, stripe_coupon_id/razorpay_offer_id, metadata

billing_activity_logs
  - account_id, user_id, action, payment_provider
  - status (default "failed"), error_class, message, metadata

plan_feature_limits
  - plan_key, feature_key (unique pair), enabled, limit_value

marketplace_plan_prices
  - account_id, currency, agency_price, commission_percent, platform_fee_amount, total_amount
  - stripe_price_id/product_id, razorpay_plan_id, active

commission_rules
  - account_id, commission_percent (default 30.0), effective_from, created_by_user_id

enterprise_contracts
  - account_id, negotiated_price, currency, billing_interval
  - collection_method (default "send_invoice"), payment_terms_days (default 30)
  - contract_start_date/end_date, auto_renew
  - negotiated_limit_overrides (jsonb), negotiated_features (jsonb)
  - negotiated_by_user_id, notes
```

---

## 4. Backend / API

**Public webhook routes:** `POST /webhooks/stripe` → `webhooks/stripe#process_payload`; `POST /webhooks/razorpay` → `webhooks/razorpay#process_payload`.

**Engine (all Enterprise):** `enterprise/app/services/enterprise/billing/*.rb` — 30 services covering checkout (5 variants), webhook handling (2 providers), coupon sync/validation/application, payment transaction recording/sync, Connect/marketplace onboarding, tenant rescue, topup fulfillment, and `payment_gateway_registry.rb` (the provider-abstraction layer kept intentionally, per the feature bible, "for future flexibility" even with one active provider).

**Models:** `app/models/{subscription, billing_activity_log, billing_coupon, payment_transaction, plan_feature_limit, marketplace_plan_price, commission_rule, enterprise_contract}.rb` — notably these live in OSS `app/models/`, not `enterprise/app/models/`, even though the feature is Enterprise-gated at the controller/service layer.

**Super Admin surface:** billing coupon management, MRR/subscription visibility (see [21-super-admin.md](21-super-admin.md), Phase 5 next item).

---

## 5. Frontend

**Vue:** account billing/subscription settings under `dashboard/routes/dashboard/settings/billing/` (plan selection, checkout redirect, usage display, payment method management); Super Admin billing coupon UI (recently touched per git status: `SuperAdmin::BillingCouponsController` shows Cloudflare error messages instead of raw hashes — a fix, not new build).

---

## 6. Test coverage (as it exists today)

Only ~10 spec files found across `spec/enterprise/**` matching billing/subscription/payment/commission/marketplace/enterprise_contract paths — this is thin relative to a 30-service, 8-table billing subsystem that directly handles money, webhooks, and commission math.

**Coverage gaps observed:** given the file count, most individual checkout services, webhook handlers, and the commission-split math (`MarketplacePlanPrice`/`CommissionRule` application) do not appear to have confirmed direct specs. This is the highest-risk gap found across the entire FRD program so far — billing correctness bugs are costly and hard to detect informally. Recommend a focused test-coverage audit of `enterprise/app/services/enterprise/billing/` before treating this subsystem as low-risk.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, **Stripe SDK** (legacy/being-phased-out path), **Razorpay SDK** (`razorpay_client.rb` — intended primary path), Sidekiq (webhook processing, reconciliation jobs)
- Compliance: Razorpay's eFIRC generation for cross-border export compliance (FEMA/GST) — a business/compliance dependency, not a code dependency, but worth knowing when working on this area

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Payment fails, account enters grace period | `grace_period_ends_at` set; `TenantRescueService` presumably handles the eventual downgrade/suspension if unresolved |
| Webhook double-delivered | Provider event handlers should be idempotent per event id — exact dedup mechanism not directly confirmed in this pass |
| Coupon redeemed past `max_redemptions` or `redeem_by` | Enforced by `ValidatePlanCouponService` at checkout time |
| Enterprise contract account also has a standard plan's feature limits | `negotiated_limit_overrides`/`negotiated_features` on the contract take precedence — exact override mechanism (merge vs. full replace) not confirmed |
| Marketplace sub-account subscription payment fails | Commission/agency relationship implications not traced in this pass — flag if agency billing is a priority area |

---

## 9. Price / plan gating

**Gating type:** This module *defines* the matrix other FRDs cite. Not a customer-facing SKU. Related: reseller dashboard is Business-only; sub-account count is a resource quota.
**`feature_key`(s):** this table is the source (`plan_key` + `feature_key`). Related keys: `reseller_dashboard` (premium); resource `t3_subaccounts`

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | n/a (this is the catalog) | 0 T3 sub-accounts | `reseller_dashboard` off |
| Standard | n/a | 3 T3 sub-accounts | `reseller_dashboard` off |
| Business | n/a | 25 T3 sub-accounts | `reseller_dashboard` on |
| Enterprise | n/a | negotiated | no seeder row; `EnterpriseContract` is the plan |

**Credits / usage:** Captain top-ups (`TopupCheckoutService`) add to `captain_responses`; not priced in this FRD.
**Enforced by:** `Enterprise::Billing::ReconcilePlanFeaturesService` reads `plan_feature_limits` and writes `account.limits` / feature flags
**Source:** `lib/seeders/plan_feature_limit_seeder.rb` — Super Admin `plan_management` edits live rows

---

## 10. Open gaps / notes

- **Test coverage is the most significant gap found in this entire FRD program.** A 30-service billing subsystem handling two payment providers, commission splits, and enterprise contracts with only ~10 specs is a real risk area — recommend prioritizing this for a dedicated review/test-hardening pass.
- Stripe is architecturally still fully present in the code despite the documented business decision to consolidate on Razorpay — new billing work should default to the Razorpay path per `docs/subscription-feature-bible-v2.md`, and Stripe-path changes should be treated as maintenance-only unless told otherwise.
- Webhook idempotency/dedup mechanism not directly confirmed — worth verifying before relying on "webhook replay is always safe."
- `billing_activity_logs.status` defaulting to `"failed"` is worth double-checking — confirm successful operations explicitly set status, otherwise the audit log could systematically misrepresent success as failure.
