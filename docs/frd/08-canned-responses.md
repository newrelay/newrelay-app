# FRD: Canned Responses

**Status:** Shipped
**Module:** OSS core
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** A short, reusable reply snippet triggered by typing `/short_code` in the message composer — the simplest of Chatwoot's three "saved response" mechanisms (canned response = static text snippet, vs. Macro = action bundle, vs. Automation Rule = event-triggered).

**Who uses it:** Agents, in the composer, while replying to a conversation.

---

## 2. How it works

1. Admins/agents create a canned response with a unique-per-account `short_code` and `content` (plain text/template).
2. In the composer, typing `/` opens a canned-response picker filtered as the agent types; `Canned Response.order_by_search` ranks results — short-code prefix match scores highest (1.0), short-code substring match next (0.5), content substring match last (0.2) — so `/order` matching a short_code beats it merely appearing in body text.
3. Selecting one inserts `content` into the composer at the cursor; the agent can still edit before sending — no server round-trip beyond the initial list fetch.
4. That's the entire feature — no execute/trigger endpoint, no action bundle, no visibility/personal-vs-global split (unlike Macros).

---

## 3. Data model

**Table:** `canned_responses`
```
canned_responses
  - account_id: integer, not null
  - short_code: string  (unique per account_id)
  - content: text
```

**Relationships:** `belongs_to :account`. No other associations — this is the simplest model in the productivity feature set.

---

## 4. Backend / API

**Routes** (`config/routes.rb`):
| Method | Path | Controller#action |
|---|---|---|
| GET | `/canned_responses` | `canned_responses#index` |
| POST | `/canned_responses` | `canned_responses#create` |
| PATCH | `/canned_responses/:id` | `canned_responses#update` |
| DELETE | `/canned_responses/:id` | `canned_responses#destroy` |

No background jobs, no external integrations — pure CRUD.

---

## 5. Frontend

**Vue:** settings CRUD table under `dashboard/routes/dashboard/settings/canned-response/`; the `/`-triggered picker lives inside the message composer (`WootWriter` / `components-next/Conversation` composer).

**States handled:** empty list, search-as-you-type in the picker, duplicate-short-code save error.

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/controllers/api/v1/accounts/canned_responses_controller_spec.rb` | CRUD endpoints |
| `spec/factories/canned_responses.rb`, `spec/fixtures/canned_responses.yml` | test data |

**Coverage gaps observed:** no `spec/models/canned_response_spec.rb` found — the `order_by_search` ranking scope (the one piece of actual logic in this feature) does not appear to have a dedicated model-level spec. Confirm it isn't covered indirectly via the controller spec before treating it as untested.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, raw SQL `CASE`/`ILIKE` for search ranking (no search engine/gem — hand-rolled)
- Frontend: Vue 3, composer slash-command picker

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Duplicate `short_code` in same account | Blocked by model validation + implicit reliance on that validation (no DB unique index observed in the schema snippet — validation-only uniqueness) |
| Empty `content` or `short_code` | Blocked by `presence: true` validations |
| Search term matches both short_code and content | Short_code match wins via `order_by_search` weighting |

---

## 9. Price / plan gating

**Gating type:** Ungated boolean. No resource quota.
**`feature_key`(s):** `canned_responses`

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | yes | — | |
| Standard | yes | — | |
| Business | yes | — | |
| Enterprise | yes | negotiated | |

**Credits / usage:** none
**Enforced by:** `account.feature_enabled?('canned_responses')` after `ReconcilePlanFeaturesService`
**Source:** `lib/seeders/plan_feature_limit_seeder.rb`

---

## 10. Open gaps / notes

- Uniqueness on `short_code` is enforced by Rails validation (`scope: :account_id`) but no corresponding unique DB index was seen in the schema excerpt — a race condition (two simultaneous creates) could theoretically produce duplicate short_codes. Low-risk given usage pattern (admin-authored, infrequent), but worth confirming if it matters.
- `order_by_search` scope has no dedicated model spec — flagged above.
