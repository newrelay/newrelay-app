# Number Provisioning — Code Review & Decisions Needed (2026-09-29)

**Scope:** every number-provisioning file on `feature/phone-reseller` plus the uncommitted search-normalization change (TelnyxProvider/ExotelProvider `normalize_search_result`, `Provider#price_to_cents`, `ProviderConfig.currency_for`, cache key `v2`, `BuyPhoneNumberModal.vue` price formatting).

**How to use this file:** each finding has evidence, a recommended option, and an empty **Decision** line. Fill in the decision, then record the implementation choice as a row in [number-provisioning-agent-decision-log.md](number-provisioning-agent-decision-log.md). Product decisions go to [telnyx-twilio-parity-frd.md](telnyx-twilio-parity-frd.md) §16 as usual.

Severity: **P1** = orders cannot complete / money or data risk · **P2** = wrong behaviour on a realistic path · **P3** = cleanup / low risk.

---

## Summary

| # | Sev | Finding | Recommended |
|---|---|---|---|
| 1 | P1 | Telnyx order statuses never map to `active`; `pending` is mislabeled `requirements_pending` and polling stops | Map per provider in the adapter |
| 2 | P1 | Exotel `status()` response has no confirmed `status` field → every India order fails after 30 min | Capture one real response, then map |
| 3 | P1 | Timeout during `provider.order` leaves order stuck in `order_placed` forever, and the number may already be bought | Rescue timeouts into the poll path, not `failed` |
| 4 | P2 | Wholesale price is now normalized at search, but never reaches `provider_cost_cents` | Re-read price server-side from search cache on create |
| 5 | P2 | Exception between idempotency claim and order row (e.g. `RecordInvalid`) locks that key as `in_progress` for 10 min | Release the slot on failure |
| 6 | P2 | Telnyx HTTP calls have no timeout (Exotel has 15s) | Add `timeout: 15` to match Exotel |
| 7 | P3 | Invalid `country_code`/`type` to Exotel raises `ArgumentError` → HTTP 500 | Rescue as 422 |
| 8 | P3 | Search cache is read before the provider-enabled check | Accept (≤5 min) or check first |
| 9 | P3 | `Array(parsed_response)` on a Hash turns into key/value pairs and crashes normalization | Accept for now (live test shows top-level array) |
| 10 | P3 | Stale comments after normalization | Delete |

---

## 1. Telnyx order status never reaches `active` — P1

**Evidence:** `PollOrderStatusJob#handle_status` (`app/jobs/number_provisioning/poll_order_status_job.rb`) matches `'active'` / `'failed'` / `nil` / else. Telnyx `NumberOrderWithPhoneNumbers::Status` is `pending | success | failure` (verified in `team-telnyx/telnyx-ruby` `lib/telnyx/models/number_order_with_phone_numbers.rb`, 2026-09-29).

**Effect:** first poll returns `pending` → `else` branch → order set to `requirements_pending`, no requeue. A completed order (`success`) would also land in `requirements_pending`. No Telnyx order can ever become `active`, so `bill_order` never runs.

**Options:**
- **A (recommended):** each adapter's `status()` returns a normalized value (`active | pending | failed | requirements`), same pattern as the new `normalize_search_result`. Job stays provider-agnostic.
- B: add Telnyx strings to the job's `case` (`'success'` → active, `'failure'` → failed, `'pending'` → requeue). Smaller diff, but the job starts branching on provider vocabulary.

Note: Telnyx order-level `pending` also covers "waiting on regulatory requirements" — distinguishing that needs the per-phone-number `requirements_met` field. Decide whether A covers it now or later.

**Decision:** ______

## 2. Exotel status mapping unverified — P1

**Evidence:** `ExotelProvider#status` GETs `IncomingPhoneNumbers/{sid}` and returns it raw. The documented purchase shape is `{ sid, phone_number, capabilities, rental_price, currency }` — no `status` key. Job reads `raw_status['status']` → `nil` → requeue 30× → `failed` with "polling attempts exhausted".

**Options:**
- **A (recommended):** capture one real `IncomingPhoneNumbers/{sid}` response (India sandbox or live), then map in the adapter as in #1A. Do not guess the field.
- B: treat a 200 from `IncomingPhoneNumbers/{sid}` as `active` (Exotel numbers are usable immediately after purchase). Only if Exotel confirms that.

**Decision:** ______

## 3. Timeout during order submission strands the order — P1

**Evidence:** `OrdersController#submit_to_provider` rescues only `Provider::RequestError`. `Net::ReadTimeout`/`Net::OpenTimeout` propagate to `rescue_from … render_provider_timeout`, but the order row is already created with `order_placed`, `provider_order_id: nil`, and `PollOrderStatusJob` is never enqueued (it runs after `submit_to_provider` returns). The idempotency slot already holds this order id, so a retry with the same key replays the stuck order.

