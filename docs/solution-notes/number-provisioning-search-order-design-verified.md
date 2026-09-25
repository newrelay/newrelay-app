# Number Provisioning: Search → Pick → Order — Verified Design

> **Status:** Draft, corrected after independent verification · **Owner:** TBD · **Scope:** the "admin searches a number → picks one → orders it" flow, India→Exotel / US→Telnyx (fixed) · **Branch:** `feature/phone-reseller` · **Pipeline:** produced by a 3-stage research → design → verify pass; this document is the *corrected* output, not the raw draft — see §7 for what was wrong in the draft and why.
>
> **Related docs:** [telnyx-twilio-parity-frd.md](telnyx-twilio-parity-frd.md) · [telnyx-virtual-number-purchase-implementation-spec.md](telnyx-virtual-number-purchase-implementation-spec.md) · [adr-exotel-india-sms-provider.md](adr-exotel-india-sms-provider.md) · [number-provisioning-reseller-architecture-design.md](number-provisioning-reseller-architecture-design.md) · [number-provisioning-vendor-findings-and-open-questions.md](number-provisioning-vendor-findings-and-open-questions.md)

## Readiness verdict: §1a is now decided (below). Three things remain before implementation starts (§1b-1d).

---

## 1. Must-fix before implementation starts

### 1a. This is a billing feature. Billing already exists in this repo — use it, don't route around it. **Decided.**

**Decision (2026-09-25, confirmed by requester): keep `NumberProvisioning::ROUTES` and `PaymentGatewayRegistry` separate.** They answer different questions — which telephony carrier provisions a number vs. which payment processor bills the account — and coincidentally both split on `'IN'` today, but a customer's payment processor and their number's carrier aren't inherently the same decision. `NumberProvisioning::ROUTES` stays in OSS, unchanged in shape. The markup/margin/billing_reference piece moves under `enterprise/`, wired to the real billing plumbing (`Subscription`, `topup_fulfillment_service.rb`'s idempotent-charge pattern via `account.with_lock` + `already_fulfilled?(payment_ref)`) — not to `PaymentGatewayRegistry` itself, just to the same underlying billing/subscription system it also uses.

**Confirmed, corrects an earlier draft of this design that claimed no billing system exists:** `Gemfile:169` has `gem 'stripe', '~> 18.0'`; `app/models/subscription.rb` has a full subscription model (`payment_provider` inclusion `%w[stripe razorpay]`); `enterprise/app/services/enterprise/billing/` has 32 services including `topup_fulfillment_service.rb` (idempotent fulfillment via `account.with_lock` + `already_fulfilled?(payment_ref)` — exactly the "don't double-charge on webhook retry" mechanism this feature needs); a `billing_coupons` table exists; there is an **active in-flight billing branch** (`claude/billing-frd-verification`, latest commit `fix(billing): dedupe Razorpay webhooks on the real per-delivery event id`).

**Consequence 1 — country→provider routing stays separate from `PaymentGatewayRegistry`, deliberately.** `enterprise/app/services/enterprise/billing/payment_gateway_registry.rb` does the same India-vs-rest-of-world split for *payment gateway* selection (`resolve_provider_for_country`, config-driven via `InstallationConfig['BILLING_PAYMENT_GATEWAYS']`, Super Admin-editable, wildcard fallback). `NumberProvisioning::ROUTES = { 'IN' => ExotelProvider }.freeze` answers a different question — which telephony carrier provisions the number — and per the decision above, stays a separate, hardcoded OSS concern. Not a duplicate to reconcile; two routers for two different resolutions that happen to share a split today.

**Consequence 2 — the OSS/EE boundary. Decided:** `app/services/number_provisioning/*` (search/order mechanics, both adapters) stays OSS — it's provider-agnostic infrastructure, not a billing decision. The markup/margin/billing computation moves under `enterprise/`, per CLAUDE.md's Enterprise Edition Notes and matching every other billing concern in this codebase (`Channel::TwilioSms`, `SuperAdmin::AppConfigsController` both end in `prepend_mod_with`). Concretely: an `Enterprise::NumberProvisioning::OrderBillingService` (or similar, under `enterprise/app/services/enterprise/number_provisioning/`) computes `margin_cents` and writes `billing_reference`, called from the OSS controller/job via `prepend_mod_with`-style extension rather than the OSS layer knowing about billing internals directly.

