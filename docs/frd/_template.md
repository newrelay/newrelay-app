# FRD: [Feature Name]

**Status:** Shipped / Partial / Planned
**Module:** [OSS core / Enterprise / newrelay custom]
**Last updated:** [date]

---

## 1. What it is

**One-liner:** [...]

**Who uses it:** [role — agent, admin, contact, super admin]

---

## 2. How it works

[Step-by-step user/system flow, in plain language — what happens from trigger to result.]

---

## 3. Data model

**Tables:**
```
table_name
  - column: type (constraints)
```

**Relationships:** [FKs, has_many/belongs_to as actually defined]

**Migration file(s):** [db/migrate/... references]

---

## 4. Backend / API

**Routes:**
| Method | Path | Controller#action | Auth/permission |
|---|---|---|---|

**Models/services involved:** [file paths]

**Background jobs:** [Sidekiq job names, trigger, queue]

**External integrations:** [3rd-party API, gem used]

---

## 5. Frontend

**Vue components:** [paths, components-next vs legacy]

**Store module(s):** [Vuex/Pinia]

**States handled:** empty / loading / error / permission-denied

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|

**Coverage gaps observed:** [...]

---

## 7. Dev tools / dependencies actually used

- Backend gems: [...]
- Frontend libs: [...]
- External services: [...]

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|

---

## 9. Price / plan gating

**Gating type:** Ungated / Boolean flag / Resource quota / Credits / Mixed
**`feature_key`(s):** [...]   # from `PlanFeatureLimit` / `config/features.yml`

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | | | |
| Standard | | | |
| Business | | | |
| Enterprise | | negotiated | `EnterpriseContract` can override |

**Credits / usage:** none / [e.g. `captain_responses`, `credit_multiplier` in `config/llm.yml`]
**Enforced by:** `Enterprise::Billing::ReconcilePlanFeaturesService` (`account.feature_enabled?` / `account.limits[...]`)
**Source:** `lib/seeders/plan_feature_limit_seeder.rb` (Hobby / Standard / Business only). Enterprise is not a fixed matrix row.

If the feature is not in the seeder or `config/features.yml`, say so explicitly — do not invent prices or limits.

---

## 10. Open gaps / notes

[Anything noticed while documenting — not a feature request, just observations for later triage.]
