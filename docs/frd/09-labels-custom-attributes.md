# FRD: Labels & Custom Attributes

**Status:** Shipped
**Module:** OSS core
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** Two independent tagging/metadata mechanisms — **Labels** (free-form color-coded tags on conversations and contacts, via `acts-as-taggable-on`) and **Custom Attributes** (admin-defined typed fields — text/number/date/checkbox/list/etc. — attached to conversations, contacts, or companies).

**Who uses it:** Admins (define labels/attribute schemas), agents (apply labels, fill in attribute values), automation/reports (filter and segment by both).

---

## 2. How it works

### Labels
1. `Label` is metadata only (`title`, `color`, `description`, `show_on_sidebar`) — the actual tag-to-record association is handled by the `acts-as-taggable-on` gem's `tags`/`taggings` tables, not a Chatwoot-owned join table.
2. `title` is lowercased before save and unique per account; `Conversation#conversations` on the label queries `account.conversations.tagged_with(title)`.
3. Conversations denormalize their current labels into `cached_label_list` (a comma-joined text column) for fast list rendering without a join, refreshed via `after_update_commit :update_associated_models` on the `Label` model (propagates rename/delete to tagged records).
4. Adding/removing a label from a conversation or contact goes through a shared `LabelConcern` (included in both `Conversations::LabelsController` and `Contacts::LabelsController`), keeping the two entry points consistent.
5. Bulk label operations on contacts have dedicated services: `Contacts::BulkAssignLabelsService`, `Contacts::BulkRemoveLabelsService`.
6. Labels also drive reporting (`Builders::V2::Reports::InboxLabelMatrixBuilder`, `LabelSummaryBuilder`) and can be suggested by AI (`Captain::LabelSuggestionService`) or set by Captain tool-calls (`AddLabelToConversationTool`).

### Custom Attributes
1. `CustomAttributeDefinition` is the schema definition — one row per custom field, scoped to one of three targets via `attribute_model` enum (`conversation_attribute / contact_attribute / company_attribute`).
2. `attribute_display_type` enum controls the input widget and value coercion: `text, number, currency, percent, link, date, list, checkbox`.
3. `attribute_key` must be unique per `(attribute_model, account_id)` — this is what's actually stored inside the target record's `custom_attributes` jsonb column (see [01-conversations.md](01-conversations.md), [03-contacts.md](03-contacts.md)); the definition row itself holds no data, just the schema.
4. `list`-type attributes store their allowed options in `attribute_values` (jsonb array); `regex_pattern`/`regex_cue` optionally validate/hint free-text input.
5. Once defined, the attribute appears as a fillable field on the relevant conversation/contact/company sidebar in the dashboard, and its value lives in that record's own `custom_attributes` jsonb — deleting the definition does not automatically strip existing values from records (no cascading cleanup observed in the model).

---

## 3. Data model

**Table:** `labels`
```
labels
  - account_id: bigint
  - title: string (lowercased, unique per account_id)
  - description: text
  - color: string, default "#1f93ff"
  - show_on_sidebar: boolean
```
Actual tag associations live in the `acts-as-taggable-on` gem's `tags` / `taggings` tables (polymorphic `taggable`), not a Chatwoot-specific join table. `conversations.cached_label_list` (text) denormalizes the current set for fast reads.

**Table:** `custom_attribute_definitions`
```
custom_attribute_definitions
  - account_id: bigint
  - attribute_display_name: string
  - attribute_key: string        # unique per (attribute_model, account_id)
  - attribute_display_type: integer  # enum text/number/currency/percent/link/date/list/checkbox
  - attribute_model: integer         # enum conversation_attribute/contact_attribute/company_attribute
  - attribute_description: text
  - attribute_values: jsonb, default []   # options for list type
  - default_value: integer
  - regex_pattern, regex_cue: string
```
Values themselves live in `conversations.custom_attributes`, `contacts.custom_attributes` (jsonb columns on the target tables), keyed by `attribute_key`.