**Consequence 3 — the `Order` table's billing columns stop being placeholders.** `margin_cents`/`billing_reference` can now point at real things: `billing_reference` → whatever `record_payment_transaction_service` produces; `margin_cents` → next to wherever `Enterprise::Billing::CloudPlans` pricing config lives (not independently traced in this pipeline — read that file before finalizing the column's meaning).

### 1b. The controller sketch will 500 on its first request

`authorize ::Inbox` in a `search` action dispatches to `InboxPolicy#search?`, which doesn't exist (`app/policies/inbox_policy.rb` has no `search?`; `app/policies/application_policy.rb` has no catch-all — Pundit raises `NotDefinedError` immediately). **Fix:** write `NumberProvisioning::OrderPolicy` with `create?`/`search?`, modeled on `app/policies/comment_automation/campaign_policy.rb` (a real namespaced-policy-with-custom-action precedent already in this repo).

### 1c. `channel_id` must be `bigint`, or drop the polymorphic pair entirely

`inboxes.channel_id` is `integer` (int4) only because that table is legacy `id: :serial` — copying it literally onto a new bigint-PK table would create a column that can't hold real bigint channel IDs. Simpler fix: since `inboxes` already carries `channel_id`/`channel_type`, the order just needs a nullable `inbox_id` FK (set once the order goes `active`) instead of its own polymorphic pair.

### 1d. Use `comment_automation` as the structural template, not `twilio_channels_controller`/`Twilio.vue` alone

`app/models/comment_automation.rb` + `app/services/comment_automation/`, `app/jobs/comment_automation/`, `app/policies/comment_automation/`, `config/routes.rb:122-133`'s nested-namespace-plus-collection-action shape, and `app/jobs/comment_automation/dm_dispatch_job.rb` (bounded self-reschedule with an attempt cap — the real shape for a status-polling job, not the 6-line webhook passthrough `twilio_delivery_status_job.rb` is) are all closer matches to this feature's actual shape (a namespaced, multi-file, async-completing resource) than the single-file `TwilioChannelsController`/`Twilio.vue` pair. Use `comment_automation`'s file layout as the skeleton.

---

## 2. Backend data model

**Migration** (adjust for §1a's OSS/EE decision and §1c's `inbox_id` fix before writing):

```ruby
# db/migrate/<ts>_create_number_provisioning_orders.rb
class CreateNumberProvisioningOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :number_provisioning_orders do |t|
      t.bigint :account_id, null: false
      t.bigint :inbox_id                                # set once status becomes 'active'; see §1c
      t.string :provider_type, null: false               # 'telnyx' | 'exotel'
      t.string :provider_order_id
      t.string :phone_number
      t.string :country_code, null: false
      t.string :status, null: false, default: 'search_pending'
      # search_pending | order_placed | requirements_pending | requirements_under_review
      # | requirements_rejected | active | failed | cancelled
      t.jsonb :regulatory_requirements, null: false, default: {}
      t.datetime :requirements_deadline_at
      t.integer :provider_cost_cents
      t.integer :margin_cents                            # meaning TBD pending §1a's billing decision
      t.string :billing_reference                         # points at real billing record once §1a is decided
      t.string :provisioning_error

      t.timestamps
    end

    add_index :number_provisioning_orders, :account_id
    add_index :number_provisioning_orders, :status
    add_index :number_provisioning_orders, :inbox_id
    add_index :number_provisioning_orders, [:provider_type, :provider_order_id],
              unique: true, where: 'provider_order_id IS NOT NULL'

    add_foreign_key :number_provisioning_orders, :accounts
  end
end
```

