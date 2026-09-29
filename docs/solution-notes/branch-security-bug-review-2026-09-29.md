# Branch Review — Security & Bugs (2026-09-29)

**Scope:** custom features on `feature/phone-reseller` (661 commits over upstream Chatwoot): MCP server, Comment-to-DM automation, Reputation / Reviews, CRM (deals/pipelines), billing (Razorpay, marketplace checkout). Number Provisioning is in its own file: [number-provisioning-code-review-2026-09-29.md](number-provisioning-code-review-2026-09-29.md).

**Depth:** security + correctness only (tenancy leaks, auth gaps, money, broken flows). No style/UI review. Reviewed by reading code; nothing below was reproduced by running it. Where a finding depends on a vendor API, the doc was checked and is cited.

**How to use:** fill each **Decision** cell, then record the implementation choice in that feature's decision log.

Severity: **P1** = security hole, money loss, or the feature can't work · **P2** = wrong behaviour on a realistic path · **P3** = low risk.

---

## Summary

| # | Sev | Feature | Finding |
|---|---|---|---|
| R-1 | P1 | Reputation | Anyone on the internet can post reviews into **any** account; they show on that account's public website widget |
| B-1 | P1 | Billing | Razorpay dedupe key uses the event *name* → every monthly `subscription.charged` after the first is skipped |
| C-1 | P1 | Comment→DM | DM sent with `recipient: { id }`; Meta requires `recipient: { comment_id }` for a DM to a commenter — real DMs fail |
| R-2 | P1 | Reputation | TLS verification turned off for Google OAuth/API calls when `RAILS_ENV=development` — and dev.newrelay.com runs as development |
| M-1 | P1 | MCP | MCP tools work on **suspended** accounts (the REST API blocks them) |
| R-3 | P2 | Reputation | `oauth_session_id` is any Redis key the caller names — not bound to the account |
| D-1 | P2 | CRM | A deal can point at another account's pipeline/stage |
| C-2 | P2 | Comment→DM | Campaign `inbox_id` not checked against the account |
| C-3 | P2 | Comment→DM | Rate limiter SCANs the whole Redis keyspace on every DM |
| M-2 | P2 | MCP | Any existing API token with empty scopes gets full MCP access, including `send_reply` |
| M-3 | P2 | MCP | Write tools only check "can view conversation", not reply/assign permission |
| M-4 | P3 | MCP | `remove_label` is case-sensitive while `add_label` lowercases |
| C-4 | P3 | Comment→DM | Public-reply failure recorded as `dm_failed` |
| R-4 | P3 | Reputation | OAuth callback error path raises again on bad `state` → 500; raw provider error in redirect URL |
| B-2 | P3 | Billing | Marketplace checkout accepts any `success_url` / `cancel_url` |

---

## P1

### R-1 · Unauthenticated review injection into any account

**Where:** `app/controllers/reputation/public_reviews_controller.rb:14` (`POST /reputation/review/:account_id`), `app/controllers/reputation/public_widgets_controller.rb:23,55`.

**What happens:** no login, no token, no rate limit (the only reputation throttle in `config/initializers/rack_attack.rb:194` is for `/reputation/feedback`). `account_id` is sequential, so anyone can loop 1..N and post a review with any name, text and rating 1–5 into every account. If the account has no Google integration, one is **created** with status `active` (`google_integration`, line 41). The review is saved `status: :pending`, and the public widget shows every review that is not `ignored` — so injected text appears on the customer's own website. `GET …/new` also reveals every account's name by ID.

**Options:**
- **A (recommended):** require a signed per-account token in the URL (same `token` pattern `ReviewRequest`/`Widget` already use) instead of the raw account ID; add a Rack::Attack throttle; don't auto-create an integration.
- B: keep the URL, add throttle + only show `published`/approved reviews in widgets. Stops the widget display, not the spam.

**Decision:** ______

### B-1 · Razorpay renewals skipped after the first charge

**Where:** `enterprise/app/services/enterprise/billing/handle_razorpay_event_service.rb:4`.

