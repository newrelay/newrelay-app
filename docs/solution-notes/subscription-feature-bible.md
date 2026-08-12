# 📖 FEATURE BIBLE: Subscription & Billing Management (v2 — Dual Razorpay Provider)

> **Purpose of this doc:** Is single file mein feature ka poora context hai — kya hai, kyun hai, kaise kaam karega, aur AI coder ko exactly kya instruct karna hai. Isse copy karke naye feature ke liye fill karo, phir Claude Code / Antigravity / Cursor ko de do as context.

**Status:** `Draft / In Progress`
**Owner:** Chandresh
**Last updated:** 2026-07-15
**Related module:** Enterprise Billing, Razorpay International Payment Gateway, Super Admin Controls
**Supersedes:** v1 (dual Stripe + Razorpay design)

---

## 0. WHY THIS VERSION CHANGED

v1 mein Stripe (international) + Razorpay (domestic) dual-provider plan tha. Do issues mile:

1. **Compliance risk:** Newrelay ek Indian-registered entity hai. Stripe ne apna India PA-CB (Payment Aggregator–Cross Border) licence July 2024 mein surrender kar diya — matlab Indian entity ke liye Stripe se cross-border payments legally lena ab clean path nahi raha.
2. **Unnecessary complexity:** We attempted a single-provider Razorpay setup, but **confirmed that we need TWO separate Razorpay accounts** (one for India, one for International) to properly handle domestic UPI vs cross-border billing.

**Decision:** We will use **Razorpay** for everything, but with **TWO separate merchant accounts**. We will maintain two sets of API keys (India & International) and route users at checkout based on IP Geolocation (with a manual override for Indian customers using VPNs).

---

## 1. WHAT — Feature Summary

**One-liner:** A dual-account Razorpay subscription billing system where Super Admins define plans with multi-currency pricing, and Account Admins subscribe via the appropriate Razorpay account (India vs International) based on geolocation.

**Elevator pitch:** The Subscription and Billing feature introduces a billing engine built on Razorpay, utilizing two separate merchant accounts to cleanly separate domestic (UPI, netbanking) and cross-border (international cards, Apple Pay) payments. Super Admins configure plans and per-currency pricing without deployments. Account Admins subscribe, upgrade/downgrade with proration, and see real-time usage against their quota.

**Who needs this:** 
1. **Super Admins**: Need a centralized place to configure plans, limits, and monitor all platform subscriptions.
2. **Account Administrators (Front Admin)**: Need a self-serve dashboard to choose plans, handle payments, and track usage.

**What happens without it:** Plan changes need engineering time; without proper compliance documentation (eFIRC), export income from international SaaS customers becomes a manual accounting/CA headache — directly relevant since Newrelay is GST-registered in Jodhpur.

**Business value:** Using two Razorpay accounts maintains compliance separation (auto-eFIRC per international transaction), while still allowing us to build against a single Provider API interface (Razorpay), keeping dev overhead much lower than integrating a completely different provider like Stripe.

---

## 3. USER STORIES

- As a **Super Admin**, I want **to create, edit, and disable subscription plans**, so that **I can change pricing and limits without developer intervention**.
- As a **Super Admin**, I want **to view all active subscriptions across accounts**, so that **I can track MRR and overall usage**.
- As an **Account Administrator (Front Admin)**, I want **to view available plans and select one**, so that **I can upgrade my account limits**.
- As an **Account Administrator (Front Admin)**, I want **to pay via Razorpay (India/International) based on my geolocation**, so that **I can successfully complete the checkout process**.
- As an **Account Administrator (Front Admin)**, I want **to view my current subscription plan and limits**, so that **I know how much of my quota I have consumed**.

---

## 4. SCOPE

### ✅ In Scope
- **Super Admin Interface**: UI/API to create/update plans (Name, Price, Limits, Razorpay Plan ID for India/Intl).
- **Dual Razorpay Subscriptions**: Routing checkout to India vs Intl account based on IP Geolocation.
- **Webhook Handlers**: Process `subscription.activated/charged` from Razorpay with idempotency guards.
- **Frontend Admin UI**: Upgraded Billing page to display dynamically fetched plans.
- **Account Limits Tracking**: Enforcing usage limits based on the selected plan.
- **Billing Lifecycle**: 14-day free trial, Dunning (Day 1, 3, 7), and prorated upgrades/downgrades.

### ❌ Out of Scope (explicitly excluded)
- Self-hosted community edition (OSS) environments (billing is an Enterprise-only overlay).

### 🔮 Future / Phase 2 (noted but not now)
- Automated tax calculation (e.g., Stripe Tax).

---

## 5. HOW IT ACTIVATES — Trigger & Lifecycle

**Activation trigger:**
- Super Admin sets up plans in the Super Admin dashboard.
- Account Admin navigates to the Billing page, selects a plan, and system auto-detects payment account.

**Preconditions:** 
- Valid API credentials for **both** India and International Razorpay accounts in the `.env` file.

