# 🤖 CODE AGENT INSTRUCTIONS — Full Build (Phases 1–5)

> Paste the relevant phase section into Claude Code / Antigravity as task context when you start that phase. Tech stack: Rails + Chatwoot fork, Vue frontend, Stripe Connect. All new backend code lives in `enterprise/` unless stated otherwise. Work through phases in order — later phases assume earlier schema exists.

---

# PHASE 1 — Foundation & Hierarchy

**Scope:** account hierarchy schema, capability gating, Super Admin hierarchy view (read-only). **Not in scope:** billing/payment logic (Phase 3).

## Step 0 — Before writing any code
1. Inspect the existing `accounts` table schema and paste it into context — confirm exact current columns before adding new ones.
2. Search the codebase for any existing feature-flag mechanism on `Account`. **Do not build a new `Capabilities` table if one already exists** — extend it instead. Report findings before proceeding.

## Step 1 — Schema migration: account hierarchy
```ruby
class AddHierarchyToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :parent_id, :bigint, null: true
    add_column :accounts, :is_reseller, :boolean, null: false, default: false
    add_index :accounts, :parent_id
    add_foreign_key :accounts, :accounts, column: :parent_id
  end
end
```

Model (`app/models/account.rb` or the enterprise override):
```ruby
belongs_to :parent, class_name: 'Account', optional: true
has_many :children, class_name: 'Account', foreign_key: :parent_id, dependent: :nullify

validate :parent_must_be_a_reseller
validate :no_self_parenting
validate :only_two_levels_deep

private

def parent_must_be_a_reseller
  return if parent.blank?
  errors.add(:parent_id, 'must reference an account with is_reseller = true') unless parent.is_reseller?
end

def no_self_parenting
  errors.add(:parent_id, 'cannot be its own parent') if parent_id.present? && parent_id == id
end

def only_two_levels_deep
  return if parent.blank?
  errors.add(:parent_id, 'cannot set a parent that itself has a parent (max 2 tiers)') if parent.parent_id.present?
end
```

**Do NOT:**
- Allow arbitrary nesting depth — strictly 2 tiers (T2 → T3).
- Infer `is_reseller` from `parent_id.nil?` — they're independent flags.

**Acceptance criteria:**
- [ ] `Account.new(parent: non_reseller_account)` fails validation.
- [ ] Self-parenting rejected.
- [ ] Three-tier chain rejected.

## Step 2 — Capability gating (Actual Implementation)
Chatwoot utilizes a built-in feature-flag system via the `flag_shih_tzu` gem and `Featurable` concern on the `Account` model. All features are registered in `config/features.yml`.

Because `flag_shih_tzu` stores flags in a signed 64-bit integer column (`feature_flags`), it has a limit of 63 bits. To accommodate 64+ features without crashing or database migrations:
- **DB Features (index 1 to 63):** Managed directly by `flag_shih_tzu`.
- **Virtual Features (index 64+):** Managed dynamically in the account's JSONB `settings['virtual_features']` store.
- **Ancestry Precedence:** Overrides for `selected_feature_flags` and `selected_feature_flags=` are defined in a prepended `Overrides` module on the `Featurable` concern to ensure they intercept all assignments before any class-level `flag_shih_tzu` generated methods.

Gate key features like `white_labeling`, `custom_domain`, `reseller_dashboard`, and `api_access` using `feature_enabled?(:feature_name)`.

**Do NOT:** gate features with scattered `if account.is_reseller?` checks — always go through `feature_enabled?`.

## Step 3 — Super Admin: Account Hierarchy view (read-only)
- `enterprise/app/controllers/super_admin/account_hierarchy_controller.rb`
- Controller: `@resellers = Account.where(is_reseller: true).includes(:children)`
- View: list resellers, expand to show T3 children. **No link/unlink or migration UI yet** — that's Phase 5.

**Acceptance criteria:**
- [ ] Super Admin sees reseller list with expandable children.
- [ ] Empty states handled (zero resellers, reseller with zero children).

---

# PHASE 2 — Reseller (T2) Infrastructure

**Scope:** branding storage, self-service onboarding/KYC, custom domain routing. Depends on Phase 1's `is_reseller` + capability gate (`white_labeling`, `custom_domain`).

## Step 0 — Before writing any code
Confirm where Chatwoot currently reads branding (logo, colors, `brand_name`) from — likely global ENV vars or a config initializer. Identify every call site before moving this to a per-account model, so nothing is missed.