**What happens:** `event_id = @event[:event] || @event[:id]` — `event` is the event **name** (`"subscription.charged"`). The dedupe key becomes `razorpay_subscription.charged_<sub_id>`. Month 2's `subscription.charged` for the same subscription has the same key → returns early. `current_period_end` never advances (grace-period/suspension logic then sees an expired period), and `transfer_agency_share!` only runs once, so resellers are paid for month 1 only.

**Verified:** Razorpay's webhook best-practices doc says to dedupe on the `x-razorpay-event-id` **header**, "unique per event". The body has no event id.

**Recommended:** pass `request.headers['X-Razorpay-Event-Id']` from `Enterprise::Webhooks::RazorpayController` into the service and use it as the dedupe key. Check whether any account already has a stale `current_period_end` from this.

**Decision:** ______

### C-1 · Instagram DM uses the wrong recipient field

**Where:** `app/jobs/comment_automation/dm_dispatch_job.rb:51`.

**What happens:** body is `recipient: { id: log.commenter_id }`. A commenter who has never messaged the account has no open conversation, so a DM by user ID is rejected. The whole feature (comment → DM) fails for real users; mock mode hides it because mock channels skip the HTTP call.

**Verified:** Meta Instagram Private Replies doc: recipient must be `{ "comment_id": "<COMMENT_ID>" }`, sent within 7 days of the comment; follow-ups only after the user replies (24h window).