---

## 4. Backend / API

**Routes:**
| Method | Path | Controller#action |
|---|---|---|
| GET/PATCH/POST/DELETE | `/labels` | `labels#index/update/create/destroy` (account-level label CRUD) |
| POST/GET | `.../conversations/:id/labels` | `conversations/labels#create/index` (via `LabelConcern`) |
| POST/GET | `.../contacts/:id/labels` | `contacts/labels#create/index` (via `LabelConcern`) |
| GET/POST/PATCH/DELETE | `/custom_attribute_definitions` | `custom_attribute_definitions#*` |

**Services:** `app/services/labels/` (bulk/shared logic), `app/services/contacts/bulk_assign_labels_service.rb`, `bulk_remove_labels_service.rb`, `app/builders/v2/reports/inbox_label_matrix_builder.rb`, `label_summary_builder.rb`, `lib/captain/label_suggestion_service.rb`.

**Widget-facing:** `api/v1/widget/labels_controller.rb` — labels are also exposed to the customer-facing widget SDK (read-only, contextual use).

---

## 5. Frontend

**Vue:** label management under `dashboard/routes/dashboard/settings/labels/`; label picker/chips inline on conversation and contact sidebars; custom-attribute definition manager under `dashboard/routes/dashboard/settings/custom-attributes/`; per-record attribute fill-in forms rendered dynamically by `attribute_display_type`.

**States handled:** color picker, sidebar-visibility toggle, list-type option management, per-type input validation (regex for text, numeric bounds for number/currency/percent).

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/label_spec.rb`, `custom_attribute_definition_spec.rb`, `spec/enterprise/models/custom_attribute_definition_spec.rb` | model validations/enums |
| `spec/controllers/api/v1/accounts/labels_controller_spec.rb`, `custom_attribute_definitions_controller_spec.rb` | account-level CRUD |
| `spec/controllers/api/v1/accounts/conversations/labels_controller_spec.rb`, `contacts/labels_controller_spec.rb` | per-record label attach/detach |
| `spec/controllers/api/v1/widget/labels_controller_spec.rb` | widget-facing exposure |
| `spec/services/contacts/bulk_assign_labels_service_spec.rb`, `bulk_remove_labels_service_spec.rb` | bulk operations |
| `spec/builders/v2/reports/inbox_label_matrix_builder_spec.rb`, `label_summary_builder_spec.rb` | reporting rollups |
| `spec/lib/captain/label_suggestion_service_spec.rb`, `spec/enterprise/lib/captain/tools/add_label_to_conversation_tool_spec.rb` | AI-driven labeling |

**Coverage gaps observed:** none significant — labels are thoroughly covered end-to-end (model → controller → bulk service → reporting → AI). No dedicated spec found for custom-attribute-definition deletion cascading (or not) into existing record values — worth a quick check if data-integrity on delete matters.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, **`acts-as-taggable-on` gem** (labels' underlying tag storage), PostgreSQL `jsonb` (custom attributes, list options)
- No external service dependency for either feature

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Label renamed | `after_update_commit :update_associated_models` propagates the rename to tagged records' `cached_label_list` |
| Duplicate label title in same account | Blocked by uniqueness validation (case-insensitive via lowercase-before-save) |
| Custom attribute definition deleted while records still hold that key's value | Not confirmed whether values are cleaned up — flagged below |
| Invalid custom attribute value vs. `regex_pattern` | Enforced at input time in the frontend form; not confirmed whether the backend also validates on write |

---

## 9. Open gaps / notes

- Deleting a `CustomAttributeDefinition` does not appear to cascade-clean the corresponding key out of existing `custom_attributes` jsonb blobs — orphaned keys may persist on old records. Not necessarily a bug (could be intentional to preserve historical data) but worth confirming intent.
- Backend-side regex validation on custom attribute value writes not confirmed — may be frontend-only enforcement.