**Risk:** a read timeout can happen *after* the provider bought the number — the platform is billed by Telnyx/Exotel with no record of a provider order id.

**Options:**
- **A (recommended):** on timeout mark the order `failed` with `provisioning_error: 'timeout — verify with provider'` and log at warn level for manual reconciliation. Simple, visible.
- B: reconcile automatically — look up the number on the provider (Telnyx `GET /phone_numbers?filter[phone_number]=…`, Exotel `IncomingPhoneNumbers`) before failing. Correct, but needs verified lookup endpoints.

**Decision:** ______

## 4. Wholesale cost never captured — P2 (blocks billing)

**Evidence:** search now returns `monthly_price_cents` + `currency` (uncommitted change). `OrdersController#order_params` permits only `country_code`, `phone_number`; `provider_cost_cents` is never written. `OrderBillingService#compute_margin_cents` is still hard-coded `0`.

**Options:**
- **A (recommended):** on create, look up the chosen number in the `number_provisioning:search:v2:*` cache entry and copy its price/currency onto the order. Server-trusted price, no extra provider call. Cache miss (>5 min) → leave `nil` ("cost unknown", already the documented meaning).
- B: accept price from the client. Rejected — client-controlled billing input.
- C: use the price in the provider's order response (Exotel returns `rental_price`; Telnyx order response shape for cost unconfirmed).

Also decide: add a `currency` column to `number_provisioning_orders` (price without a currency is ambiguous — Telnyx USD vs Exotel INR; see TODOS.md "Convert number price into the subscription currency").

**Decision:** ______

## 5. Orphaned idempotency slot on unexpected error — P2

**Evidence:** `resolve_idempotent_order` sets the slot to `in_progress` (NX, 10 min). If `create!` raises (`RecordInvalid` on phone format) or anything else raises before `store_idempotency_key`, the slot stays `in_progress`. The modal reuses the same key for that selection, so the admin gets "already being processed" for 10 minutes.

**Options:**
- **A (recommended):** in `place_order`, on any exception before `store_idempotency_key`, `Redis::Alfred.delete(idempotency_cache_key)` and re-raise.
- B: accept — phone numbers come from the provider's own search, so `RecordInvalid` is unlikely.

**Decision:** ______

## 6. Telnyx requests have no timeout — P2

**Evidence:** `TelnyxProvider` passes no `timeout:`; `ExotelProvider` uses `REQUEST_TIMEOUT = 15` (decision log row, 2026-09-29). Default Net::HTTP read timeout is 60s — a slow Telnyx holds a Puma thread for up to a minute on search/order.

**Recommended:** add `timeout: REQUEST_TIMEOUT` (15) to all three Telnyx calls, matching Exotel.

**Decision:** ______

## 7. Invalid Exotel params return 500 — P3

**Evidence:** `ExotelProvider#search` raises `ArgumentError` on bad `country_code`/`type`; controller has no `rescue_from ArgumentError`. `NumberProvisioning.for` upcases the country for routing, but the adapter validates the raw value — `country_code=in` routes to Exotel and then 500s.

**Options:** **A (recommended):** controller `rescue_from ArgumentError` → `render_could_not_create_error`. B: upcase in the controller before calling. Both are one line.

**Decision:** ______

## 8. Cache served while provider is disabled — P3

**Evidence:** `OrdersController#search` returns the Redis hit before `NumberProvisioning.for` runs its enabled check. After Super Admin disables a provider, search results keep appearing for up to 5 minutes; ordering is correctly rejected.

**Options:** **A (recommended):** accept; the order path is guarded. B: resolve the provider before reading the cache.

**Decision:** ______

## 9. Exotel search response shape assumed to be an array — P3

**Evidence:** `Array(response.parsed_response).map { normalize_search_result }`. If Exotel ever wraps results in an object, `Array(hash)` yields `[key, value]` pairs and `number['capabilities']` raises `TypeError` (500). Live testing (vendor findings doc) returned a top-level array for `IN/Mobile` and `IN/TollFree`.

**Recommended:** accept; revisit only if a wrapped response is seen.

**Decision:** ______

## 10. Stale comments — P3

- `BuyPhoneNumberModal.vue` `selectCountry`: "Exotel's raw search response isn't confirmed to be a top-level array" — backend now always returns a normalized array.
- `OrderBillingService#compute_margin_cents` comment says cost isn't captured "from the provider's search/order response" — search now captures it (still not persisted, see #4).
- Design doc "Not yet built: price normalization on `search()`" and vendor-findings §"Known gap" — done by the uncommitted change once committed.

**Recommended:** update these with the commit that lands the normalization.

**Decision:** ______

---

## Page review — Settings → Phone Numbers (list + Buy modal)