## Step 1 — Move branding into Account records
```ruby
class AddBrandingToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :brand_name, :string
    add_column :accounts, :brand_logo_url, :string
    add_column :accounts, :brand_primary_color, :string
    add_column :accounts, :brand_secondary_color, :string
  end
end
```
Replace every ENV-based branding read found in Step 0 with `current_account.brand_name || DEFAULT_BRAND_NAME` (fallback to platform default when a T2 hasn't customized yet — never show a blank/broken UI).

**Do NOT:** delete the ENV fallback entirely — accounts with `white_labeling` disabled should still render platform-default branding, not empty strings.

## Step 2 — Self-service onboarding (KYC) for T2 payment accounts
This is the Connect account creation flow specced in the Subscription Feature Bible (Section 8/13) — build it here as part of T2 onboarding:
- `enterprise/app/services/enterprise/billing/connect_onboarding_service.rb` — creates a Stripe Express connected account for the account, generates an onboarding link.
- `enterprise/app/controllers/enterprise/api/v1/connected_accounts_controller.rb` — `POST` to kick off onboarding, `GET /status` to poll.
- Store result in `connected_accounts` table (see Phase 3 — create this migration now if Phase 3 hasn't started yet, since onboarding needs it):
```ruby
class CreateConnectedAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :connected_accounts do |t|
      t.references :account, null: false, foreign_key: true
      t.string :stripe_account_id, null: false
      t.string :country, null: false
      t.string :charge_routing, null: false   # 'destination' or 'separate_charge_transfer'
      t.string :onboarding_status, null: false, default: 'onboarding_incomplete'
      t.boolean :charges_enabled, default: false
      t.boolean :payouts_enabled, default: false
      t.timestamps
    end
  end
end
```
Set `charge_routing` at creation time based on the account's country — **India connected accounts get `separate_charge_transfer`, everyone else gets `destination`** (see Phase 3 for why).

**Do NOT:** let a T2 account without a `connected_account.charges_enabled = true` publish any pricing panel (Phase 3) or accept T3 payments — gate this explicitly.

## Step 3 — Custom domain routing (CNAME)
- Add `custom_domain` column to `accounts` (string, unique index).
- Middleware/controller concern to resolve `Account` by request host when `custom_domain` is set and matches, falling back to the default subdomain routing otherwise.
- Document (don't just assume) what SSL provisioning path is used for custom domains — Chatwoot forks vary here (Cloudflare for SaaS, Let's Encrypt via a cert-manager sidecar, etc.). Confirm before building, do not guess.

**Do NOT:** allow two accounts to claim the same `custom_domain` — enforce a DB-level unique index, not just application-level validation.

**Acceptance criteria (Phase 2 overall):**
- [x] T2 branding renders correctly with and without `white_labeling` enabled.
- [x] T2 can complete Stripe Express onboarding and reach `charges_enabled = true`.
- [x] Custom domain resolves to the correct account; duplicate domain claims rejected at the DB layer.

---

# PHASE 3 — Transactional Core (Payment Manager)

**Scope:** the billing engine itself — this phase is specced in full detail in the separate Subscription & Billing Feature Bible (v3.1). Summary of what the code agent needs to build, for continuity with this PDE plan:

## Step 1 — Two distinct billing relationships
- **Case 1 (Platform subscription, T1 → T2):** plain Stripe subscription, Super Admin sets price. No Connect split.
- **Case 2 (Marketplace subscription, T2 → T3):** T2 sets their own price via a self-serve panel; commission is computed and added on top, never deducted.

## Step 2 — Data model
```ruby
# plans / plan_prices — Case 1 pricing, Super Admin owned (standard)

# marketplace_plan_prices — Case 2 pricing, agency owned
create_table :marketplace_plan_prices do |t|
  t.references :account, null: false, foreign_key: true   # the T2 client_id
  t.string :currency, null: false
  t.decimal :agency_price, null: false
  t.decimal :commission_percent, null: false
  t.decimal :platform_fee_amount, null: false   # computed: agency_price * commission_percent
  t.decimal :total_amount, null: false           # computed: agency_price + platform_fee_amount
  t.string :stripe_price_id
  t.boolean :active, default: true
  t.timestamps
end

create_table :commission_rules do |t|
  t.references :account, null: false, foreign_key: true
  t.decimal :commission_percent, null: false, default: 30.0
  t.datetime :effective_from, null: false
  t.references :created_by_user
  t.timestamps
end
```

Add to `subscriptions`:
```ruby
add_column :subscriptions, :relationship_type, :string, null: false   # 'platform' or 'marketplace'
add_reference :subscriptions, :connected_account, foreign_key: true, null: true
add_column :subscriptions, :application_fee_amount, :decimal
```

## Step 3 — Commission formula (critical — do not get this wrong)
```
platform_fee_amount = agency_price * (commission_percent / 100.0)
total_amount = agency_price + platform_fee_amount
```
Then at Stripe checkout time, pass `application_fee_amount` (the fixed computed dollar value) — **never use Stripe's `application_fee_percent` parameter for this**, since that parameter computes percent-of-total, which would shortchange the agency relative to what they set.

## Step 4 — Country-aware charge routing
```ruby
class Billing::Tier3CheckoutService
  def call
    case connected_account.charge_routing
    when 'destination'
      # single API call: charge with transfer_data[destination] + application_fee_amount
    when 'separate_charge_transfer'
      # charge lands on platform account first, then a separate Transfer
      # moves (total_amount - platform_fee_amount) to the connected account
    end
  end
end
```

## Step 5 — T2 self-serve pricing panel
- `enterprise/app/controllers/enterprise/api/v1/tier2/pricing_panel_controller.rb`
- Slider/input UI (already prototyped) writing to `marketplace_plan_prices`.
- Live preview must show: agency price → platform fee → total client price, with copy making clear the fee is additive, not deducted.

**Do NOT:**
- Conflate Case 1 and Case 2 subscriptions in the same code path.
- Let a plan price change retroactively rewrite historical `application_fee_amount` values.
- Skip idempotency keys on the checkout endpoint (double-click protection).

**Acceptance criteria:** see the Subscription Feature Bible v3.1, Section 10, for the full checklist — reuse that as this phase's definition of done.

---

# PHASE 4 — Reliability & Orphaned Tenant Logic

**Scope:** webhook idempotency, T2→T1 rescue/promotion, grace periods on payment failure.

## Step 1 — Idempotent webhooks
```ruby
create_table :processed_webhook_events do |t|
  t.string :stripe_event_id, null: false
  t.string :event_type, null: false
  t.datetime :processed_at, null: false
end
add_index :processed_webhook_events, :stripe_event_id, unique: true
```
Webhook controller/job must check-and-insert this row **before** doing any side-effecting work, inside the same transaction as the side effect where possible, so a crash mid-processing doesn't leave a half-applied duplicate-prone state.

## Step 2 — Orphaned tenant rescue hook
When a T2 (`is_reseller` account) is deleted or suspended, its T3 children must not simply lose service. Build:
```ruby
class Billing::TenantRescueService
  def call(orphaned_t3_account)
    # 1. Detach: orphaned_t3_account.update!(parent_id: nil)
    # 2. Decide new billing relationship: promote to a direct 'platform' subscription,
    #    at a price to be determined by Super Admin policy (flag for manual review,
    #    do not auto-charge an assumed price)
    # 3. Notify the T3 account holder of the change before any billing change takes effect
  end
end
```

**Do NOT:** auto-charge the promoted T3 account any price without either an explicit default platform plan or Super Admin confirmation — silently picking a number here is a billing-trust incident waiting to happen.

## Step 3 — Grace periods
```ruby
add_column :subscriptions, :grace_period_ends_at, :datetime
```
On a T2 payment failure that would otherwise cascade to suspending T3 service, set `grace_period_ends_at = Time.current + 7.days` on affected T3 subscriptions instead of immediate suspension. A scheduled job checks and suspends only once the grace period has actually elapsed and the underlying T2 issue remains unresolved.

**Acceptance criteria:**
- [ ] Replaying an identical webhook event twice produces no duplicate side effects.
- [ ] Deleting/suspending a T2 account triggers the rescue flow for every T3 child, not a silent cascade suspension.
- [ ] A T3 client's service survives 7 days past a T2 payment failure before any suspension occurs.

---

# PHASE 5 — Chatwoot Super Admin & Governance

**Scope:** the mutation and audit tooling that Phase 1's read-only hierarchy view deliberately deferred.

## Step 1 — Reseller Management dashboard
- Extend the Phase 1 `account_hierarchy_controller` from read-only to support:
  - Toggling `is_reseller` on any account (with a confirmation step — this changes what validations apply to its children).
  - Manually linking/unlinking a T3 account to/from a T2 parent (reuses the Phase 1 model validations, so an invalid link is rejected at the model layer automatically).

## Step 2 — Financial Ledger Audit
- Global view aggregating `invoices` + `subscriptions.application_fee_amount` across all `connected_accounts` — total commission earned, filterable by date range and by T2 account.
- **"Stuck Payouts" view:** connected accounts where `payouts_enabled = false` or `onboarding_status = 'restricted'`, surfaced with the specific missing requirement pulled from Stripe's account object, not just a generic "blocked" label — Super Admin needs to know what to tell the agency to fix.

## Step 3 — Tenant Migration UI
- "Migrate Tenant" action: reassign a T3 account's `parent_id` from one T2 to another.
- Must carry over: active `marketplace_plan_prices` subscription state (or explicitly flag it for repricing under the new T2 — do not silently keep charging the old T2's price under a new parent without confirmation), full subscription/invoice history (never delete, only re-parent).

**Do NOT:** allow a tenant migration to silently drop billing history — this is an audit trail, treat deletion of `subscriptions`/`invoices` rows as forbidden in this flow entirely.

## Step 4 — Global Resource Quotas & Plan Management (Actual Implementation)
- **Plan Management console** (`app/controllers/super_admin/plan_management_controller.rb`):
  - View features and set per-agent prices for **Starter** and **Business** plans.
  - Features toggles and pricing details are saved back to `InstallationConfig` keys `CHATWOOT_CLOUD_PLANS` and `CHATWOOT_CLOUD_PLAN_FEATURES`.
  - Seeding logic is automatically run on first visit if the config parameters are blank.
- **Local development Stripe Fallback:**
  - `CreateSessionService` redirects local developers to `/super_admin/plan_management` when Stripe billing session creation fails due to missing credentials, avoiding server crash errors.
- **Resource Quotas:**
  - Extend the Phase 1 `account_capabilities` pattern with a companion `account_limits` table (numeric caps) rather than overloading the boolean capability table with numeric values.
```ruby
create_table :account_limits do |t|
  t.references :account, null: false, foreign_key: true
  t.string :limit_key, null: false     # e.g. 'monthly_messages', 'agent_seats', 'contacts'
  t.integer :limit_value, null: false
  t.timestamps
end
add_index :account_limits, [:account_id, :limit_key], unique: true
```

**Acceptance criteria:**
- [x] Super Admin can toggle `is_reseller` and manually re-parent a T3 account.
- [x] Super Admin can manage Starter & Business plan details, toggle features, and update prices in Plan Management.
- [ ] Financial ledger view shows accurate aggregate commission, filterable.
- [ ] Stuck Payouts view surfaces the specific Stripe requirement blocking each account.
- [ ] Tenant migration preserves full billing history under the new parent.
- [x] Per-reseller resource limits are enforced and visible to Super Admin.

---

# PHASE 6 — Plan Tiers & Feature Limits (Hobby / Standard / Business / Enterprise)

**Scope:** every feature gets an associated numeric limit (not just an on/off toggle), and the platform ships four named plans with an industry-standard limit matrix. Depends on Phase 1 (`account_capabilities`, `account_limits`) and Phase 5's existing `CHATWOOT_CLOUD_PLANS`/`CHATWOOT_CLOUD_PLAN_FEATURES` config.

## Step 0 — Before writing any code
1. Pull the current `CHATWOOT_CLOUD_PLANS` and `CHATWOOT_CLOUD_PLAN_FEATURES` `InstallationConfig` values from a running instance and paste them into context — Phase 5 already seeded Starter/Business, confirm exact current keys before renaming/restructuring to the new 4-plan set.
2. Confirm whether `account_limits` (Phase 5) is currently populated per-account only, or also has a plan-level default — Phase 6 needs a **plan → default limits** mapping that gets copied onto `account_limits` at subscription time, then can be overridden per-account (e.g. a negotiated custom deal for one Enterprise client).

## Step 1 — Every feature gets a limit, not just a flag

Today (Phase 1/5) `account_capabilities` is boolean-only (on/off) and `account_limits` is a separate free-standing numeric table. Unify these so **every gated feature has both**: whether it's enabled, and how much of it the account gets.

```ruby
class CreatePlanFeatureLimits < ActiveRecord::Migration[7.0]
  def change
    create_table :plan_feature_limits do |t|
      t.string :plan_key, null: false        # 'hobby' | 'standard' | 'business' | 'enterprise'
      t.string :feature_key, null: false      # matches flag_shih_tzu / virtual_features keys
      t.boolean :enabled, null: false, default: false
      t.integer :limit_value                  # nullable = unlimited
      t.timestamps
    end
    add_index :plan_feature_limits, [:plan_key, :feature_key], unique: true
  end
end
```

On subscription activation (or plan change), copy the matching `plan_feature_limits` rows into that account's `account_capabilities` (enabled) + `account_limits` (limit_value) — **do not** have runtime code read `plan_feature_limits` directly on every request; the account-level tables remain the source of truth for enforcement, `plan_feature_limits` is just the template.

**Do NOT:** let a limit of `nil` be confused with `0` — `nil` means unlimited (Enterprise), `0` means the feature is fully unavailable. A truthy-check bug here (`if limit_value` treating `0` as falsy in some languages, though not in Ruby) is a classic source of "why do Enterprise accounts have zero contacts" bugs — be explicit: `limit_value.nil? ? :unlimited : limit_value`.

## Step 2 — Industry-standard 4-plan limit matrix

Seed data for `plan_feature_limits` (adjust exact numbers to your pricing, but keep this general shape — it mirrors how GoHighLevel/Chargebee-style multi-tenant CRM platforms structure their tiers, in particular tying **sub-account/reseller count to plan tier**, since that's the core of your 3-tier model):

| Feature / Limit | Hobby | Standard | Business | Enterprise |
|---|---|---|---|---|
| Seats (team members) | 1 | 5 | 20 | Unlimited |
| Contacts | 500 | 5,000 | 50,000 | Unlimited |
| Conversations/month | 200 | 2,000 | 20,000 | Unlimited |
| **T3 sub-accounts (reseller capacity)** | 0 (`is_reseller` cannot be enabled) | 3 | 25 | Unlimited |
| White-labeling / custom branding | ❌ | ❌ | ✅ | ✅ |
| Custom domain | ❌ | ❌ | ✅ | ✅ |
| API access | ❌ | Read-only | Full | Full + higher rate limit |
| Automations/workflows | 3 | 15 | Unlimited | Unlimited |
| AI credits/month | 0 | 100 | 1,000 | Custom/negotiated |
| Support | Community | Email | Priority email | Dedicated + SLA |

**Do NOT:** hardcode "Hobby = 0 sub-accounts" as a special-case `if plan == 'hobby'` scattered in the reseller-onboarding controller — enforce it the same way as every other limit, by checking `account_limits` for `t3_subaccount_count` before allowing `is_reseller` to be set to `true` or before a new T3 signup under that T2. One enforcement path for all limits, no exceptions carved out per-feature.

## Step 3 — Enforcement points

Every action that consumes a limited resource must check before proceeding, not just display the limit in UI:
- Creating a new T3 sub-account under a T2 → check `t3_subaccount_count` against current children count.
- Adding a team member → check `seats` against current agent count.
- Sending a message/conversation → check `conversations_per_month` against a rolling counter (reset monthly — decide whether this resets on calendar month or on subscription anniversary, and be explicit about it, don't leave it ambiguous).

```ruby
# concern, included wherever a limited action happens
module EnforcesAccountLimit
  def enforce_limit!(account, limit_key, current_count)
    limit = account.account_limits.find_by(limit_key: limit_key)&.limit_value
    return if limit.nil? # unlimited
    raise Billing::LimitExceededError, limit_key if current_count >= limit
  end
end
```

**Do NOT:** enforce limits only at the UI layer (disabling a button) — always enforce server-side too, since API access exists as a plan feature itself and a limit that's only UI-enforced is trivially bypassed via direct API calls.

## Step 4 — Plan comparison + usage UI

- Super Admin: extend the existing Phase 5 `plan_management_controller` to manage all four plans' `plan_feature_limits` rows (not just Starter/Business pricing as it does today).
- Front Admin (T2): a plan comparison view (reuse standard pricing-table UI patterns) plus a **usage dashboard** showing current consumption vs. limit for each metered feature (e.g. "18/25 sub-accounts used") — this is what drives natural upgrade prompts, so make the "you're near your limit" state visually distinct, not just a number.

**Acceptance criteria:**
- [ ] All four plans (`hobby`, `standard`, `business`, `enterprise`) exist in `plan_feature_limits` with a complete row per feature — no feature silently falls back to "unlimited" by omission.
- [ ] Hobby accounts cannot enable `is_reseller`; Standard/Business are capped at their sub-account count; Enterprise is uncapped.
- [ ] Every limited action is enforced server-side, independent of UI state.
- [ ] Plan upgrade/downgrade correctly re-copies the new plan's `plan_feature_limits` onto the account (existing usage above a new, lower limit should be flagged, not silently truncated — e.g. a Business→Standard downgrade with 10 existing sub-accounts against a new cap of 3 needs a resolution decision, not silent data loss).
- [ ] Usage dashboard accurately reflects current consumption vs. plan limit per feature.

## Step 5 — Enterprise: custom pricing & contracts (industry-standard "Contact Sales" model)

Enterprise is fundamentally different from the other three plans: pricing and specific limits are **negotiated per customer**, not fixed in a shared `plan_feature_limits` row. Do not try to force Enterprise into the same self-serve checkout flow as Hobby/Standard/Business.

**Architecture:** the `enterprise` row in `plan_feature_limits` remains only a **baseline/floor** (mostly "unlimited" defaults). Actual negotiated terms live in a separate per-account contract table that overrides the baseline:

```ruby
class CreateEnterpriseContracts < ActiveRecord::Migration[7.0]
  def change
    create_table :enterprise_contracts do |t|
      t.references :account, null: false, foreign_key: true
      t.decimal :negotiated_price, null: false
      t.string :currency, null: false
      t.string :billing_interval, null: false        # 'monthly' | 'annual'
      t.string :collection_method, null: false, default: 'send_invoice'  # vs 'charge_automatically'
      t.integer :payment_terms_days, default: 30      # net-30 typical for enterprise invoicing
      t.date :contract_start_date, null: false
      t.date :contract_end_date, null: false
      t.boolean :auto_renew, default: false
      t.jsonb :negotiated_limit_overrides, default: {}  # e.g. { "ai_credits_per_month": 50000 }
      t.references :negotiated_by_user                 # audit: which Super Admin/sales rep closed this
      t.text :notes
      t.timestamps
    end
  end
end
```

**Onboarding flow (deliberately not self-serve):**
1. Public pricing page shows Hobby/Standard/Business with self-serve checkout, but Enterprise shows a **"Contact Sales"** CTA — a lead-capture form, not a checkout button.
2. Lead comes into Super Admin (or a CRM if one is wired up separately) for a sales conversation.
3. Once terms are agreed, a Super Admin manually creates the `enterprise_contracts` row and activates the account's subscription — this is an internal action, not something the customer self-serves.
4. Limit enforcement (Step 3 above) checks `negotiated_limit_overrides` first, falling back to the `enterprise` plan's baseline `plan_feature_limits` row for anything not explicitly negotiated.

**Billing mechanism:** use Stripe's invoicing with `collection_method: 'send_invoice'` rather than automatic card charging — most enterprise deals are annual contracts paid via bank transfer/PO on net-30 terms, not recurring card charges. Do not force an enterprise customer through the same card-based Stripe Checkout as the self-serve plans.

**Do NOT:**
- Do not let an Enterprise account's limits be edited through the same UI/endpoint used for the shared `plan_feature_limits` template — a fat-fingered edit there would affect every Enterprise customer at once instead of just the one being negotiated.
- Do not auto-renew a contract silently if `auto_renew` wasn't explicitly agreed — flag `contract_end_date` approaching for sales follow-up instead.
- Do not skip the audit fields (`negotiated_by_user`, `notes`) — a negotiated deal without a record of who agreed to what and why is an unauditable liability the first time a customer disputes their invoice.

**Acceptance criteria (Enterprise):**
- [ ] Enterprise is not reachable via self-serve checkout; it routes to a sales lead-capture form instead.
- [ ] A Super Admin can create an `enterprise_contracts` row with custom price and limit overrides, and it correctly takes precedence over the baseline `enterprise` plan row.
- [ ] Enterprise invoices are sent (not auto-charged) per the contract's `collection_method` and `payment_terms_days`.
- [ ] Every negotiated contract has a recorded `negotiated_by_user` and is queryable for audit.

---

## Build order summary

1. Phase 1 — hierarchy schema + capability gating + read-only Super Admin view
2. Phase 2 — branding, Connect onboarding, custom domains
3. Phase 3 — full billing engine (Case 1 + Case 2, commission formula, pricing panel)
4. Phase 4 — webhook idempotency, orphaned tenant rescue, grace periods
5. Phase 5 — mutation/audit tooling in Super Admin
6. Phase 6 — four-tier plan matrix (Hobby/Standard/Business/Enterprise) with per-feature numeric limits, enforced server-side

Each phase should ship with its own test coverage and be reviewed before starting the next — Phase 3 in particular touches real money and should not proceed until Phases 1–2's account/hierarchy model is stable. Phase 6 should land after Phase 3 (billing) is stable, since plan changes need to correctly interact with active `marketplace_plan_prices`/`subscriptions`.