**Recommended:** send `recipient: { comment_id: log.comment_id }`. Also fail (don't retry) logs older than 7 days.

**Decision:** ______

### R-2 · TLS verification disabled on a real deployed host

**Where:** `app/services/reputation/oauth_service.rb:30`, `app/controllers/api/v1/accounts/reputation/integrations_controller.rb:31,233`, `app/jobs/reputation/listing_image_job.rb:53`.

**What happens:** `verify: false if Rails.env.development?`. `config/initializers/fast_mcp.rb` documents that dev.newrelay.com is a real, reachable host running `RAILS_ENV=development`. On that host the Google OAuth code exchange and Google Business API calls accept any certificate, so a network attacker can capture OAuth access/refresh tokens.

**Recommended:** delete the `verify: false` lines. If a local machine has a broken CA bundle, fix the bundle (or use an explicit env flag defaulting to verify on).

**Decision:** ______

### M-1 · MCP works on suspended accounts

**Where:** `app/tools/mcp/base_tool.rb:84` (`require_account!`).

**What happens:** REST API rejects suspended accounts (`app/controllers/concerns/ensure_current_account_helper.rb:11`, `account.active?`). MCP checks membership and the `mcp_integration` feature flag only — a suspended (e.g. non-paying) account can still read conversations and send replies over MCP.

**Recommended:** add `raise ToolError, 'Account is suspended' unless account.active?` in `require_account!`, and filter `list_accounts` the same way.

**Decision:** ______

---

## P2

### R-3 · `oauth_session_id` reads any Redis key

**Where:** `integrations_controller.rb:21,71`. The callback writes `reputation_google_oauth_<account_id>_<hex>`; the API reads whatever key the client sends, with no prefix/account check. The random suffix makes stealing another account's token impractical, but the endpoint still reads arbitrary Redis keys and the token is reusable for 15 min.

**Recommended:** reject keys not starting with `reputation_google_oauth_#{current_account.id}_`; delete the key after a successful connect.

**Decision:** ______

### D-1 · Deal can reference another account's pipeline

**Where:** `app/models/deal.rb` validates stage↔pipeline, contact, owner, company — but not `pipeline.account_id == account_id`. `DealsController#deal_params` permits `pipeline_id`/`pipeline_stage_id`. A CRM user can create a deal on another tenant's pipeline ID; `index` then renders that pipeline/stage (names leak across tenants).

**Recommended:** add `validate :pipeline_belongs_to_account` (same shape as `contact_belongs_to_account`).

**Decision:** ______

### C-2 · Campaign `inbox_id` not scoped to the account

**Where:** `campaigns_controller.rb:36`. `inbox_id` is permitted with no ownership check. `InboundCommentJob` matches on `inbox.account_id`, so no DM is sent from a foreign inbox, but `index` (`includes(:inbox)`) can render another tenant's inbox data.

**Recommended:** in `create`/`update`, `Current.account.inboxes.find(campaign_params[:inbox_id])`. Same for trigger `template_id`.

**Decision:** ______

### C-3 · Rate limiter scans the whole Redis keyspace per DM

**Where:** `app/services/comment_automation/rate_limiter.rb:20` → `Redis::Alfred.keys_count` = `SCAN` over every key in the DB. Cost grows with total Redis size (all Sidekiq/cache keys), on every DM, and any Redis error fails closed (no DMs).

**Recommended:** one counter per inbox per second: `INCR comment_automation:send:<inbox>:<epoch_sec>` + `EXPIRE 2`.

**Decision:** ______

### M-2 · Existing API tokens become full MCP tokens

**Where:** `base_tool.rb` `authorize_scope!` — blank `scopes` = every tool allowed. Every user's existing dashboard access token has blank scopes, so once an account enables `mcp_integration`, any leaked old API token can also `send_reply` over MCP.

**Options:** **A (recommended):** require an explicit scope list for MCP (blank = deny). B: accept — the REST API already allows the same actions with that token.

**Decision:** ______

### M-3 · Write tools only check read permission

**Where:** `send_reply`, `set_status`, `assign_conversation`, labels — all gate on `ConversationPolicy#show?`. With Enterprise custom roles, a role that can view but not reply/assign/manage can still do those over MCP.

**Recommended:** check the same permission the REST controller for each action checks (e.g. `MessagePolicy#create?`, conversation assignment policy).

**Decision:** ______

---

## P3

| # | Where | Issue | Recommended | Decision |
|---|---|---|---|---|
| M-4 | `app/tools/mcp/remove_label_tool.rb:21` | `add_label` downcases input; `remove_label` doesn't, so removing "Billing" silently does nothing | `labels.map(&:downcase)` | ______ |
| C-4 | `public_reply_job.rb` `fail_log` | Public-reply failure stored as `dm_failed`; message log UI can't tell which step failed | Add `public_reply_failed` status or accept | ______ |
| R-4 | `oauth_callbacks_controller.rb:13` | Bad/expired `state` → rescue calls `settings_url` → `current_account` raises again → 500. Error message (may include Google response body) put in redirect URL | Render a plain error when state is invalid; generic message in URL | ______ |
| B-2 | `marketplace_checkout_controller.rb:9` | `success_url`/`cancel_url` taken from params unvalidated (open redirect after payment) | Only allow `FRONTEND_URL` host | ______ |

---

## Checked and fine

- **Razorpay webhook** verifies HMAC-SHA256 with `secure_compare`; missing secret = reject.
- **Reputation API** base controller: `administrator`/`reputation_manage` gate, per-listing scoping for non-admins.
- **Reputation public feedback / video upload / redirect**: gated by unguessable `ReviewRequest.token` + `live_for_public_submit?`; feedback throttled 10/hour/IP.
- **Reputation OAuth state**: signed with `message_verifier`, 15-minute expiry.
- **Comment automation**: all endpoints admin-only; mock endpoints refuse unless `COMMENT_AUTOMATION_PROVIDER=mock`; dedupe on unique `(inbox_id, comment_id)` before any send.
- **MCP**: token → user → account membership → feature flag; conversation lookups scoped to `current_account` + policy; `Current.reset` in `ensure`.
- **CRM**: `administrator`/`crm_manage` policy; all finds scoped to `Current.account`; contact/owner/company tenancy validated.

## Not covered

- Email/mailer and Super Admin controllers (billing coupons, plans, email templates, Cloudflare domains): Super Admin–only, not reviewed in depth.
- Frontend code for these features, UI/design consistency, i18n.
- Upstream Chatwoot code merged into this branch.
- No specs were run.
