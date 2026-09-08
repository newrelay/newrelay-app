# FRD: Comment-to-DM Automation

**Status:** Shipped (core matching/DM pipeline is real and production-capable for Instagram); Partial (social-account/response-control management UI is currently backed by a mock store, not real per-platform account data)
**Module:** newrelay custom
**Last updated:** 2026-09-07

> See also `docs/solution-notes/comment-to-dm-automation-prd.md` (original PRD) and `openreply-automation-prd.md`.

---

## 1. What it is

**One-liner:** When someone comments a matching keyword on an Instagram post, automatically reply publicly and send them a DM — a lead-gen/engagement automation ("comment WORD to get X") common on Instagram/TikTok growth funnels.

**Who uses it:** Marketers/admins (set up campaigns per post, define keyword triggers and reply/DM copy), end Instagram users (comment, receive automated public reply + DM).

---

## 2. How it works

### Real, production pipeline (comment matching → DM send)
1. Instagram's webhook (`POST /webhooks/instagram`, verified via `GET .../verify`) delivers comment-change events. `CommentAutomation::InboundCommentJob#process_entry` resolves the target `Channel::Instagram`/`inbox` from the webhook payload's page id.
2. For each `comments`-field change, `process_comment` looks up **active campaigns for that specific post** (`CommentAutomation::Campaign.active_for_post(inbox:, post_id:)`) — campaigns are scoped to one Instagram post (`post_id`), not account-wide.
3. `CommentAutomation::MatchEngine#match` finds the first trigger whose `keyword` matches the comment text (`exact` match_type or substring `include?`, case-insensitive) — a blank keyword matches everything (catch-all trigger). Self-comments (the business's own account replying to itself) are explicitly excluded.
4. A `CommentAutomation::MessageLog` row is created **first**, before any reply is sent — its unique index on `(inbox_id, comment_id)` is the actual dedup mechanism: if the same comment is processed twice (webhook retry), `ActiveRecord::RecordNotUnique` is caught and the duplicate is silently dropped, logged as `event=duplicate_comment`.
5. `CommentAutomation::PublicReplyJob` posts one of the trigger's `public_replies` (array — presumably rotated/randomized for variety) as a public comment reply.
6. Once the public reply succeeds, `CommentAutomation::DmDispatchJob` sends the trigger's `dm_text_body` as a direct message to the commenter.
7. **Rate limiting:** `CommentAutomation::RateLimiter` caps DM sends to 10/second per inbox using short-lived Redis keys (`ex: 1`) as a sliding counter. If Redis itself errors, the limiter **fails closed** (blocks sending) rather than risking a ban from over-sending — an explicit `ponytail:` comment in the code flags this as a deliberate simplification to revisit if legitimate sends get delayed by transient Redis blips.
8. If the rate limit is hit, the job requeues itself (up to `MAX_RATE_LIMIT_ATTEMPTS = 30`, ~30s of tolerance) rather than dropping the send.
9. Network errors talking to Instagram's API (timeouts, connection refused, SSL errors — an explicit whitelist) mark the log as failed with the error message rather than raising unhandled.
10. **Mock mode:** `CommentAutomation.mock_channel?(inbox.channel)` — for inboxes without a real Instagram connection, jobs run synchronously (`perform_now`) against fake data instead of hitting Instagram's real API, via `MockAutoresponderStore`, `PostMockCommentService`, `ConnectMockChannelService` (same "build/demo without waiting on platform approval" pattern as [15-reputation-management.md](15-reputation-management.md)'s `Reputation::Providers` mock mode).

### Campaign/trigger authoring
11. A `Campaign` targets one `inbox` + one `post_id`, can be toggled `is_active`.
12. Each campaign has one or more `Trigger`s: `keyword`, `match_type` (exact/contains), an array of `public_replies` (varied response copy), and one `dm_text_body`. Triggers can be built from a saved `Template` (`template_id`) — reusable keyword/reply/DM combos, with a `favorite` flag for quick access.

### Settings/management layer (mock-backed today)
13. `SocialAccountsController` and `ResponseControlsController` (per-post-type response toggles, defaults, team/member assignment) are **entirely backed by `CommentAutomation::MockAutoresponderStore`** — there's no real `comment_automation_social_accounts` or `comment_automation_response_controls` DB table. This is account-scoped in-memory/cache-backed mock data (per `MockAutoresponderStore`), not a stub returning static JSON, but it is not the real per-platform account/team-assignment system yet.
14. `MockConnectionsController`/`MockCommentsController` exist specifically to let a user simulate the whole flow (fake IG connection, fake incoming comment) for demo/testing without a real Instagram Business account.

---

## 3. Data model

