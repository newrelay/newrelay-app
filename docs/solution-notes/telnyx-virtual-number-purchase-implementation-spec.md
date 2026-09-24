# Technical Implementation Spec — Virtual Number Purchase (Telnyx, §6a/PRD-18)

> Notion note: same publishing blocker as the other two Telnyx docs — this workspace has used all its free blocks and needs a plan upgrade before new Notion pages can be created. Follows the NewRelay HQ "Technical Implementation Spec" template.
>
> **🚨 Blocking (2026-09-24, live-tested against a real Telnyx account, not documentation) — two separate issues, both unresolved:**
>
> **1. No SMS-capable numbers in India — confirmed as a real product limitation, not an account/tier artifact.** Live test: all five phone number types (`local`/`mobile`/`toll_free`/`national`/`shared_cost`) with `features[]=sms` returned `"No coverage found in the specified country"`. Cross-checked against Telnyx's own [India Mobile Numbers release note](https://telnyx.com/release-notes/india-mobile-numbers) (2026-09-17) — the feature shipped as **voice-only**, no SMS/MMS mentioned. This rules out "maybe it's this account's tier." Every part of this spec's India-specific SMS code — the district picker in `NumberSearchService` (§2a), the `requirements_pending`/KYC states (§3), `RequirementSubmissionService` (§2a) — is written for a capability Telnyx's India numbers don't have and were never scoped to have. This is now a Product decision (FRD Open Question 14: drop India from SMS scope, or re-scope India as Voice-only under §6b instead), not something more testing will resolve. **Don't build the India SMS code paths below until that's decided.**
>
> **2. The core search → reserve → order flow itself has not been confirmed to actually complete, on any account tested so far.** `number_reservations.create` failed with an account-tier error (10038, same as the regulatory-requirements lookup). A real order attempt — explicitly confirmed, against an available $0-listed US number, with the user's own API key — failed with `"Only 1 order is allowed at your account level"` (10039). No charge occurred. **Retried after the existing order was deleted from the Telnyx dashboard, against a fresh number — identical error.** This narrows the diagnosis to a genuine plan-tier order cap (likely lifetime, not "1 active order"), not a stale-order cleanup problem. Everything in §2a below is confirmed correct at the request/response *shape* level (real gem source, real field names), but that is not the same claim as "this completes a real purchase" — it hasn't, on any account tried yet, across two independent attempts. See FRD Open Question 16.
>
> **⚠ Also partially superseded (2026-09-23).** The FRD's §6a now includes **PRD-19: purchased numbers are reseller-model, not BYO** — NR's own Telnyx master account, marked up, billed through NR's own subscription system, not the customer's Telnyx credentials. This spec was written before that decision and was built entirely on the BYO assumption (§3's `api_key` column, §5's security section, §2a's `client(channel)` pattern all assume a per-customer Telnyx key). The judgment call below — "no Architecture Design needed" — **no longer holds**; PRD-19 introduces a shared platform credential, a billing integration, and a tenant-isolation model this spec never anticipated. Recommendation: pause further edits to this spec, write the Architecture Design PRD-19 now calls for, then revise this spec to match — rather than patching the code snippets below piecemeal around a decision this large. The rest of this document (§1, §2 minus the auth assumption, §4, §7's search/order edge cases, §11's non-auth tests) is still broadly accurate for the *search and order mechanics themselves*; it's the credential/billing/ownership layer underneath that needs to change.
>
> **Original process note (superseded above, kept for history):** NR's process calls for an Architecture Design before this spec when a change spans two-plus modules or a shared platform contract (that gate was used for the sibling Voice/PRD-10 work). This feature's blast radius is narrower — one new channel model, one new webhook, one new admin flow — so it's spec'd directly from the FRD, the same tier as "integration risk → PRD + Implementation Spec." Flag if that judgment call is wrong.

| Field | Value |
|---|---|
| Restates | [telnyx-twilio-parity-frd.md](telnyx-twilio-parity-frd.md) §6a, PRD-18 **and PRD-19 (not yet incorporated below)** |
| Architecture Design | None yet — **now recommended before this spec is finalized**, per PRD-19 |
| Status | Draft, partially superseded |
| Written by | TBD |

## 1. Restatement of the requirement

An account admin can search Telnyx's available-number inventory from inside NR and purchase one directly, without ever opening the Telnyx portal. Once active, the number becomes a working Telnyx-backed SMS inbox with webhooks already configured — no manual step between "purchased" and "usable." Entering an existing (BYO) Telnyx number remains supported unchanged; this is a second, additive path.

## 2. Implementation approach

Mirrors the existing Twilio provisioning shape (`Twilio::WebhookSetupService`, `Channel::TwilioSms`) rather than inventing a new pattern: a small set of single-purpose services under `app/services/telnyx/`, one new controller for the search/order actions, one new public webhook route for async order-status updates, and a `provisioning_status` state machine on the channel record that the frontend polls/observes.

**Scope correction (per FRD §16 decision, 2026-09-23):** an earlier draft of this spec hard-forced `country_code: 'US'` and explicitly deferred all regulatory-document handling. That's wrong — Phase 1's confirmed country scope is **US and India**, admin-selectable, not a single hardcoded country. Consequence: this spec now **must** include a real KYC/regulatory-document submission flow, because India requires it as the normal path (address + ID verification, restricted to four authorized telecom districts: Mumbai City, Gurugram, Noida, Bangalore — confirmed against Telnyx's own India documentation), not a rare edge case the way it would be for a mostly-US scope. Two genuinely different flows exist side by side: **US** (search → order → active in seconds, no documents) and **India** (search within one of four districts → order → submit KYC documents → wait on Telnyx's review → active). Country allowlist for Phase 1 is `['US', 'IN']` — see §14 for whether that should be hardcoded or config-driven.

## 2a. SDK / API reference — exact calls used

All calls go through the `telnyx` gem (Appendix C of the FRD, `~> 5.168.0`, requires Ruby ≥ 3.2.0). All method names below are now confirmed against gemdocs.org's rendered docs for that exact version (see the Sources line at the end of this document).

**⚠ A note for whoever implements this, since it's an easy trap:** `team-telnyx/demo-ruby-telnyx`'s `console-search-and-order-numbers` example (checked 2026-09-23) uses the gem's **old, pre-5.x API style** — global `Telnyx.api_key = ...` config and singular-class calls like `Telnyx::AvailablePhoneNumber.list(filter)` / `Telnyx::NumberOrder.create(...)`. That's superseded by the current client-instance style (`Telnyx::Client.new(api_key:)` → `client.available_phone_numbers.list(filter: {...})`) used throughout this spec and confirmed against the gem's own current README. The demo confirms the *concept* (search → order → poll `status == 'pending'` until it resolves) matches this spec's design, but don't copy its exact syntax — it predates the version actually going into the Gemfile and would raise `NoMethodError` against `~> 5.168.0`. (It also has a typo baked in — `coutry_code:` — a second reason not to copy it verbatim.)

**1. Search — `Telnyx::NumberSearchService` — CONFIRMED**

```ruby
# app/services/telnyx/number_search_service.rb
module Telnyx
  class NumberSearchService
    ALLOWED_COUNTRY_CODES = %w[US IN].freeze # Phase 1 allowlist — not free text, see spec §14 Q1
    INDIA_AUTHORIZED_DISTRICTS = ['Mumbai City', 'Gurugram', 'Noida', 'Bangalore'].freeze

    pattr_initialize [:channel!]

    def perform(country_code:, locality: nil, administrative_area: nil, phone_number_type: 'local')
      raise ArgumentError, "unsupported country: #{country_code}" unless ALLOWED_COUNTRY_CODES.include?(country_code)
      raise ArgumentError, "India numbers require an authorized district" if country_code == 'IN' && INDIA_AUTHORIZED_DISTRICTS.exclude?(locality)

      client.available_phone_numbers.list(
        filter: {
          country_code: country_code,
          locality: locality,
          administrative_area: administrative_area,
          phone_number_type: phone_number_type, # 'local' | 'toll_free' (US only — India is 'local'/'mobile')
          limit: 20
        }.compact
      ).data
      # NOTE: no longer rejects results with regulatory_requirements present (see §2 scope
      # correction) — India results always carry requirements and are legitimately orderable.
      # The response's requirements metadata is what drives the KYC submission step below.
    end

    private

    def client
      @client ||= ::Telnyx::Client.new(api_key: channel.api_key)
    end
  end
end
```
REST equivalent: `GET /v2/available_phone_numbers?filter[country_code]=US&...` (or `IN`). **Fully confirmed (2026-09-23)** against the real `Telnyx::Models::AvailablePhoneNumberListParams::Filter` model on gemdocs.org — `country_code`, `locality`, `administrative_area`, `phone_number_type`, and `limit` are all real attributes of that filter, `limit` nested inside `filter` exactly as coded here (not a separate top-level/REST-level pagination param the way a raw `page[size]` query string would work). This is the one call in this spec that turned out correct on the first pass, not something an earlier guess got wrong. `INDIA_AUTHORIZED_DISTRICTS` is a source-of-truth-in-code list — if Telnyx expands the four districts, this needs a code change, not just a config change (flagged in §14, same open question as the country allowlist). Also available on this filter but not yet used here: `reservable: true` (excludes numbers that can't actually be reserved) and `exclude_held_numbers: true` — worth considering adding to cut down on "picked a number, reservation immediately failed" cases, noted as a possible refinement rather than added speculatively.

**1a. Reserve — `Telnyx::NumberReservationService` — CONFIRMED (2026-09-23, against gemdocs.org's rendered docs for `telnyx` 5.168.0)**

Added after re-checking Telnyx's own numbers getting-started guide, which calls this out explicitly as the step between search and order. Fixes edge case §7.1 (a searched number going stale) properly instead of just erroring after the fact.

**Correction from the first draft of this service:** `extend` is not a top-level method on `number_reservations` — it's nested under an `actions` sub-resource, and named `extend_` (trailing underscore) since `extend` is a Ruby core method name. Exact confirmed signatures: `Telnyx::Resources::NumberReservations#create(phone_numbers:, customer_reference: nil, request_options: {})` and `Telnyx::Resources::NumberReservations::Actions#extend_(number_reservation_id, request_options: {})`.

```ruby
# app/services/telnyx/number_reservation_service.rb
module Telnyx
  class NumberReservationService
    pattr_initialize [:channel!]

    def perform(phone_number)
      client.number_reservations.create(phone_numbers: [{ phone_number: phone_number }])
    end

    def extend(reservation_id)
      # NOTE: nested under `.actions`, method name has a trailing underscore — not
      # `client.number_reservations.extend(id)`, which doesn't exist.
      client.number_reservations.actions.extend_(reservation_id)
    end

    private

    def client
      @client ||= ::Telnyx::Client.new(api_key: channel.api_key)
    end
  end
end
```

**2. Order — `Telnyx::NumberOrderService` — CONFIRMED**

```ruby
# app/services/telnyx/number_order_service.rb
module Telnyx
  class NumberOrderService
    pattr_initialize [:account!, :phone_number!, :inbox_name!, :api_key!]

    def perform
      ActiveRecord::Base.transaction do
        channel = create_channel!
        order = client(channel).number_orders.create(
          phone_numbers: [{ phone_number: phone_number }]
        )
        # CORRECTED (2026-09-23, against the gem's actual source on GitHub — the two
        # earlier attempts via gemdocs.org's rendered docs never reached this model).
        # The response is wrapped in `.data` (a NumberOrderWithPhoneNumbers), and the
        # per-number field is `regulatory_requirements`, not `requirements` as originally
        # written here — real attribute name confirmed against
        # Telnyx::Models::NumberOrderPhoneNumber's own source.
        ordered_number = order.data.phone_numbers.first
        next_status = ordered_number.regulatory_requirements.present? ? 'requirements_pending' : 'order_placed'
        channel.update!(
          telnyx_number_order_id: order.data.id,
          provisioning_status: next_status,
          regulatory_requirements: ordered_number.regulatory_requirements,
          requirements_deadline_at: ordered_number.deadline # real field, confirmed — not invented
        )
        create_inbox!(channel)
        Telnyx::NumberOrderStatusPollJob.perform_later(channel.id)
        channel
      end
    rescue ::Telnyx::Errors::ConflictError => e
      # 409 — the searched/reserved number is gone (someone else got it, or the
      # reservation expired). The one edge case (§7.1) that maps to a specific,
      # named exception rather than a generic API error.
      raise CustomExceptions::TelnyxNumberUnavailable, e.message
    rescue ::Telnyx::Errors::APIError => e
      # invalid key (AuthenticationError), bad params (BadRequestError/UnprocessableEntityError),
      # rate limited (RateLimitError), Telnyx-side outage (InternalServerError), etc. — see spec §7
      raise CustomExceptions::TelnyxOrderFailed, e.message
    end

    private

    def client(channel)
      @client ||= ::Telnyx::Client.new(api_key: channel.api_key)
    end

    def create_channel!
      account.telnyx_sms.create!(api_key: api_key, medium: :sms, provisioning_status: 'search_pending')
    end

    def create_inbox!(channel)
      account.inboxes.create!(name: inbox_name, channel: channel)
    end
  end
end
```
REST equivalent: `POST /v2/number_orders` with `{"phone_numbers":[{"phone_number":"+1..."}]}`. Gem call (`telnyx.number_orders.create(...)`) confirmed against the gem's own README example, response shape confirmed against the gem's actual source (`NumberOrderCreateResponse` → `NumberOrderWithPhoneNumbers` → `Array<NumberOrderPhoneNumber>`). The `regulatory_requirements` field on the order response is what the flow branches on — not a client-side country check — so this same code path handles both US and India without an `if country_code == 'IN'` branch.

**Real requirement/status enum values, confirmed against source (correcting the earlier prose-only description in the FRD's Appendix E, which had the right shape but wasn't checked against actual code):**
- `NumberOrderPhoneNumber#status` (the number's own status): `pending`, `success`, `failure` — **no `cancelled` at this level**, contrary to what this spec and the FRD previously implied.
- `NumberOrderPhoneNumber#requirements_status` (a separate field — this is where "cancelled" actually lives): `pending`, `approved`, `cancelled`, `deleted`, `"requirement-info-exception"`, `"requirement-info-pending"`, `"requirement-info-under-review"` (the last three are real Ruby symbols with hyphens, e.g. `:"requirement-info-pending"` — note the required quoting).
- Each entry in `regulatory_requirements` has a `field_type`: `textual`, `datetime`, `address`, `document` — **four types, not three.** `RequirementSubmissionService` above only branches on `:document`/`:address`/`:text` — missing a `:datetime` case, a real gap this check surfaced, not present in the original design.

**3a. Requirement lookup (new, not order-dependent) — `Telnyx::RegulatoryRequirementLookupService` — CONFIRMED (2026-09-23)**

Added after finding `Telnyx::Resources::RegulatoryRequirements#retrieve` exists as a standalone, no-order-needed lookup. Not part of the original §6a design — this is a genuine capability upgrade, not a bugfix, and it's why open question §14.7 recommends showing requirements to the admin *before* they commit to a purchase, not just after.

**Live-tested result (2026-09-24):** this endpoint returned `"Feature not permitted at this account level. Refer to https://telnyx.com/upgrade"` (error 10038) against the account used for testing — a different error than a 404, meaning the endpoint is real but gated behind a Telnyx plan tier. Not yet known whether the tier this account is on is representative of what a real NR customer would have, or a sandbox/free-tier limitation specific to testing. This needs confirming with Telnyx before `RegulatoryRequirementLookupService` can be relied on — it may need a fallback (e.g., surfacing requirements only after an order reveals them, the original pre-upgrade design) if the account tier gate turns out to be a real, permanent constraint rather than a sandbox artifact.

```ruby
# app/services/telnyx/regulatory_requirement_lookup_service.rb
module Telnyx
  class RegulatoryRequirementLookupService
    pattr_initialize [:channel!]

    def perform(country_code:, phone_number_type: 'local')
      client.regulatory_requirements.retrieve(
        filter: { country_code: country_code, phone_number_type: phone_number_type, action: :ordering }
      ).data
      # Each entry: id (the real requirement_id), name, description, field_type,
      # example, acceptance_criteria (acceptable_characters/acceptable_values/
      # min_length/max_length/case_sensitive). Real literal India values still
      # unconfirmed — see §14.6 — this call is how to get them, not a substitute
      # for actually calling it once credentials exist.
    end

    private

    def client
      @client ||= ::Telnyx::Client.new(api_key: channel.api_key)
    end
  end
end
```
REST equivalent: `GET /regulatory_requirements?filter[country_code]=IN&filter[phone_number_type]=mobile&filter[action]=ordering`.

**4. KYC/regulatory document submission — `Telnyx::RequirementSubmissionService` — CORRECTED (2026-09-23), not just confirmed**

**The first draft of this service was architecturally wrong, not just missing a method name.** There is no single "submit requirement values" call. It's a real three-step flow, confirmed against Telnyx's `Documents` and `Addresses` resources plus `NumberOrders#update`:

1. **Upload each document** via `Telnyx::Resources::Documents#upload(document:)` (multipart) — returns a document with an `id`. **This ID expires in 30 minutes if not linked to something** — a third independent timer in this feature, after the number reservation (§2a-1a) and the requirements submission deadline (§3). Documents must be uploaded right before submission, not staged ahead of time.
2. **For address-type requirements only**, create an address record via `Telnyx::Resources::Addresses#create(business_name:, country_code:, first_name:, last_name:, locality:, street_address:, ...)` — returns an address with an `id`.
3. **Submit the actual requirement fulfillment** via `Telnyx::Resources::NumberOrders#update(number_order_id, regulatory_requirements: [...])`, where each entry is `{ requirement_id:, field_value: <the document id, address id, or plain text — whichever the requirement_type calls for> }`. `field_value` is **not** raw file content — it's always a reference (ID) to something created via steps 1/2 first, or literal text for non-file requirement types.

```ruby
# app/services/telnyx/requirement_submission_service.rb
module Telnyx
  class RequirementSubmissionService
    # field_submissions example — `type` now covers all four confirmed field_types
    # (Telnyx::Models::SubNumberOrderRegulatoryRequirementWithValue::FieldType), not
    # the three this service originally handled:
    # [
    #   { requirement_id: "req_123", type: :document, file: <uploaded file> },
    #   { requirement_id: "req_456", type: :address, address_attrs: { business_name:, first_name:, ... } },
    #   { requirement_id: "req_789", type: :textual, value: "some text answer" },
    #   { requirement_id: "req_012", type: :datetime, value: "2026-09-23T00:00:00Z" } # e.g. a date-of-birth-style requirement — gap this check surfaced, wasn't handled before
    # ]
    pattr_initialize [:channel!, :field_submissions!]

    def perform
      raise CustomExceptions::InvalidProvisioningState unless channel.provisioning_status == 'requirements_pending'

      # field names confirmed against Telnyx::Models::UpdateRegulatoryRequirement's
      # actual source: `requirement_id` and `field_value`, exactly as originally
      # written — this pairing was a correct guess, unlike the response-side bugs above.
      requirements = field_submissions.map { |submission| { requirement_id: submission[:requirement_id], field_value: resolve_field_value(submission) } }
      client.number_orders.update(channel.telnyx_number_order_id, regulatory_requirements: requirements)
      channel.update!(provisioning_status: 'requirements_under_review')
    end

    private

    def resolve_field_value(submission)
      case submission[:type]
      when :document
        # `submission[:file]` arrives as a Rails ActionDispatch::Http::UploadedFile from the
        # multipart controller param — wrap it in Telnyx::FilePart (confirmed pattern from the
        # gem's own README, used elsewhere in the SDK for file-accepting endpoints) rather than
        # passing the Rails object directly, so filename/content_type are set explicitly instead
        # of relying on the gem to introspect an unfamiliar object type.
        file = Telnyx::FilePart.new(
          submission[:file].read,
          filename: submission[:file].original_filename,
          content_type: submission[:file].content_type
        )
        client.documents.upload(document: file).id # must happen immediately before the update call above — 30-min document expiry
      when :address
        client.addresses.create(**submission[:address_attrs]).id
      when :textual, :datetime
        submission[:value]
      end
    end

    def client
      @client ||= ::Telnyx::Client.new(api_key: channel.api_key)
    end
  end
end
```
This also means edge case §7.13 ("partial requirement submission") needs a small correction: since `field_submissions` is an array covering whatever requirements the admin has ready, a genuinely partial submission is just a shorter array on a later call — `NumberOrders#update` doesn't require all requirements to be submitted in the same call.

**3. Post-activation webhook config — `Telnyx::WebhookSetupService` — CONFIRMED (2026-09-23)**

Exact signature confirmed: `Telnyx::Resources::MessagingProfiles#update(messaging_profile_id, webhook_url: nil, webhook_failover_url: nil, ...)`. The original by-convention guess for this method name turned out correct.

```ruby
# app/services/telnyx/webhook_setup_service.rb
module Telnyx
  class WebhookSetupService
    pattr_initialize [:channel!]

    def perform
      client.messaging_profiles.update(
        channel.messaging_profile_id,
        webhook_url: callback_url,
        webhook_failover_url: nil
      )
    end

    private

    def client
      @client ||= ::Telnyx::Client.new(api_key: channel.api_key)
    end

    def callback_url
      Rails.application.routes.url_helpers.telnyx_callback_url
    end
  end
end
```

## 3. Data model

New table, `channel_telnyx_sms` (the base Phase 1 SMS channel model from FRD PRD-02 — this spec defines it fully rather than assuming a separate migration exists, so it's buildable standalone):

| Column | Type | Notes |
|---|---|---|
| `account_id` | `bigint, null: false` | Owning account |
| `phone_number` | `string` | Blank until the number is active; BYO path sets it immediately |
| `api_key` | `string` | Encrypted (`encrypts :api_key if Chatwoot.encryption_configured?`, same pattern as `Channel::TwilioSms#auth_token`) |
| `messaging_profile_id` | `string` | Telnyx messaging profile the number gets attached to |
| `medium` | `integer, default: 0` | `sms: 0` (only value used in this spec's scope; `whatsapp: 1` is PRD-02/Phase-1-general, not this feature) |
| `country_code` | `string` | `'US'` or `'IN'` — the Phase 1 allowlist (§2a); drives search UI (district picker for India vs. area-code field for US) |
| `provisioning_status` | `string, default: 'byo'` | `byo` \| `search_pending` \| `order_placed` \| `requirements_pending` \| `requirements_under_review` \| `requirements_rejected` \| `active` \| `failed` \| `cancelled` — the three `requirements_*` states are real and used (not reserved-but-unused, per the §2 scope correction) |

**These are NR's own simplified state names, not Telnyx's literal vocabulary — mapping confirmed against the gem's actual source:**

| NR's `provisioning_status` | Derived from Telnyx's real field(s) |
|---|---|
| `order_placed` | `NumberOrderPhoneNumber#status == 'pending'`, `regulatory_requirements` empty |
| `requirements_pending` | `regulatory_requirements` present, `requirements_status == 'requirement-info-pending'` (note the hyphens — real symbol is `:"requirement-info-pending"`) |
| `requirements_under_review` | `requirements_status == 'requirement-info-under-review'` |
| `requirements_rejected` | `requirements_status == 'requirement-info-exception'` |
| `active` | `NumberOrderPhoneNumber#status == 'success'` |
| `failed` | `NumberOrderPhoneNumber#status == 'failure'` |
| `cancelled` | `requirements_status == 'cancelled'` (this lives on `requirements_status`, **not** on `status` — Telnyx's own `status` enum has no `cancelled` value at all, confirmed against source; an earlier draft of this spec and the FRD implied it did) |

`deadline` is a real field directly on `NumberOrderPhoneNumber` (confirmed) — NR's `requirements_deadline_at` column just stores that same value, it isn't a separate NR-invented concept.
| `telnyx_number_order_id` | `string, null: true` | Telnyx's order ID; null for BYO channels |
| `regulatory_requirements` | `jsonb, default: {}` | Telnyx's own description of what's needed (field names, document types) — sourced from the order response, not hardcoded by NR, since requirement shape can vary |
| `requirements_deadline_at` | `datetime, null: true` | Telnyx's submission deadline; miss it and Telnyx auto-cancels the order (spec §7, new edge case below) |
| `provisioning_error` | `string, null: true` | Last error message, shown to the admin on `failed` or `requirements_rejected` |
| `created_at` / `updated_at` | | |

New child table for the actual KYC documents, kept separate from the channel row rather than crammed into `regulatory_requirements` jsonb, since these are file uploads:

```ruby
create_table :telnyx_number_requirement_documents do |t|
  t.bigint :channel_id, null: false # references channel_telnyx_sms
  t.string :requirement_field_name, null: false # e.g. "address_document", "id_document" — matches Telnyx's field_values keys
  t.timestamps
end
```
Actual file storage uses ActiveStorage (`has_many_attached :requirement_documents` on `Channel::TelnyxSms`, or a `has_one_attached :file` on this join table) — same pattern already used for `Call#recording` elsewhere in this codebase, not a new upload mechanism.

Indexes: `account_id`; unique partial index on `telnyx_number_order_id` where not null (one channel per order — prevents a webhook retry from being applied to two rows).

**Decision — Inbox/Channel created at order time, not at activation.** The `Inbox`/`Channel::TelnyxSms` pair is created the moment the order is placed (`provisioning_status: 'order_placed'`), not deferred until Telnyx confirms activation. Alternative considered: wait until active, only then create the inbox. Rejected — that leaves the admin on a bare wizard screen with nothing to look at for however long the order takes (seconds to, in edge cases, longer), whereas an inbox that visibly says "Setting up your number…" in the inbox list is a better, and cheaper, signal. Consequence: a `failed`/`cancelled` provisioning state is a real, permanent state a Channel/Inbox row can be in — the UI and any inbox-listing code must handle it (not assume every Telnyx channel has a working `phone_number`).

## 4. Migration & backfill

Pure `create_table`, no backfill (net-new table, no existing rows). Idempotent by nature (a fresh `create_table` migration). Rollback: `drop_table :channel_telnyx_sms` — safe, since nothing else references this table yet (Phase 1 is the first thing to use it).

```ruby
class CreateChannelTelnyxSms < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_telnyx_sms do |t|
      t.bigint :account_id, null: false
      t.string :phone_number
      t.string :api_key
      t.string :messaging_profile_id
      t.integer :medium, default: 0, null: false
      t.string :country_code
      t.string :provisioning_status, default: 'byo', null: false
      t.string :telnyx_number_order_id
      t.jsonb :regulatory_requirements, default: {}
      t.datetime :requirements_deadline_at
      t.string :provisioning_error
      t.timestamps
    end
    add_index :channel_telnyx_sms, :account_id
    add_index :channel_telnyx_sms, :telnyx_number_order_id, unique: true,
              where: 'telnyx_number_order_id IS NOT NULL'
  end
end

class CreateTelnyxNumberRequirementDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :telnyx_number_requirement_documents do |t|
      t.bigint :channel_id, null: false
      t.string :requirement_field_name, null: false
      t.timestamps
    end
    add_index :telnyx_number_requirement_documents, :channel_id
  end
end
```

## 5. Authorization & security

- Search and order endpoints: admin-only, same Pundit gate pattern as `Api::V1::Accounts::Channels::TwilioChannelsController` (account admin role required to create/modify inboxes).
- `api_key` encrypted at rest, same conditional-encryption pattern already used for Twilio's `auth_token`/`api_key_secret`.
- Order-status webhook: **Ed25519 signature verification required** (`telnyx-signature-ed25519`/`telnyx-timestamp` headers), consistent with the security stance already committed to for the SMS webhooks (FRD PRD-03) and the Voice Architecture Design (§8) — no exception for this endpoint.
- Search endpoint is a live proxy to Telnyx's API using the account's own key — rate-limit it server-side (e.g. per-account throttle) so a misbehaving client can't be used to hammer Telnyx's search API through NR's backend.
- **Correction (§2 scope correction):** an earlier draft of this spec said no PII beyond the phone number is handled in Phase 1. That's no longer true — India's KYC flow means NR now accepts and (briefly) stores real identity documents (address proof, government ID). This is a genuinely new data-handling surface for the codebase, not a minor addendum:
  - Documents are forwarded to Telnyx and not meant to be retained by NR beyond what's needed to resubmit on rejection — needs a real retention policy (e.g. auto-purge N days after the order reaches a terminal state: `active` or `cancelled`), not "keep forever by default" the way ActiveStorage attachments elsewhere in this app might be.
  - Access to uploaded documents restricted to the submitting admin and the request that forwards them to Telnyx — no separate "view uploaded ID" surface for other agents/admins in the UI.
  - This is exactly the kind of "new codepaths need threat modeling" item worth a second pair of eyes before it ships — flagged in §14, not resolved unilaterally here.

## 6. Interfaces / endpoints / events

| Interface | Method/Path | Request | Response | Auth |
|---|---|---|---|---|
| Search | `GET /api/v1/accounts/:account_id/channels/telnyx/available_numbers` | `country_code` (**client-selected**, constrained server-side to `US`/`IN` — no longer forced to `US`), `locality` (district name for India, city for US), `administrative_area`, `phone_number_type` | List of `{ phone_number, region, locality, monthly_cost, requirements_summary }` — India results included, not filtered out | Admin |
| **Reserve — new** | `POST /api/v1/accounts/:account_id/channels/telnyx/number_reservations` | `{ phone_number }` — called when the admin picks a number from search results, before the confirm step | `{ reservation_id, expires_at }` (30 min out) | Admin |
| Order | `POST /api/v1/accounts/:account_id/channels/telnyx/number_orders` | `{ phone_number, inbox_name, country_code, reservation_id }` | `{ inbox_id, channel_id, provisioning_status }` — status is `order_placed` (US, typical) or `requirements_pending` (India, typical) | Admin |
| **Submit requirements — new, corrected shape (§2a call 4)** | `POST /api/v1/accounts/:account_id/channels/telnyx/number_orders/:channel_id/requirements` | Multipart: an array of submissions, each `{ requirement_id, type: 'document'\|'address'\|'text', file / address_attrs / value }` — the endpoint itself does the upload-then-reference dance (Documents/Addresses APIs) before calling `NumberOrders#update`; the client never sees a document/address ID directly | `{ provisioning_status: 'requirements_under_review' }` | Admin |
| Poll (fallback) | `GET /api/v1/accounts/:account_id/channels/telnyx/number_orders/:channel_id` | — | `{ provisioning_status, provisioning_error, regulatory_requirements, requirements_deadline_at }` | Admin |
| Order-status webhook | `POST /telnyx/number_order_status` | Telnyx's order-event payload | `204` | Ed25519-verified, no session |

Idempotency: the order endpoint requires a client-generated `Idempotency-Key` header; a retry with the same key returns the original result rather than placing a second order. (Exact mechanism — request-scoped cache vs. a dedicated table — is an open implementation detail, see §14.)

## 7. Business rules & edge cases

1. **Now mostly solved by reservation, not just handled after the fact:** admin picks a number → NR reserves it for 30 minutes → the normal case (confirm-and-order within 30 min) never hits a "taken" race. What's still a real edge case: reservation itself expires (admin idle >30 min, e.g. stuck mid-KYC-upload) — the flow needs to either auto-extend (via `NumberReservationService#extend`, §2a) while the admin is actively completing requirements, or clearly tell them their hold expired and to search again, not silently fail on order.
2. Country is constrained server-side to the Phase 1 allowlist (`US`, `IN`) regardless of what the client requests — this is enforced in `NumberSearchService`, not just in the UI, so a crafted request can't ask for an unsupported country. (Corrects the earlier "no regulatory requirements" filter, which is no longer applied — see §2.)
3. Duplicate order submission (double-click, network retry) must not create two channels/inboxes for the same purchase attempt — enforced via the `Idempotency-Key` header plus the unique index on `telnyx_number_order_id`.
4. The order-status webhook may be delayed or lost. A background poll job is the fallback, not the only path — see §8.
5. Order fails on Telnyx's side (declined, invalid key, insufficient balance) → `provisioning_status: 'failed'`, `provisioning_error` set, channel/inbox is **not** deleted (stays as a visible failure the admin can act on — delete and retry), no automatic retry.
6. Invalid webhook signature → reject with `401`, log distinctly (same "surface a mass-invalid-signature pattern, don't let it blend into generic 4xx noise" principle from the Voice Architecture Design §14).
7. An account tries to order a number that duplicates one already active on another Telnyx channel in the same account → rejected with a clear validation error before the order API call is even made.
8. Telnyx API key is invalid/expired at the moment of ordering (not just at inbox-creation time for BYO) → surfaced as a `failed` provisioning state with the API's error message, not a silent no-op.
9. Admin navigates away or closes the tab mid-order — the order and channel/inbox already exist server-side (created synchronously in the order endpoint, not client-side), so this doesn't lose the order; the admin can return to the inbox list and see its provisioning state.
10. **India: a searched district isn't one of the four authorized ones.** Rejected client-side (the district picker only offers the four) *and* server-side in `NumberSearchService` (§2a) — never trust the client-side constraint alone.
11. **India: submitted KYC documents are rejected by Telnyx** (`requirements_rejected`) — admin sees the specific rejection reason (from Telnyx's response) and can resubmit; previously-uploaded documents for that requirement are replaced, not appended.
12. **India: the submission deadline (`requirements_deadline_at`) passes before documents are submitted** — Telnyx auto-cancels the order; NR's poll job (§8) must catch this transition to `cancelled` and surface it clearly, not leave the channel silently stuck showing "requirements pending" forever.
13. **India: partial requirement submission** — Telnyx may return multiple required fields (e.g. both an address document and an ID document); the submission endpoint must handle "some fields submitted, others still pending" as a real intermediate state, not assume one submission satisfies everything.
14. Uploaded KYC documents must be validated for file type/size before forwarding to Telnyx (standard upload hygiene) — this is the one place in this feature where NR accepts arbitrary file uploads from an admin, worth the same scrutiny any file-upload endpoint gets.

## 8. Background jobs & external calls

- **`Telnyx::NumberOrderStatusPollJob`** — fallback poller for when the webhook doesn't arrive. Behavior now branches by whether the order has requirements (§2's scope correction means this can no longer assume one timeline for everyone):
  - **US, no requirements:** checks status every 30s for up to 5 minutes (Telnyx's own docs describe no-requirement activation as "momentary"), then marks `failed` with a "still pending" error if it never resolves.
  - **India, requirements pending/under review:** polls on a much slower cadence (e.g. hourly, not every 30s — there's no value hammering an endpoint that's waiting on human review at Telnyx), and does **not** time out into `failed` the way the US path does — it keeps polling until `requirements_deadline_at` passes (→ `cancelled`, edge case §7.12) or Telnyx reports a terminal state.
  - Retries on transient HTTP errors the same way `Voice::Provider::Twilio::RecordingAttachmentJob` retries on `Down::Error`, for both paths. **Note (confirmed via the gem's README):** the `telnyx` gem already retries connection errors, `408`/`409`/`429`/`5xx` responses itself, 2 attempts with exponential backoff, before an exception even reaches this job's code. The job's own `retry_on` isn't redundant — it's a second, outer layer for retrying the *poll itself* over a period of minutes/hours, not the same thing as the gem's per-request retry — but worth knowing the two layers exist so nobody "fixes" a perceived double-retry bug that isn't one. Per-request retry count/timeout is tunable via `request_options: { max_retries:, timeout: }` on any call if the job's outer cadence ever needs the inner layer backed off too.
- **`Telnyx::WebhookSetupService`** — synchronous within the status-update path (webhook or poll job) once `provisioning_status` transitions to `active`: configures the messaging webhook URL on the now-owned number via the Telnyx API (PRD-06), same responsibility `Twilio::WebhookSetupService` has today.
- External calls, all confirmed (§2a): `client.available_phone_numbers.list` (search), `client.number_reservations.create` + `client.number_reservations.actions.extend_` (reserve), `client.number_orders.create` (order), `client.documents.upload` + `client.addresses.create` + `client.number_orders.update` (requirement submission), `client.messaging_profiles.update` (post-activation webhook config) — all via the `telnyx` gem already planned in the FRD's Appendix C.

## 9. Performance / scalability

Not material — this is an admin-driven, low-frequency action (searching and buying a number happens once per inbox setup, not a hot path). No batching, pagination beyond what the search API itself returns, or caching need identified.

## 10. Observability & instrumentation

- Log/event on each state transition: `telnyx_number_order.placed`, `.requirements_pending`, `.requirements_submitted`, `.requirements_rejected`, `.activated`, `.failed`, `.cancelled`, `.webhook_signature_invalid` — tagged with `account_id`, `channel_id`, `order_id`, `country_code`.
- Dashboard/alert, US path: count of channels stuck in `order_placed` for longer than the 5-minute no-requirement window — a real "something's wrong" signal distinct from an expected `failed` state.
- Dashboard, India path: count of channels sitting in `requirements_pending` (nobody's submitted documents yet) vs `requirements_under_review` (submitted, waiting on Telnyx) — different signals, one is "admin hasn't acted," the other is "waiting on a third party," and they shouldn't be conflated in one metric.
- Reuses the `channel_provider: telnyx` tagging convention already established in the FRD (§12).

## 11. Test plan

| Spec file | Covers |
|---|---|
| `spec/services/telnyx/number_search_service_spec.rb` | Filter passthrough, country allowlist enforcement (rejects unsupported country), India district validation, Telnyx API error handling |
| `spec/services/telnyx/number_order_service_spec.rb` | Order creation, channel+inbox creation, branches correctly to `order_placed` (no requirements) vs `requirements_pending` (has requirements) based on the order response, idempotency-key dedupe, duplicate-number rejection, `Telnyx::Errors::ConflictError` → `TelnyxNumberUnavailable` mapping specifically (distinct from the generic `Telnyx::Errors::APIError` catch-all) |
| `spec/services/telnyx/requirement_submission_service_spec.rb` | Rejects submission when not in `requirements_pending` state, transitions to `requirements_under_review`, partial-field submission (edge case §7.13) |
| `spec/services/telnyx/webhook_setup_service_spec.rb` | Webhook config call on activation |
| `spec/controllers/api/v1/accounts/channels/telnyx_numbers_controller_spec.rb` | Admin-only auth, search/order/poll/requirements-submit happy paths and errors, file upload validation (edge case §7.14) |
| `spec/controllers/telnyx/number_order_status_controller_spec.rb` | Valid/invalid Ed25519 signature, status transitions applied for both US and India paths |
| `spec/jobs/telnyx/number_order_status_poll_job_spec.rb` | US: poll → active, poll → timeout → failed. India: poll → requirements_under_review (no timeout), poll → deadline passed → cancelled, retry-on-transient-error for both |
| `spec/models/channel/telnyx_sms_spec.rb` | Validations, encryption, full provisioning-state transition graph (including the three `requirements_*` states) |
| Frontend component test | Both flows: US (search → results → order → pending → active/failed) and India (search within district → results → order → document upload → under review → active/rejected) |

## 12. Rollout & rollback

Behind the FRD's `channel_provider_telnyx` flag. Rollback is flag-off; the migration is purely additive (`create_table`, nothing else touched), so disabling requires no data cleanup — any channel already provisioned stays queryable, just not creatable for new inboxes while the flag is off. No dual-write or backfill concerns, consistent with the sibling Voice Architecture Design's rollback stance.

## 13. Jira task breakdown

~~1. Verify `telnyx` gem method names for number reservation, messaging-profile webhook config, and requirement submission (§2a, calls 1a, 3, and 4)~~ — **done (2026-09-23), confirmed against gemdocs.org's rendered docs for `telnyx` 5.168.0**, no longer a Jira task. Corrected two real bugs in the process: reservation extend is `client.number_reservations.actions.extend_(id)` not `.extend(id)`, and requirement submission is a 3-step Documents/Addresses/NumberOrders#update flow, not the single-call design originally spec'd. See §2a for the corrected code.
2. Migrations: `channel_telnyx_sms` + `telnyx_number_requirement_documents` tables (§4) — 0.5d
3. `Channel::TelnyxSms` model: validations, encryption, full provisioning-state graph (§3) — 1.5d
4. `Telnyx::NumberSearchService` + spec, including India district validation — 1.5d
5. `Telnyx::NumberReservationService` + `Telnyx::NumberOrderService` + spec (reserve-then-order, reservation-expiry/extend handling, idempotency, requirements-vs-no-requirements branching) — 2.5d, depends on task 1
6. `Telnyx::RequirementSubmissionService` + spec, plus file-upload validation (§7.14) and retention-policy job (§5) — 2d
7. `Telnyx::NumberOrderStatusPollJob` + spec, dual cadence for US vs. India (§8) — 1.5d
8. Order-status webhook controller + Ed25519 verifier + spec — 1.5d
9. `Telnyx::WebhookSetupService` (post-activation) + spec — 1d, depends on task 1
10. `Api::V1::Accounts::Channels::TelnyxNumbersController` (search/order/poll/requirements-submit) + spec — 2d
11. Frontend: search-and-buy flow, US branch (all states) — 1.5d
12. Frontend: search-and-buy flow, India branch — district picker, KYC document upload form, rejection/resubmission UI — 2.5d
13. i18n strings, `en.yml` + `en.json` (now covers two country flows, not one) — 1d
14. Manual QA against a real Telnyx sandbox account — **both** a US order and an India order with real KYC documents — 1.5d

## 14. Open questions / recommendations

~~1. `telnyx` gem method names — not yet verified.~~ **Resolved 2026-09-23** — all confirmed against gemdocs.org for `telnyx` 5.168.0. See §2a for corrected code; the requirement-submission redesign (Documents → Addresses → NumberOrders#update, not a single call) is the one worth a second engineer's eyes before implementation starts, given it's the newest and least-exercised part of this spec.
2. **Idempotency-key mechanism** — client-generated UUID header cached server-side for a short window, vs. a dedicated idempotency-keys table. **Recommendation:** start with a Redis-cached key (short TTL, matches the low-stakes/low-volume nature of this flow) rather than a new table — upgrade later only if it proves insufficient.
3. **Cost-confirmation step before purchase (FRD Open Question 8, still unresolved by Product)** — this spec assumes a confirm-before-charge UI step is required, since this is the one action in the whole FRD that spends the customer's real money. **Recommendation:** show the number's monthly cost in the results list and require an explicit "Buy this number — $X/mo" confirmation click before the order fires. Needs Product sign-off before this is final, not just an engineering default.
4. **KYC document retention policy — not yet decided (§5).** How long does NR keep uploaded ID/address documents after the order reaches a terminal state? **Recommendation:** auto-purge N days (e.g. 30) after `active` or `cancelled`, since NR has no ongoing need for them once Telnyx has approved or the attempt is dead — needs a real decision, not left as "ActiveStorage default," given these are identity documents.
5. **Country allowlist: hardcoded `['US', 'IN']` vs. config-driven (FRD Open Question 9)** — this spec hardcodes it in `NumberSearchService::ALLOWED_COUNTRY_CODES` (§2a) for Phase 1 simplicity. **Recommendation:** fine as a constant for Phase 1 given only two countries exist today; revisit as config/DB-driven only if a third country is actually requested, not preemptively.
6. **Narrowed twice now (2026-09-23).** First pass: the field *types* are fully confirmed (`field_type`: `textual`/`datetime`/`address`/`document`, per `SubNumberOrderRegulatoryRequirementWithValue`'s real source). Second pass, a real capability upgrade: there's a **standalone lookup for exactly this**, confirmed against source — `Telnyx::Resources::RegulatoryRequirements#retrieve(filter: { country_code:, phone_number_type:, action: :ordering })` (`GET /regulatory_requirements`, no order needed, no cost). Its response gives the real `id` (the actual `requirement_id` to use later), `name`, `description`, `field_type`, `example`, and `acceptance_criteria` (accepted characters/values, min/max length, case sensitivity) for every requirement a given country+number-type combination needs. **What's still unresolved is only the literal India values** — this session has no Telnyx API credentials to actually call the endpoint, and Telnyx's public docs only show worked examples for Germany/Switzerland, not India. **Recommendation, revised:** this is now a 5-minute authenticated API call (`regulatory_requirements.retrieve(filter: { country_code: 'IN', phone_number_type: 'mobile', action: 'ordering' })`), not "place a real sandbox order and see what happens" as previously framed — a much smaller ask than §13.14's full manual QA pass, and worth doing standalone, earlier, as soon as anyone has a Telnyx API key, rather than waiting for the QA phase.
7. **New, surfaced by finding this lookup exists: should NR call it *before* the admin commits to a purchase, not just discover requirements after ordering?** Right now this spec's flow (§2, §6) only reveals requirements after the order is placed (`order_placed` → `requirements_pending`). Since `RegulatoryRequirements#retrieve` needs no order, NR could show "here's what India requires" as informational copy at the country/district-selection step — before the admin has committed to anything — which is a materially better UX than "surprise, now go find your ID and address documents" after they've already picked a number. **Recommendation:** worth adding to Phase 1 scope given how cheap the API call is, but it's scope growth beyond what §6a originally specified, so flagging rather than silently adding it.
8. **Document upload's 30-minute expiry (§2a call 4) needs the same "don't stage ahead of time" UX care as the number reservation.** If the admin uploads a document, then gets distracted before hitting final submit, the document ID could be dead by the time `NumberOrders#update` runs. **Recommendation:** upload documents at the point of final submission (one atomic "Submit" action), not as each file is individually attached in the form — matches how the code in §2a is structured (upload happens inside `perform`, not as a separate pre-step).
9. **Two valid submission paths exist, and this spec picked one without comparing them.** Telnyx's gem has both `NumberOrders#update(number_order_id, regulatory_requirements:)` (order-level, what §2a call 4 uses) and `NumberOrderPhoneNumbers#update_requirements(number_order_phone_number_id, regulatory_requirements:)` (per-phone-number level) — confirmed as two separate real resources, not a guess. Since Phase 1 orders exactly one number per order, they're likely equivalent in practice here, but the per-number path is arguably more correct in general (an order *can* cover multiple numbers with independent requirement states) and this spec didn't investigate whether one is preferred/deprecated. **Recommendation:** worth a quick confirmation against Telnyx's own docs or support before implementation — not worth blocking on, since a wrong pick here is a one-line service change, not a design-level mistake.

## 15. Approval

| Gate | Who | Date |
|---|---|---|
| Spec approved | TBD | TBD |

**Sources (gem verification, 2026-09-23):** [gemdocs.org: NumberReservations](https://gemdocs.org/gems/telnyx/5.168.0/Telnyx/Resources/NumberReservations.html) · [gemdocs.org: NumberReservations::Actions](https://gemdocs.org/gems/telnyx/5.168.0/Telnyx/Resources/NumberReservations/Actions.html) · [gemdocs.org: MessagingProfiles](https://gemdocs.org/gems/telnyx/5.168.0/Telnyx/Resources/MessagingProfiles.html) · [gemdocs.org: NumberOrders](https://gemdocs.org/gems/telnyx/5.168.0/Telnyx/Resources/NumberOrders.html) · [gemdocs.org: Documents](https://gemdocs.org/gems/telnyx/5.168.0/Telnyx/Resources/Documents.html) · [gemdocs.org: Addresses](https://gemdocs.org/gems/telnyx/5.168.0/Telnyx/Resources/Addresses.html) · [Telnyx regulatory requirements docs](https://developers.telnyx.com/docs/numbers/phone-numbers/regulatory-requirements/index) · [team-telnyx/telnyx-ruby README (errors, retries, file uploads, request_options)](https://github.com/team-telnyx/telnyx-ruby) · [gemdocs.org: AvailablePhoneNumbers](https://gemdocs.org/gems/telnyx/5.168.0/Telnyx/Resources/AvailablePhoneNumbers.html) · [gemdocs.org: AvailablePhoneNumberListParams::Filter](https://gemdocs.org/gems/telnyx/5.168.0/Telnyx/Models/AvailablePhoneNumberListParams/Filter.html) · [team-telnyx/telnyx-code-examples](https://github.com/team-telnyx/telnyx-code-examples) · [team-telnyx/demo-ruby-telnyx: console-search-and-order-numbers](https://github.com/team-telnyx/demo-ruby-telnyx/tree/main/console-search-and-order-numbers) (concept-confirming only — uses a superseded pre-5.x API style, see the warning at the top of this section) · [telnyx-ruby source: update_regulatory_requirement.rb](https://github.com/team-telnyx/telnyx-ruby/blob/main/lib/telnyx/models/update_regulatory_requirement.rb) · [number_order_phone_number.rb](https://github.com/team-telnyx/telnyx-ruby/blob/main/lib/telnyx/models/number_order_phone_number.rb) · [number_order_with_phone_numbers.rb](https://github.com/team-telnyx/telnyx-ruby/blob/main/lib/telnyx/models/number_order_with_phone_numbers.rb) · [available_phone_number_list_response.rb](https://github.com/team-telnyx/telnyx-ruby/blob/main/lib/telnyx/models/available_phone_number_list_response.rb) · [cost_information.rb](https://github.com/team-telnyx/telnyx-ruby/blob/main/lib/telnyx/models/cost_information.rb) · [sub_number_order_regulatory_requirement_with_value.rb](https://github.com/team-telnyx/telnyx-ruby/blob/main/lib/telnyx/models/sub_number_order_regulatory_requirement_with_value.rb) · [number_order_phone_number_update_requirements_params.rb](https://github.com/team-telnyx/telnyx-ruby/blob/main/lib/telnyx/models/number_order_phone_number_update_requirements_params.rb) (2026-09-23: fetched directly via `gh api` — this pass caught two real bugs gemdocs.org's rendered docs hadn't surfaced, and confirmed the rest) · [regulatory_requirements.rb (resource)](https://github.com/team-telnyx/telnyx-ruby/blob/main/lib/telnyx/resources/regulatory_requirements.rb) · [regulatory_requirement_retrieve_params.rb](https://github.com/team-telnyx/telnyx-ruby/blob/main/lib/telnyx/models/regulatory_requirement_retrieve_params.rb) · [regulatory_requirement_retrieve_response.rb](https://github.com/team-telnyx/telnyx-ruby/blob/main/lib/telnyx/models/regulatory_requirement_retrieve_response.rb) · [Telnyx regulatory requirements docs (no India worked example found)](https://developers.telnyx.com/docs/numbers/phone-numbers/regulatory-requirements/index)