Confirmed schema-valid and non-conflicting: current schema version is `2026_09_23_143000`; no `number_provisioning_orders`/`channel_telnyx_sms`/`channel_exotel_sms` exists yet; `accounts` is a valid FK target (used elsewhere, e.g. `billing_activity_logs`).

**Model:** `app/models/number_provisioning/order.rb` — confirmed-correct shape (verified against `app/models/billing_activity_log.rb:33,39`, which uses exactly this pattern already): plain `ApplicationRecord`, `belongs_to :account`, `belongs_to :inbox, optional: true`, `STATUSES = %w[search_pending order_placed requirements_pending requirements_under_review requirements_rejected active failed cancelled].freeze`, `validates :status, inclusion: { in: STATUSES }`.

**Namespace note:** `NumberProvisioning::Order` (model, under `app/models/`) alongside the existing `app/services/number_provisioning/*` (services) is a real, precedented Zeitwerk layout in this repo — `CommentAutomation` and `Reputation` both do the equivalent split (explicit namespace file in one tree, implicit directory in another). Expected to autoload cleanly; not runtime-verified in this pipeline (no server boot was performed) — confirm with a real `rails runner` load before merging.

**Channel models:** `Channel::TelnyxSms`/`Channel::ExotelSms` don't exist yet and are correctly out of this flow's critical path except at the very end. When built, mirror `Channel::TwilioSms` (`encrypts ... if Chatwoot.encryption_configured?`, `EDITABLE_ATTRS`, ending in `prepend_mod_with('Channel::TelnyxSms')`).

---

## 3. Backend service layer

### 3a. Price normalization — confirmed real gap, deliberately not solved here

`TelnyxProvider#search` returns `response.parsed_response['data']` raw; `ExotelProvider#search` returns `response.parsed_response` raw — different shapes (`rental_price` vs. `cost_information.monthly_cost`), neither logged anywhere in the repo as a real captured response. **Do not invent the field mapping or currency units** — no VCR cassette, spec fixture, or seed data exists for either provider's real response shape. Capture one real response from each before writing a `NumberProvisioning::SearchResult` normalizer that maps to `{ phone_number:, monthly_price_cents:, currency:, capabilities:, raw: }`.

### 3b. Credential model

**Telnyx — delete the `Integrations::Hook` fallback, use `GlobalConfig`.** Corrected reasoning (the original draft's reasoning was wrong even though its conclusion was right): the Hook branch is not dead code — `hooks_controller.rb` has no registered-app allowlist, and `Integrations::Hook`'s validations short-circuit (`return if app.blank?`) for unregistered `app_id`s like `'telnyx'`. **Any account admin can create a working `telnyx` hook today**, and `telnyx_provider.rb`'s current code would silently prefer it over the platform key — a real billing hole under a reseller model (order lands on the tenant's own Telnyx account while NR's `Order` row records cost/margin against a number NR doesn't own). Replace `ENV.fetch('TELNYX_API_KEY', nil)` with `GlobalConfig.get_value('TELNYX_RESELLER_API_KEY')` and delete the Hook branch entirely. Register the new key in `config/installation_config.yml` (same shape as `CAPTAIN_OPEN_AI_API_KEY`) and in `SuperAdmin::AppConfigsController#allowed_configs`.

**Exotel — genuinely unresolved, do not guess.** Unlike Telnyx, `'exotel'` **is** a registered app with a real settings form already in active use (the existing inbound-IVR feature, BYO). Nothing in any doc says whether *purchased* India numbers should use a reseller `GlobalConfig.get_value('EXOTEL_RESELLER_API_KEY')` or the customer's existing BYO Exotel hook. Leave `exotel_provider.rb`'s credential lookup untouched until a human decides — flagged, not resolved, across two independent passes of this pipeline.

### 3c. Interface extension

Add `status(provider_order_id:)` to `NumberProvisioning::Provider` (both adapters need it for the polling job). **Do not add `reserve`/`lookup_requirements`/`submit_requirements`/`configure_webhook` speculatively** — Exotel's reservation concept is confirmed unconfirmed (ADR follow-up item 3); building an abstraction shaped around Telnyx's known 30-minute-reservation semantics before Exotel's equivalent is known risks being the wrong shape. Telnyx's real reservation requirement is a known gap/fast-follow, not a blocker for a first cut.