**Real, persisted tables:**
```
comment_automation_campaigns
  - account_id, inbox_id: bigint, not null
  - name: string, not null
  - post_id: string, not null      # target Instagram post
  - is_active: boolean, default true

comment_automation_triggers
  - campaign_id, account_id: bigint, not null
  - keyword: string
  - match_type: integer, default 0    # exact / contains
  - public_replies: text[], default []
  - dm_text_body: text, not null
  - template_id: bigint (optional)

comment_automation_templates
  - account_id: bigint, not null
  - name: string, not null
  - template_type: integer, default 0
  - public_replies: text[], default []
  - dm_text_body: text
  - favorite: boolean, default false

comment_automation_message_logs
  - trigger_id, account_id, inbox_id: bigint, not null
  - contact_id: bigint (optional)
  - comment_id, commenter_id: string, not null
  - status: integer, default 0   # matched → public_replied → sent / failed
  - sent_at: datetime
  - unique index on (inbox_id, comment_id) — the dedup mechanism
```

**Not backed by a table (mock store only):** social accounts, response controls (per-post-type defaults/overrides), team/member assignment for comment automation — currently served from `CommentAutomation::MockAutoresponderStore`, which is account-scoped but not a real persistence layer for this data.

---

## 4. Backend / API

**Routes** (`/api/v1/accounts/:account_id/comment_automation/*`):
| Resource | Notes |
|---|---|
| `campaigns` | full CRUD |
| `templates` | full CRUD |
| `message_logs` | `index` (read-only activity log) |
| `social_accounts` | mock-store backed (see §2 note 13) |
| `response_controls` | mock-store backed |
| `settings` | account-level config |
| `mock_connections`, `mock_comments` | demo/testing simulation endpoints |

**Real pipeline:** `app/jobs/comment_automation/{inbound_comment_job, public_reply_job, dm_dispatch_job}.rb`, `app/services/comment_automation/{match_engine, rate_limiter}.rb`.

**Mock pipeline:** `app/services/comment_automation/{mock_autoresponder_store, post_mock_comment_service, connect_mock_channel_service}.rb`.

**Inbound trigger:** `POST /webhooks/instagram` (shared Instagram channel webhook, see [05-channels.md](05-channels.md)) — comment-type changes route into `InboundCommentJob`.

---

## 5. Frontend

**Vue:** campaign/trigger builder and message-log activity view under `dashboard/routes/dashboard/comment-automation/` (or similar); response-controls settings page (currently rendering mock-store data).

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/comment_automation/{trigger,campaign,message_log}_spec.rb` | model validations |
| `spec/jobs/comment_automation/{dm_dispatch_job,public_reply_job,inbound_comment_job}_spec.rb` | full pipeline, per-job |
| `spec/services/comment_automation/{rate_limiter,connect_mock_channel_service,post_mock_comment_service,mock_autoresponder_store,match_engine}_spec.rb` | rate limiting, mock flow, keyword matching |
| `spec/factories/comment_automation/{trigger,campaign,message_log}.rb` | test data |

**Coverage gaps observed:** none significant for the real pipeline (matching, dedup, rate limiting, DM dispatch are all directly tested) — this module is well covered for its size, on par with Automation Rules/Campaigns.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, Sidekiq (3 jobs), Redis (rate-limit counter via `Redis::Alfred`), Instagram Graph API (real mode), HTTParty (per `NETWORK_ERRORS` list)
- Mock mode: no external dependency, in-memory/cache-backed fake data

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Same comment webhook delivered twice | Second insert hits unique `(inbox_id, comment_id)` index, caught and logged as duplicate, no double-send |
| Business's own account comments on its own post | Excluded via `self_comment?` check in `MatchEngine` |
| Rate limit exceeded | Job requeues itself, up to 30 attempts (~30s), rather than dropping the DM |
| Redis unavailable when checking rate limit | Fails closed — blocks the send rather than risking an Instagram ban from unthrottled sending (explicitly flagged as a deliberate tradeoff in code) |
| Instagram API network error on DM send | Caught via explicit error whitelist, log marked failed with the error message, not an unhandled exception |
| No trigger keyword matches the comment | No log created, no reply sent — silent no-op |

---

## 9. Price / plan gating

**Gating type:** Not in the plan matrix. No `feature_key` in `config/features.yml` or `PlanFeatureLimit`.
**`feature_key`(s):** none

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | not gated | — | availability is code/channel presence, not a plan row |
| Standard | not gated | — | |
| Business | not gated | — | |
| Enterprise | not gated | — | |

**Credits / usage:** none
**Enforced by:** Instagram channel + campaign records, not `ReconcilePlanFeaturesService`
**Source:** `lib/seeders/plan_feature_limit_seeder.rb` — no matching key. Do not invent a SKU.

---

## 10. Open gaps / notes

- **Social account management and response controls are not yet backed by real data** — they run entirely on `MockAutoresponderStore`. This is fine for demo purposes but means the "assign team/member to a social account" and "per-post-type response defaults" features don't actually persist against real Instagram Business accounts today. Flag before promising this as a production-ready settings surface.
- Core matching/DM pipeline, by contrast, is fully real and well-tested — safe to treat as production-ready for genuine Instagram channels.
- TikTok is mentioned in the broader routing/model surface (see [05-channels.md](05-channels.md) `channel_tiktok`) but this FRD's evidence (webhook wiring, `InboundCommentJob`) only confirms the pipeline for Instagram — TikTok comment automation support not verified in this pass.
