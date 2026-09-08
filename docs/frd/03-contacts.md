# FRD: Contacts

**Status:** Shipped
**Module:** OSS core
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** The person record behind every conversation — identity, contact details, custom attributes, and links to every inbox/channel they've reached the account through.

**Who uses it:** Agents/admins (dashboard contacts book), API/import consumers, automations/CRM linkage (`company_id`).

---

## 2. How it works

1. A contact is created the first time a person reaches an account via any channel (auto-created through `contact_inbox` resolution) or manually/via CSV import.
2. Each contact can be linked to multiple `contact_inboxes` (one per channel they've used — e.g. same person on WhatsApp and email) — `has_many :inboxes, through: :contact_inboxes`.
3. `contact_type` enum (`visitor / lead / customer`) tracks lifecycle stage; `blocked` flag lets agents block a contact from messaging in.
4. Identity fields (`name`, `email`, `phone_number`, `identifier`) are uniqued per-account (case-insensitive email); `additional_attributes`/`custom_attributes` (jsonb) hold flexible metadata (browser, location, or admin-defined custom fields).
5. `ContactIdentifyAction` and `ContactMergeAction` (`app/actions/`) handle the two special flows: identifying an anonymous widget visitor once they submit an email, and merging two contact records into one (moving conversations/notes/attributes).
6. Bulk import: `DataImport` model — CSV uploaded via ActiveStorage (`import_file`), `after_create_commit` kicks off `DataImportJob` → `DataImport::ContactManager` parses/validates/creates contacts row by row, writes `failed_records` back for download, tracks `processed_records`/`total_records`/`status`.
7. Export works the reverse direction (`POST /contacts/export`) — streams a CSV of filtered contacts.
8. Stale contacts (never had a conversation, inactive) are periodically cleaned by `Internal::RemoveStaleContactsService` / `RemoveStaleContactInboxesService`.

---

## 3. Data model

**Table:** `contacts`
```
contacts
  - account_id: integer, not null
  - name, middle_name, last_name: string
  - email, phone_number, identifier: string (each unique per account_id where present)
  - contact_type: integer, default 0   # enum visitor:0 lead:1 customer:2
  - blocked: boolean, default false
  - location, country_code: string
  - company_id: bigint (nullable, CRM link)
  - additional_attributes, custom_attributes: jsonb, default {}
  - last_activity_at: datetime
```

**Relationships:** `belongs_to :account`; `has_many :conversations, :contact_inboxes, :csat_survey_responses, :notes, :contact_tasks`; `has_many :inboxes, through: :contact_inboxes`; `has_many :messages, as: :sender`; `has_many :tasks, through: :contact_tasks`.

**Notable indexes:** unique `(email, account_id)` and `(identifier, account_id)`; GIN trigram index across `name/email/phone_number/identifier` for fuzzy search; partial index for "resolved" contacts (has email/phone/identifier).

**Related table:** `data_imports` (`data_type`, `status` enum pending/processing/completed/failed, `processed_records`, `total_records`, `processing_errors`, attached `import_file`/`failed_records`).

---

## 4. Backend / API

**Routes** (`config/routes.rb`):
| Method | Path | Controller#action |
|---|---|---|
| GET | `/contacts` | `contacts#index` |
| GET | `/contacts/active` \| `/search` | `contacts#active` / `#search` |
| POST | `/contacts/filter` | `contacts#filter` |
| POST | `/contacts/import` | `contacts#import` |
| POST | `/contacts/export` | `contacts#export` |
| POST | `/contacts` | `contacts#create` |
| GET/PATCH/DELETE | `/contacts/:id` | `contacts#show/update/destroy` |
| GET | `/contacts/:id/contactable_inboxes` | `contacts#contactable_inboxes` |
| POST | `/contacts/:id/destroy_custom_attributes` | `contacts#destroy_custom_attributes` |
| DELETE | `/contacts/:id/avatar` | `contacts#avatar` |
| nested | `/conversations`, `/contact_inboxes`, `/labels`, `/notes`, `/attachments` | `contacts/*` controllers |

**Actions/services:** `app/actions/contact_identify_action.rb`, `contact_merge_action.rb`; `app/services/contacts/contactable_inboxes_service.rb`; `app/services/data_import/contact_manager.rb`; `app/builders/contact_inbox_builder.rb`, `contact_inbox_with_contact_builder.rb`.

**Jobs:** `DataImportJob`, `ContactIpLookupJob` (geo/IP enrichment), `app/jobs/contacts/*`.

---

## 5. Frontend

**Vue:** contacts book pages under `dashboard/routes/dashboard/contacts/` (legacy) and `components-next/` variants referenced in recent `ContactsTableOverhaul` work (see `docs/solution-notes/contacts-table-overhaul.md`).

**Store:** `store/modules/contacts/` + satellites `contactConversations.js`, `contactLabels.js`, `contactNotes.js`.

**States handled:** empty book, list loading, import progress/failed-rows download, merge confirmation dialog, permission-gated delete.

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/contact_spec.rb`, `contact_inbox_spec.rb` | validations, associations, scopes |
| `spec/policies/contact_policy_spec.rb` | authorization |
| `spec/actions/contact_merge_action_spec.rb` | merge flow |
| `spec/actions/contact_identify_action_spec.rb` | widget-visitor identify flow |
| `spec/builders/contact_inbox_builder_spec.rb`, `contact_inbox_with_contact_builder_spec.rb` | contact/channel linking |
| `spec/drops/contact_drop_spec.rb` | liquid/template drop for contact data |
| `spec/helpers/contact_helper_spec.rb` | helper methods |
| `spec/assets/contacts.csv` + import specs | CSV import fixture |

**Coverage gaps observed:** no dedicated spec found for `DataImport::ContactManager` itself (only fixture present) — confirm via `spec/services/data_import/` before assuming import parsing is covered.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, ActiveStorage (import/export files), PostgreSQL `pg_trgm` (fuzzy search), Sidekiq (`DataImportJob`)
- Frontend: Vue 3 + Vuex, CSV handling on upload UI

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Duplicate email/identifier on create | Blocked by model validation + unique DB index |
| CSV row fails validation on import | Row skipped, appended to `failed_records`, `processing_errors` logged, `processed_records` still increments |
| Merging two contacts with conflicting attributes | Handled by `ContactMergeAction` (see spec for exact precedence rules) |
| Contact never engages after creation | Cleaned up by `RemoveStaleContactsService` |

---

## 9. Price / plan gating

**Gating type:** Resource quota (contact count). Contact UI itself is ungated.
**`feature_key`(s):** resource `contacts`; boolean `ip_lookup` (all plans)

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | yes | 500 contacts | |
| Standard | yes | 5,000 contacts | |
| Business | yes | 50,000 contacts | |
| Enterprise | yes | negotiated | `EnterpriseContract.negotiated_limit_overrides` can override |

**Credits / usage:** none
**Enforced by:** `Enterprise::Billing::ReconcilePlanFeaturesService` → `account.limits['contacts']`
**Source:** `lib/seeders/plan_feature_limit_seeder.rb`

---

## 10. Open gaps / notes

- Import parsing logic (`DataImport::ContactManager`) has a CSV fixture but no confirmed spec file exercising it directly — verify before treating as tested.
- Stale-contact cleanup cadence (cron schedule) not confirmed here — check `config/schedule.yml` if precise timing matters.