**Lifecycle states:**
| State | Meaning | Next state trigger |
|---|---|---|
| `pending` | Customer creation/checkout session active | Successful payment webhook |
| `active` | Subscribed to a plan and provider customer ID stored | Webhook fires for renewal/cancellation |
| `past_due` | Payment failed (Dunning) | User updates payment method |
| `disabled` | Subscription cancelled / Account marked for deletion | Resubscribe |

---

## 6. EXTERNAL DEPENDENCIES & LEAD TIME

| Dependency | Needed for | Who applies | Approval/setup time | Status | Blocker risk |
|---|---|---|---|---|---|
| Razorpay merchant KYC (India) | Domestic payments | Admin | 1-3 days | `pending` | High |
| Razorpay merchant KYC (Intl) | Cross-border payments | Admin | Confirm with Razorpay | `to verify` | High |
| Webhook secrets (x2) | Verifying incoming events from both accounts | Admin | Instant | `pending` | High |
| GST invoicing rule confirmation | Validating the 18% / 0% split | Admin/CA | Days | `pending` | Medium |

---

## 7. DATA MODEL

**New/modified tables:**
```
plans (New Table)
  - id, name, description, limits, active
  - plan_prices (Nested or related): currency, amount, razorpay_plan_id

subscriptions (New Table)
  - id, account_id, plan_id, status, provider, provider_subscription_id, current_period_end

invoices (New Table)
  - id, subscription_id, razorpay_payment_id, amount, currency, status, gst_amount, invoice_number

processed_webhook_events (New Table)
  - id, razorpay_event_id, razorpay_account_type, processed_at

accounts (Modified)
  - custom_attributes: { subscription_provider: 'razorpay', ... }
```

---
.en
## 8. BACKEND / API

**Endpoints:**
| Method | Route | Purpose | Auth |
|---|---|---|---|
| `GET/POST` | `/super_admin/plans` | CRUD plans with multi-currency pricing | Super Admin |
| `POST` | `/enterprise/api/v1/accounts/:id/checkout` | Geo-route to correct Razorpay account | Admin (Front) |
| `POST` | `/enterprise/webhooks/razorpay/:type` | Handle India/Intl webhooks separately | Razorpay Sig |

**Existing patterns to follow:** 
- Abstract billing logic into provider-agnostic services. All billing logic must remain inside the `enterprise/` directory.

---

## 9. FRONTEND / UI

**Screens/components touched:**
- **Super Admin**: Plan management dashboard supporting multiple currencies.
- **Front Admin**: Billing settings fetching plan pricing dynamically based on user's region.

---

## 10. FLOW — Step by Step

1. **Plan Creation**: Super Admin adds a `plan_price` row per currency (INR + USD minimum).
2. **Plan Selection**: Front Admin sees plans in their detected currency.
3. **Checkout**: Backend detects IP, routes to India/Intl Razorpay account.
4. **Webhook**: Handler checks signature for specific account, guards with `processed_webhook_events`.
5. **Upgrade/Downgrade**: Proration via Razorpay API, update `subscriptions` record.
6. **Failure**: Dunning retries on Day 1, 3, 7, then cancellation.

---

## 11. EDGE CASES & FAILURE MODES

| Scenario | Expected behavior |
|---|---|
| VPN User in India shows Intl pricing | Allow manual override to switch to India account |
| Webhook duplicate | Filter via `processed_webhook_events` index |

---

## 12. NON-FUNCTIONAL REQUIREMENTS

- **Security:** Strict webhook verification for both accounts.
- **Scalability:** Async processing via Sidekiq.

---

## 13. AI IMPLEMENTATION INSTRUCTIONS

**Tech stack:** Rails + Vue.js + Razorpay Gem. All billing logic in `enterprise/`.

**Step-by-step:**
1. Database setup (Plans, Subscriptions, Invoices, Webhook log).
2. Service layer for Dual-Razorpay routing.
3. Super Admin UI for multi-currency plan definitions.
4. Front Admin checkout flow with auto-detect/manual override.
5. Webhook logic with idempotency checks.

---

## 14. ROLLOUT PLAN

- **Rollout order:** Internal Testing -> Beta Accounts -> All Users.
- **Success metric:** Payments processed successfully through both India/Intl accounts.

---

## 15. RESOLVED DECISIONS (from Grill-Me session)

- **Razorpay Merchant Setup:** We will use TWO separate Razorpay accounts (one for India, one for International).
- **Checkout Routing:** Backend will detect user's country via IP Geolocation to enforce the correct Razorpay account. Users can manually override this at checkout to select 'India' (e.g. if using a VPN).
- **Trial Period:** Yes, we will implement a standard 14-day free trial period before forcing a subscription.
- **Dunning Retry Schedule:** Failed payments will be retried on Day 1, Day 3, and Day 7. If payment still fails on Day 7, the subscription is canceled.
- **GST Invoicing:** Engineering default hardcoded values: 18% GST for India billing accounts, 0% for International (Export).
