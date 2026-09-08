# FRD: Custom Filters

**Status:** Shipped
**Module:** OSS core
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** A saved, reusable advanced query (multi-condition, boolean-combined) an agent builds once and re-applies later — for conversations, contacts, or reports — without rebuilding the filter each time.

**Who uses it:** Agents/admins, on the conversation list, contacts book, or report screens.

---

## 2. How it works

1. A `CustomFilter` stores a `query` (jsonb — the actual filter condition tree: attribute, operator, value, and-or joins) tagged with `filter_type` (`conversation` / `contact` / `report`) so the same model serves three different filterable surfaces.
2. Filters are personal — `belongs_to :user` as well as `:account` — one agent's saved filter isn't visible to others (no visibility/sharing flag, unlike Macros' `personal`/`global` split).
3. Applying a filter (whether saved or ad-hoc, unsaved) goes through `FilterService` — a **generic, attribute-driven query builder**, not per-filter-type hardcoded SQL. It loads `lib/filters/filter_keys.yml` (the whitelist of filterable attributes and their types) and, combined with `Filters::CustomAttributeFilterHelper`, can filter on both standard columns and admin-defined `CustomAttributeDefinition` fields (see [09-labels-custom-attributes.md](09-labels-custom-attributes.md)) — same `ATTRIBUTE_TYPES` mapping (`date`/`text`/`numeric`/`boolean`) used to build the right SQL comparison per type.
4. This means Custom Filters and Custom Attributes are tightly coupled: any custom attribute an admin defines automatically becomes filterable without additional code, because `FilterService` reads the attribute definitions dynamically rather than requiring a filter to be hand-registered.
5. `CustomExceptions::CustomFilter` provides typed errors for malformed filter queries (bad attribute key, invalid operator) rather than letting a raw SQL error leak out.

---

## 3. Data model

**Table:** `custom_filters`
```
custom_filters
  - account_id, user_id: bigint, not null
  - name: string, not null
  - filter_type: integer, default 0   # enum conversation:0 contact:1 report:2
  - query: jsonb, default {}, not null
```

**Not a table:** `lib/filters/filter_keys.yml` — the whitelist of filterable attributes/types, read at query-build time.

---

## 4. Backend / API

**Routes:**
| Method | Path | Controller#action |
|---|---|---|
| GET/POST | `/custom_filters` | `custom_filters#index/create` |
| GET/PATCH/DELETE | `/custom_filters/:id` | `custom_filters#show/update/destroy` |

Filter *application* itself happens via each resource's own `filter` action (e.g. `POST /conversations/filter`, `POST /contacts/filter` — see [01-conversations.md](01-conversations.md), [03-contacts.md](03-contacts.md)), which accepts a query payload in the same shape whether or not it was loaded from a saved `CustomFilter`.

**Engine:** `app/services/filter_service.rb`, `app/services/filters/{filter_helper, custom_attribute_filter_helper}.rb` (concerns), `lib/filters/filter_keys.yml`, `lib/custom_exceptions/custom_filter.rb` (or similar).

---

## 5. Frontend

**Vue:** filter builder UI (condition rows: attribute dropdown, operator, value, AND/OR) shared across the conversation list, contacts book, and reports — likely one shared component given the backend's single generic query shape, per `Limits::MAX_CUSTOM_FILTERS_PER_USER` (1000, from `lib/limits.rb`) capping how many a single user can save.

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/controllers/api/v1/accounts/custom_filters_controller_spec.rb` | CRUD |
| `spec/factories/custom_filters.rb` | test data |

**Coverage gaps observed:** no dedicated `spec/models/custom_filter_spec.rb` or `spec/services/filter_service_spec.rb` found directly under those names — the actual query-building logic (the interesting part of this feature) doesn't appear to have its own isolated spec; it's likely exercised indirectly through `conversations#filter`/`contacts#filter` request specs, but that wasn't confirmed.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, PostgreSQL `jsonb` (stored query), dynamic SQL query building (own `FilterService`, no external query-builder gem)

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Filter references an attribute key that doesn't exist / was deleted | Handled via `CustomExceptions::CustomFilter` rather than a raw SQL error |
| User saves more than `MAX_CUSTOM_FILTERS_PER_USER` (1000) | Presumably blocked at creation — exact enforcement point not directly confirmed in this pass |
| Filter type mismatch (e.g. a `report`-type filter applied to conversations) | Not confirmed whether `FilterService` cross-checks `filter_type` against the endpoint it's applied to |

---

## 9. Price / plan gating

**Gating type:** Not in the plan matrix. No `custom_filters` key in `config/features.yml` or `PlanFeatureLimit`.
**`feature_key`(s):** none

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | not gated | — | available to any account user who can use conversation filters |
| Standard | not gated | — | |
| Business | not gated | — | |
| Enterprise | not gated | — | |

**Credits / usage:** none
**Enforced by:** inbox/account membership, not `ReconcilePlanFeaturesService`
**Source:** `lib/seeders/plan_feature_limit_seeder.rb` — no matching key

---

## 10. Open gaps / notes

- `FilterService`'s query-building logic has no directly confirmed isolated spec — worth a quick check if this becomes a priority area, since it's the one piece of real logic in an otherwise simple CRUD feature.
- Enforcement point for the 1000-filters-per-user limit not directly confirmed.