### 3d. Polling job

Model on `app/jobs/comment_automation/dm_dispatch_job.rb` (bounded self-reschedule, attempt cap, explicit terminal failure path), **not** `webhooks/twilio_delivery_status_job.rb` (a 6-line one-shot webhook handler with no polling shape at all). If Telnyx or Exotel emit order-status webhooks instead of requiring polling, prefer that — not verified either way in this pipeline. If a scheduled sweep is wanted instead of self-rescheduling, this repo's recurring-job mechanism is confirmed: sidekiq-cron via `config/schedule.yml`.

---

## 4. Backend controller + routes

Structure on `app/controllers/api/v1/accounts/comment_automation/campaigns_controller.rb`'s pattern (`authorize(@resource || Namespace::Model)`, not the bare-class stand-in), not a literal copy of `twilio_channels_controller.rb`. Real, load-bearing differences from the Twilio precedent, confirmed necessary:

- **No live-credential pre-check before creating the order row** — there's nothing customer-supplied to validate up front once §3b's platform-credential model is in place; failure surfaces naturally when `.order` raises.
- **No synchronous `Channel`/`Inbox` creation** — a purchased number isn't active on order placement (seconds for US, potentially days for India KYC); channel/inbox creation happens in the polling job on `status == 'active'`.
- Pass the policy class explicitly to `check_authorization` (`Api::V1::Accounts::BaseController`'s default resolves off `controller_name.classify`, which would try to constantize `::Order` and fail).
- **`CheckAccountLimits`** (already a `before_action` on `Api::V1::Accounts::BaseController`) is the existing hook for plan/limit gating — a paid number purchase should almost certainly interact with it; not designed here, flagged as directly relevant.

**Routes**, following the `comment_automation` nested-namespace-plus-collection-action shape already used in this file (`config/routes.rb:122-133`), not the single-line `resource :twilio_channel` shape:

```ruby
namespace :number_provisioning do
  resources :orders, only: [:create] do
    collection { get :search }
  end
end
```

Confirmed non-colliding — no existing `number_provisioning` route; only the unrelated `resource :exotel` (inbound-IVR webhook) currently touches Exotel.

---

## 5. Frontend

**No search→pick→order UI precedent exists anywhere in this codebase** — confirmed by two independent search passes (across all of `app/javascript`, all `components-next/` subdirectories, and `components-next/relay/`). This is new UX, not an adaptation of a hidden pattern.

**Model the form on `Voice.vue`, not `Twilio.vue`.** Corrected: the original draft recommended mirroring `Twilio.vue`'s patterns, but `Twilio.vue` opens with its own deprecation comment and uses the Options API — CLAUDE.md requires Composition API with `<script setup>`. `Voice.vue` (same telephony domain) already uses `<script setup>`, `useVuelidate`, `RelayButton`/`RelayInput`, the byte-identical `INPUT_CLASS` Tailwind constant, and route-query-driven provider selection — it's the correct, modern-pattern precedent that was missed in the first pass.

**Country selector, not provider selector**, as the entry point — provider is derived from country by `NumberProvisioning.for` (never taken as a caller argument), so the UI shouldn't expose it as a choice. `Sms.vue`'s `ComboBox`-driven provider switch is the wrong shape for this specific screen (it's right for BYO flows where the admin picks a provider; wrong here where the backend already decided).

**API client**: `app/javascript/dashboard/api/numberProvisioningOrders.js` (flat, matching the `commentAutomationCampaigns.js` convention for namespaced non-channel resources — `super('number_provisioning/orders', { accountScoped: true })`), not nested under `api/channel/`.

**Store actions**: mirror `createTwilioChannel`'s shape in `store/modules/inboxes.js` (UI-flag commit → API call → `ADD_INBOXES` → flag reset, `throw` on failure) for the final `active` case; the search step needs its own, simpler action (no store mutation needed beyond holding search results locally in the component, since results aren't persisted state).

**Genuinely new UI problem, not resolved anywhere**: what shows between "order placed" and "active" — a US number may activate in seconds, an India number can take days pending KYC. No precedent in this codebase for a polling-status interstitial. Recommend (not validated against anything existing, since nothing like it exists here) a lightweight provisioning-status page that polls `GET number_provisioning/orders/:id` and redirects to `settings_inboxes_add_agents` on `active`, or shows a KYC-required state on `requirements_pending`.

**India KYC document-upload UI is explicitly out of scope for this flow** — but note precisely: the FRD states Phase 1 *must* include a real document-submission UI, so shipping search→pick→order without it means this design does not complete Phase 1 as the FRD defines it; it's a legitimate phasing call, not a scope reduction that satisfies the FRD on its own. Also: the FRD's KYC discussion is written for Telnyx; under the confirmed India→Exotel routing, India KYC is actually Exotel/DLT-shaped, and that shape is confirmed unconfirmed (ADR follow-up item 4) — the eventual KYC UI can't be designed from the FRD's Telnyx-specific description alone.

---

## 6. Implementation order

1. ~~Decide §1a~~ **Done** — kept separate; OSS gets `app/services/number_provisioning/*`, EE gets the markup/billing service.
2. Migration (§2, with §1c's `inbox_id` fix) → model.
3. Service layer: add `status()` to the interface and both adapters; fix Telnyx credentials (§3b); leave Exotel credentials untouched pending decision; register `TELNYX_RESELLER_API_KEY`.
4. Policy: `NumberProvisioning::OrderPolicy` (§1b) — do this before the controller, not after, or the controller ships broken.
5. Polling job, modeled on `dm_dispatch_job.rb` (§3d).
6. Controller + routes (§4).
7. `enterprise/app/services/enterprise/number_provisioning/order_billing_service.rb` (§1a consequence 2) — computes `margin_cents`, writes `billing_reference`, called via `prepend_mod_with` from the OSS job/controller once an order reaches `active`.
8. Frontend: API client, store actions, `Voice.vue`-modeled form component + results list + provisioning-status interstitial (§5).
9. Tests: no existing spec covers `twilio_channels_controller.rb` to mirror directly — write fresh RSpec request specs for the new controller/policy/job, and `spec/enterprise/` specs for the billing service.
10. Do not enable real charges until step 7 (the EE billing service) is built and tested — the OSS pieces (1-6, 8) can ship/merge independently since they don't touch money.

---

## 7. What the draft got wrong, and why this document exists

This is the corrected output of a 3-stage pipeline (research → design → independent verification). The intermediate design draft claimed no billing system existed in this codebase and proposed a self-contained `provider_cost_cents`/`margin_cents` scheme with no connection to real billing — that claim was checked and found false (§1a): this repo has Stripe, a `Subscription` model, 32 enterprise billing services, and an existing country→payment-provider router doing almost exactly what this feature's provider-routing does. The draft also proposed a controller `authorize` call that doesn't exist on the target policy (§1b) and recommended mirroring a deprecated, Options-API frontend component instead of the correct modern one already in the same directory (§5). All three are corrected above. The remaining "not resolved" items in this document survived two independent verification passes and are genuinely open — they are not gaps in this pipeline's diligence, they're gaps in what currently exists to check against.

## Sources

Every file path cited above was opened and read directly during this pipeline's research/design/verification stages — see [number-provisioning-vendor-findings-and-open-questions.md](number-provisioning-vendor-findings-and-open-questions.md) for the vendor-side research this design builds on.

## Approval

| Gate | Who | Date |
|---|---|---|
| §1a billing/OSS-EE decision made — keep `NumberProvisioning::ROUTES` and `PaymentGatewayRegistry` separate, markup/billing under `enterprise/` | Requester (via chat) | 2026-09-25 |
| Reviewed against source FRD/ADR/Architecture Design for conflicts | TBD | TBD |