Reviewed from code only (`phoneNumbers/Index.vue`, `BuyPhoneNumberModal.vue`, `store/modules/phoneNumberOrders.js`, `SettingsSideMenu.vue`, `phoneNumbersMgmt.json`, jbuilders). **Not yet checked visually in a browser** — the Chrome extension was not connected.

| # | Sev | Where | Issue | Recommended | Decision |
|---|---|---|---|---|---|
| P-1 | P1 | List | Status never updates without a full reload — the store fetches once on mount, no polling/websocket. With backend #1/#2, orders also sit in "Order placed" or flip to a wrong status. | Re-fetch every ~15s while any row is non-terminal (`order_placed`, `requirements_*`) | ______ |
| P-2 | P1 | Buy modal, confirm step | Admin buys without seeing the price — confirm step shows only the number. Price, currency and capabilities from the chosen result aren't repeated. | Show price/mo + capabilities on the confirm step | ______ |
| P-3 | P2 | Buy modal, country step | "India — SMS and voice, via Exotel" is wrong: live search showed every `IN/Mobile` result has `sms: false` (vendor findings doc). | Change copy to match reality ("Voice" for India) or confirm with Exotel first | ______ |
| P-4 | P2 | List + modal | Vendor names shown to customers: Provider column (`telnyx`/`exotel`) and "via Telnyx/Exotel" in country descriptions. Conflicts with white-label installs. | Hide provider column and vendor names from the tenant UI (keep in Super Admin) | ______ |
| P-5 | P2 | List | Failed orders show a red "Failed" badge with no reason and no next step. `provisioning_error` isn't in `index.json.jbuilder`, and there are no row actions (retry/remove). | Add a short, safe reason (tooltip) + a retry path; never show raw provider body | ______ |
| P-6 | P2 | List | "Purchased" column shows `created_at` for every order, including failed ones that were never purchased. Count "{n} numbers" also counts failed orders. | Rename column to "Ordered", or count/label only `active` as purchased | ______ |
| P-7 | P2 | Route | Nav item is hidden when provisioning is disabled, but `/settings/phone-numbers/list` still opens directly; "Buy Number" then fails with "provider is not available". | Redirect or show an empty/disabled state when `numberProvisioningEnabled` is false | ______ |
| P-8 | P3 | Results list | Capability badges print raw API strings (`sms`, `voice`) — not i18n, lowercase. | Map known capabilities to i18n keys (`SMS`, `Voice`) | ______ |
| P-9 | P3 | Country column | Shows ISO code (`IN`, `US`) instead of a country name. | Reuse the modal's country titles, or accept codes | ______ |
| P-10 | P3 | Confirm button | Only `disabled` while ordering — no loading indicator; the order call can take up to the provider timeout (60s on Telnyx today, see #6). | Use RelayButton's loading state if it has one; otherwise spinner icon | ______ |
| P-11 | P3 | Results step | Search error sends the admin back to the country step and only shows a toast — they lose context. | Stay on results step with an inline error + retry | ______ |
| P-12 | P3 | Country step | Uses legacy `dashboard/components/ChannelSelector.vue`. CLAUDE.md: don't add new usages of legacy `components/` widgets. It is already Tailwind/Relay-styled, so low impact. | Accept, or move to a Relay card when one exists | ______ |
| P-13 | P3 | Modal code | `formatPrice(result)` runs twice per row in the template; stale comment in `selectCountry` about Exotel array shape (see #10). | Compute once per row; delete comment | ______ |

Fine on the page: Relay components (`RelayButton`, `RelayBadge`, `RelayInput`, `RelayModal size="lg"`) used correctly; table head `text-[14px] font-semibold` per CLAUDE.md; semantic color tokens only; all strings in `en.json`; nav gate is reactive and refreshed on Settings mount; idempotency key per selection.

---

## Reviewed and fine (no action)

- **Authorization:** all four actions are administrator-only via `NumberProvisioning::OrderPolicy`; orders scoped to `Current.account`.
- **Idempotency:** NX claim + NX reclaim for failed orders is race-safe; key generated once per number selection in the modal.
- **Provider error leakage:** client gets a generic message; raw body only in logs.
- **Poll job:** per-order Redis lock, `MAX_ATTEMPTS`, `RequestError` + `ProviderDisabledError` rescued; Enterprise billing via `prepend_mod_with`.
- **Money:** `price_to_cents` uses `BigDecimal`, blank/unparseable → `nil`, not `0`.
- **Super Admin:** margin validated 0–100, targeted cache clear after save.
- **Search cache key bump to `v2`:** correct — prevents serving pre-normalization raw entries after deploy.
- **Frontend:** Relay components, i18n keys in `en.json` only, `Intl.NumberFormat` with fallback for unknown currency.

## Not covered

- No RSpec exists for this feature (design doc lists it as not built); nothing above was verified by running tests.
- Channel/inbox creation on `active` is intentionally unbuilt (`mark_active` TODO) — out of scope for this review.
