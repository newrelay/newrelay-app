# FRD: Super Admin

**Status:** Shipped
**Module:** OSS core (framework), newrelay custom (billing/marketplace/enterprise-contract screens layered on top)
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** The platform operator's own admin panel (separate from any customer account) — manage every account/user on the instance, configure the installation, and (newrelay-specific) run billing operations: subscriptions, coupons, enterprise contracts, marketplace pricing, payment gateway config.

**Who uses it:** Platform/instance operators only (`SuperAdmin`, a `User` STI subclass — `users.type = 'SuperAdmin'`) — never regular account admins or agents.

---

## 2. How it works

1. Built on the **`administrate`** gem (Rails admin-panel framework, via `administrate-field-active_storage`/`administrate-field-belongs_to_search` plugins) — not a hand-rolled admin UI, and not ActiveAdmin. This means most CRUD screens follow `administrate`'s conventions (resource-per-controller, auto-generated forms) rather than bespoke Vue pages like the rest of the dashboard.
2. `SuperAdmin < User` — reuses the same `users` table/auth (Devise) as regular agents, just a different `type` (Rails STI). Signing in as a super admin is a fully separate session/URL space (`/super_admin/*`), mounted alongside a Sidekiq::Web monitoring UI (`authenticated :super_admin { mount Sidekiq::Web }`) — so super admins can also watch the job queue directly.
3. Core instance-management resources: `accounts` (with member actions `seed` — enqueues `Internal::SeedAccountJob`, per this repo's CLAUDE.md dev workflow — `reset_cache`, `clear_custom_domain`, `clear_portal_custom_domain`), `users`, `account_users`, `agent_bots`, `platform_apps`, `platform_banners` (instance-wide announcement banners), `installation_configs` (global config key/value store), `instance_status`, `settings` (+ `refresh`), `cloudflare_domains` (custom-domain DNS management, ties to the Help Center/portal custom-domain feature), `push_diagnostics`.
4. **newrelay-added billing/marketplace screens** (not stock Chatwoot Super Admin): `enterprise_contracts` (full CRUD — negotiate/manage the contracts described in [20-billing-subscription.md](20-billing-subscription.md)), `enterprise_inquiries` (a sales pipeline — `mark_processed`/`send_payment_link`/`reject` — for accounts requesting an Enterprise deal), `subscriptions`/`payment_transactions`/`billing_activity_logs` (read-only oversight), `billing_coupons` (full CRUD), `marketplace_plan_prices` (read-only), `plan_management` (singleton — likely where `PlanFeatureLimit` rows are edited), `payment_gateways` (singleton — provider config/toggles, ties to the Stripe→Razorpay transition noted in the Billing FRD).
5. `account_hierarchy` resource (`GET .../accounts/:account_id`) suggests a parent/child or agency/sub-account view — consistent with the marketplace `relationship_type` model in Billing.
6. Recent fix (per git log: `fix(super-admin): show Cloudflare error messages instead of raw hashes`) confirms `cloudflare_domains` is live/actively maintained, not a stub.
7. Recent fix (`feat(super-admin): render custom attributes as a serialized JSON field`) confirms `administrate`'s auto-generated forms needed a custom field type for jsonb columns (e.g. `users.custom_attributes`) — a concrete example of where the generic admin-framework approach needed a bespoke override.

---

## 3. Data model

No dedicated Super Admin tables — it's a management UI over existing tables (`accounts`, `users` with `type='SuperAdmin'`, `installation_configs`, `platform_banners`, `platform_apps`, plus every Billing table from [20-billing-subscription.md](20-billing-subscription.md)). `installation_configs` is the one config-storage table worth noting on its own:
```
installation_configs
  - name: string, not null (config key)
  - (value/serialized_value columns not individually inspected in this pass)
```

---

## 4. Backend / API

**Routes** (`/super_admin/*`, `administrate`-framework controllers under `app/controllers/super_admin/`):
| Resource | Notable actions |
|---|---|
| `accounts` | full CRUD + `seed`, `reset_cache`, `clear_custom_domain`, `clear_portal_custom_domain` |
| `enterprise_contracts` | full CRUD |
| `enterprise_inquiries` | `index/destroy` + `mark_processed`/`send_payment_link`/`reject` |
| `subscriptions`, `payment_transactions`, `billing_activity_logs`, `marketplace_plan_prices` | read-only (`index/show`) |
| `billing_coupons` | full CRUD |
| `plan_management`, `payment_gateways` | singleton `show/update` |
| `users`, `account_users`, `agent_bots`, `platform_apps`, `platform_banners`, `installation_configs` | standard CRUD (subset per resource) |
| `access_tokens` | read-only |
| `account_hierarchy` | `show` + per-account drill-down |
| `cloudflare_domains` | `show`/`destroy` |
| `instance_status`, `settings` (+`refresh`), `push_diagnostics`, `app_config` | instance-level ops/diagnostics |
| `/monitoring/sidekiq` | Sidekiq::Web, gated behind `authenticated :super_admin` |

---

## 5. Frontend

Server-rendered `administrate` views (ERB, not Vue) — a deliberately different stack from the rest of the dashboard, consistent with `administrate` being a Rails-native admin framework rather than an SPA.

---

## 6. Test coverage (as it exists today)

~14 spec files under `spec/controllers/super_admin/` (or similar) — covers the core resource controllers. Given the breadth of resources (23 controllers) versus spec count, coverage is likely partial/uneven, but not individually itemized in this pass.

**Coverage gaps observed:** did not enumerate per-controller coverage in this pass — recommend a follow-up check specifically on the newrelay-added billing/marketplace screens (`enterprise_contracts`, `enterprise_inquiries`, `plan_management`, `payment_gateways`) since those are custom, not inherited from stock Chatwoot, and touch the same money-adjacent surface flagged as under-tested in [20-billing-subscription.md](20-billing-subscription.md).

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, **`administrate` gem** (+ `administrate-field-active_storage`, `administrate-field-belongs_to_search`), Devise (shared auth with regular users via STI), Sidekiq::Web (mounted, not custom-built)
- No separate frontend framework for this surface — server-rendered admin views

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| jsonb column needs to be edited in an auto-generated `administrate` form | Required a custom field override (recent fix — `custom attributes as serialized JSON field`) rather than relying on the framework default |
| Cloudflare API returns an error | Recently fixed to surface the actual error message instead of a raw hash dump (a real usability fix, implies this was previously a poor debugging experience for operators) |
| Enterprise inquiry needs a payment link sent without full self-serve checkout | `send_payment_link` member action — routes through the Enterprise contract/payment-link services from Billing |

---

## 9. Price / plan gating

**Gating type:** Operator-only. Super Admin is not a customer plan SKU.
**`feature_key`(s):** none. Super Admin auth is a separate Devise scope, not `PlanFeatureLimit`.

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | no | — | not sold to accounts |
| Standard | no | — | |
| Business | no | — | |
| Enterprise | no | — | instance operators only |

**Credits / usage:** none
**Enforced by:** Super Admin session / `SuperAdmin::*Controller`, not `ReconcilePlanFeaturesService`
**Source:** not in `lib/seeders/plan_feature_limit_seeder.rb`

---

## 10. Open gaps / notes

- Per-resource test coverage not individually confirmed — flag the billing/marketplace-specific screens (`enterprise_contracts`, `enterprise_inquiries`, `plan_management`, `payment_gateways`) for closer scrutiny given they're newrelay-custom and money-adjacent, consistent with the coverage gap already flagged in [20-billing-subscription.md](20-billing-subscription.md).
- `installation_configs` value storage/serialization format wasn't fully inspected — worth a look if instance-wide config behavior needs to be understood precisely.
