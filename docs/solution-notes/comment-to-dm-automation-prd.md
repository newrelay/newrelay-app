# Comment-to-DM Automation — Implementation Plan

**Status:** Reviewed & ready to build (CEO review complete, 2026-09-01)
**Supersedes:** [`openreply-automation-prd.md`](openreply-automation-prd.md) — that proposal wired this into `AutomationRule`; this document and the codebase audit below confirm that was the wrong call (see §1).
**Source references:** `Chatwoot_Execution_Plan_Structured.pdf` + `commenttodmmaster.md` (external planning docs) — reconciled against this repo's actual code as of commit `537fbccf` on `feature/ui-changes`.
**Scope decision trail:** `~/.gstack/projects/auzadev-DakshAI/ceo-plans/2026-09-01-comment-to-dm-automation.md`

This is the single doc to build from. Follow it in phase order. Where it disagrees with the original external planning docs, this doc wins — the differences are corrections found by reading the actual codebase, not opinion.

---

## 1. What this is, and why native (not `AutomationRule`)

A commenter posts a keyword on an Instagram (later TikTok) post. We publicly reply, then DM them privately with a tracked link. Only when they engage with that DM — reply or click a button — does a real Chatwoot contact/conversation get created. Cold commenters never touch the support inbox.

Two prior proposals exist in this repo's history:
- `openreply-automation-prd.md` (superseded) — proposed extending `AutomationRule` with `send_dm`/`reply_to_comment` actions.
- `commenttodmmaster.md` (external, this session's input) — proposed an isolated `CommentAutomation::` module.

**Verified via codebase audit:** `AutomationRule` (`app/models/automation_rule.rb:35-42`) has zero comment or lead-attribution concepts today, and is enterprise-audited (`enterprise/app/models/enterprise/audit/automation_rule.rb`). Extending it is the *more* invasive path, not the incremental one it looks like on paper — every account's automation UI would gain fields it doesn't need, and the audit log would need updating too. **Decision: isolated `CommentAutomation::` module, confirmed.**

---

## 2. Codebase reality-check (read this before writing code)

Corrections to what the external reference docs assumed:

| Reference doc assumed | Actual state | Impact |
|---|---|---|
| Instagram webhook already routes some comment-ish traffic; this is an "extend" | `Webhooks::InstagramEventsJob::SUPPORTED_EVENTS = [:message, :read]` ([instagram_events_job.rb:14](../../app/jobs/webhooks/instagram_events_job.rb)) — **no comment event handling exists at all**. `Channel::Instagram` subscribes only to `%w[messages message_reactions messaging_seen]` ([channel/instagram.rb:50](../../app/models/channel/instagram.rb)) — no `comments` field, no `instagram_manage_comments` scope anywhere in the repo. | This is greenfield work: new webhook subscription field, new event branch, new normalization path. Size Phase 1 accordingly — do not treat it as a small delta. |
| TikTok is a stub needing 80hrs in a gated fast-follow phase | `channel/tiktok.rb` is a full model with OAuth (`app/controllers/tiktok/callbacks_controller.rb`), webhook HMAC verification (`app/controllers/webhooks/tiktok_controller.rb`), and a working outbound send service (`Tiktok::SendOnTiktokService`). Only DM events are handled today (`Webhooks::TiktokEventsJob::SUPPORTED_EVENTS = [:im_send_msg, :im_receive_msg, :im_mark_read_msg]`) — comment ingestion is missing, same gap as Instagram. | **Scope decision (accepted):** build TikTok comment-webhook intake in the same phases as Instagram, not a separate 80hr phase. Reuse `Tiktok::SendOnTiktokService` for DM dispatch — it already works. The only real TikTok-specific blocker is their partner-approval timeline, which is external and unaffected by this decision. |
| `MetaTokenVerifyConcern` is a shared Meta-webhook verifier TikTok can reuse | It's used by exactly two controllers: `webhooks/instagram_controller.rb` and `webhooks/whatsapp_controller.rb`. TikTok's webhook (`webhooks/tiktok_controller.rb:24-40`) already does its own independent HMAC-SHA256 verification. | Instagram's comment webhook reuses `MetaTokenVerifyConcern` as planned. TikTok's comment webhook reuses TikTok's own existing verification method — don't force it onto the Meta concern. |
| New encrypted token storage needed for the automation module | Campaigns only ever reference `inbox_id`. Both `Channel::Instagram` and `Channel::Tiktok` already store `access_token` via Rails' native `encrypts` (gated behind `Chatwoot.encryption_configured?`). | **Scope decision (accepted): cut.** No new credential storage of any kind — campaigns/triggers never hold a secret. |
| "Up to 3 interactive buttons" on Instagram DMs is a small addition | `Instagram::BaseSendService` (`app/services/instagram/base_send_service.rb`) only builds `text` and `attachment` message payloads today — no quick-reply/button/generic-template support exists. | Real net-new work in Phase 3, not a checkbox. Build it as an extension to `Instagram::BaseSendService`, following its existing `message_params` → `send_message` → `process_response` shape (including its `external_error` / `channel.authorization_error!` handling for expired tokens). |
| Rate limiting / throttle needs a new mechanism | `AutoAssignment::RateLimiter` (`app/services/auto_assignment/rate_limiter.rb`) is an existing Redis-backed sliding-window limiter using `Redis::Alfred` key counting. | Reuse the same pattern for the ~10 msg/sec outbound throttle instead of inventing a new leaky-bucket implementation. |
| No existing short-link precedent | Confirmed — grepped the whole repo, nothing. | This module owns `comment_automation_short_links` outright. **Scope decision (deferred to TODOS.md):** don't generalize it into shared infra yet — no second consumer exists. |
| No stated data retention plan | N/A (not addressed in reference docs) | **Scope decision (accepted): add a Phase 5 cleanup job.** `comment_automation_message_logs` will accumulate one row per matched comment including cold, non-consenting commenters. Purge `pending`/`public_replied` rows with no `contact_id` after 90 days. |

---

## 3. Architecture

**Eng review finding (confirmed):** dedup must happen *before* any external API call, not after — a webhook retry racing a slow first attempt must not be able to send two public replies. `InboundCommentJob`'s first action is `INSERT message_logs (status: pending)` inside the `(inbox_id, comment_id)` unique constraint; only on successful insert does it enqueue `PublicReplyJob`/`DmDispatchJob`. A retried webhook fails the INSERT immediately, before any Instagram/TikTok API call is attempted — not after.

```
                     ┌─────────────────────────────────────────────────────┐
                     │              CommentAutomation:: (new)               │
                     │                                                      │
  IG comment  ──────▶│  Webhooks::Instagram                                 │
  webhook            │  Controller (extend)                                │
  (MetaTokenVerify   │        │                                            │
   Concern, existing)│        ▼                                            │
                     │  CommentAutomation::InboundCommentJob (new)          │
                     │   1. INSERT message_logs(status: pending) —          │
                     │      unique(inbox_id, comment_id) gates HERE,        │
                     │      before any send is attempted                    │
  TikTok comment ───▶│  Webhooks::TiktokController (extend, own HMAC)       │
  webhook            │        │                                            │
                     │        ▼                                            │
                     │  CommentAutomation::MatchEngine                     │
                     │   - keyword lookup (Trigger, scoped to Campaign)     │
                     │   - self-comment exclusion                          │
                     │   - dedup: unique (inbox_id, comment_id)             │
                     │        │                                            │
                     │        ▼                                            │
                     │  CommentAutomation::PublicReplyJob (rotating text,   │
                     │   3-12s jitter)                                     │
                     │        │                                            │
                     │        ▼                                            │
                     │  CommentAutomation::DmDispatchJob                    │
                     │   - reuses Instagram::SendOnInstagramService /       │
                     │     Tiktok::SendOnTiktokService                      │
                     │   - throttled via AutoAssignment::RateLimiter        │
                     │     pattern (Redis::Alfred)                          │
                     │        │                                            │
                     │        ▼                                            │
                     │  MessageLog (status: pending → public_replied →      │
                     │   dm_sent → engaged, or dm_failed)                   │
                     └───────────────────┬──────────────────────────────────┘
                                          │  on real DM reply/click
                                          ▼
                     ┌─────────────────────────────────────────────────────┐
                     │        EXISTING Chatwoot pipeline (untouched)        │
                     │  Instagram::WebhooksBaseService#find_or_create_contact│
                     │  → ContactInboxWithContactBuilder                    │
                     │  → CommentAutomation attaches campaign attribution    │
                     │    onto contact.custom_attributes here (same merge   │
                     │    pattern WebhooksBaseService already uses for      │
                     │    additional_attributes)                            │
                     └─────────────────────────────────────────────────────┘
```

### Data flow — shadow paths (inbound comment webhook)

```
INPUT (webhook payload) ──▶ HMAC VERIFY ──▶ NORMALIZE ──▶ MATCH ──▶ DISPATCH ──▶ LOG
      │                          │               │            │          │         │
      ▼                          ▼               ▼            ▼          ▼         ▼
  [nil/empty body]        [bad signature]   [missing       [no trigger  [Send API [dup
   → 400, no ACK            → 401, log,       comment_id]    matches]    timeout/  comment_id]
                             no processing     → 422, log     → no-op,    429]      → unique
  [malformed JSON]                             skip           log         → retry   index
   → 400, log                                  [wrong         match       2x, then  rejects,
                                                 event type]   attempt     dm_failed, no dup DM
                                                 → ignore                 alert
                                                 silently
                                                 (documented,
                                                 not a bug)
```

State machine — `comment_automation_message_logs.status`:

```
  pending ──▶ public_replied ──▶ dm_sent ──┬──▶ engaged   (terminal: contact_id set,
                  │                        │               attribution patched)
                  │                        └──▶ dm_failed  (terminal: retried 2x, alerted)
                  └──▶ dm_failed (public reply itself failed — no DM attempted)

  Invalid transitions blocked by: status is DB enum + only written by
  CommentAutomation::MatchEngine / PublicReplyJob / DmDispatchJob, one writer each.
```

---

## 4. Database schema

Same four tables as the reference doc's migration (`comment_automation_campaigns`, `_triggers`, `_message_logs`, `_short_links`), **with the "encrypted token storage" future-work line struck** (§2 above — never needed) and the retention job added in Phase 5. Reuse the migration exactly as specified in `commenttodmmaster.md` §6 — it was reviewed and is sound: `account_id` on every table (matches `deals`/`pipelines` pattern), unique index on `(inbox_id, comment_id)` for dedup, FK chain `campaign → trigger → message_log → short_link`.

Two additions not in the original migration, both found in eng review:

1. An index to support the Phase 5 retention job's query (`status IN (pending, public_replied) AND contact_id IS NULL AND created_at < ?`):

```ruby
add_index :comment_automation_message_logs, [:status, :contact_id, :created_at]
```

2. **An index on `post_id`.** `comment_automation_campaigns` is looked up by `post_id` on *every single inbound webhook event* — the highest-traffic path in this entire module — but had no index for it at all:

```ruby
add_index :comment_automation_campaigns, [:account_id, :post_id]
```

Without this, every comment on either platform forces a full table scan across all campaigns to find a match. Cheap to add now in the Phase 1 migration; expensive to add later once the table has production rows (index-build lock risk).

---

## 5. Error & rescue map

| Codepath | What can go wrong | Exception / condition | Rescued? | Rescue action | User/operator sees |
|---|---|---|---|---|---|
| Webhook HMAC verify | Bad/missing signature | handled by `MetaTokenVerifyConcern` (IG) / TikTok's own verifier | Y | 401, no processing | Nothing (attacker gets opaque 401) |
| Comment normalization | Malformed payload, missing `comment_id` | `ActionController::ParameterMissing` / custom | Y — must add | 422, `[comment_automation] event=malformed_payload` log | Nothing (Meta/TikTok retries or drops) |
| Dedup | Retried webhook, same `comment_id` | `ActiveRecord::RecordNotUnique` on `(inbox_id, comment_id)` | Y — must add | Swallow silently (expected on Meta retry), log at debug | Nothing |
| Keyword match | No trigger matches | n/a (normal path) | — | No-op | Nothing |
| Public reply send | IG/TikTok API timeout | `Net::ReadTimeout` / `HTTParty::Error` | Y | Retry 2x w/ backoff via Sidekiq `retry_on`, then mark `dm_failed` | Alert (see §7) |
| Public reply send | Rate limited (429) | API error code | Y | Backoff + retry, respect `Retry-After` | Nothing (transparent) |
| Public reply send | Token expired | error code 190 (IG) | Y | `channel.authorization_error!` — **reuse existing `Instagram::BaseSendService#external_error` behavior**, don't reinvent | Inbox shows re-auth banner (existing Chatwoot UX) |
| DM dispatch | Same as above | same | Y | Same | Same |
| DM dispatch | Recipient blocked DMs / opted out | API error (platform-specific) | Y — must add | Mark `dm_failed`, no retry (permanent) | Nothing (log only) |
| Short-link redirect | Unknown `code` | `ActiveRecord::RecordNotFound` | Y — must add | 404 branded page (not raw Rails error) | Broken-link page |
| Short-link redirect | `destination_url` fails open-redirect validation | custom validation | Y — must add | Reject at write time (trigger/campaign save), not at redirect time | N/A — caught before it can fire |
| Retention cleanup job | DB timeout mid-purge | `ActiveRecord::StatementTimeout` | Y — must add | `retry_on`, cap batch size (e.g. 1000/run) | Nothing (job retries next run) |

No `rescue StandardError` / catch-alls anywhere in this list — every rescue above names its exception class. Rows marked "must add" are net-new and are the actual Phase 2/3 deliverable, not boilerplate.

---

## 6. Security & threat model

| Threat | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Forged webhook (no valid signature) | Med | High (fake DMs sent on your behalf, quota burn) | HMAC verification is mandatory and blocking, both platforms — already required by the reference doc, confirmed non-negotiable |
| Open redirect via short-link `destination_url` | Med | Med (phishing via your trusted domain) | Validate `destination_url` against an allowlist pattern at write time (campaign/trigger save), not at redirect time — reject `javascript:`, non-http(s) schemes, and disallow arbitrary external hosts unless explicitly allowed per account |
| Comment/DM content injection (stored XSS via keyword or reply text) | Low (internal-authored content, not end-user input in v1 — no admin UI) | Low in v1, rises once Phase 7 admin UI ships | Standard Rails output escaping on any future UI render; sanitize `dm_text_body`/`public_replies` on write regardless |
| IDOR on short-link `/l/:code` | Low | Low (codes are opaque, not sequential) | Use a random, non-guessable `code` (e.g. 8+ char base62), not an auto-increment id |
| Retry-storm from a webhook loop | Low | Med (quota exhaustion, duplicate DMs) | DB-level unique index on `(inbox_id, comment_id)` is the real gate — dedup happens before any send, not after |
| Over-privileged automation token | Med (if using an existing admin token) | High (blast radius = full account) | **Confirmed in reference doc §15, adopt as specified:** provision a dedicated low-privilege agent account for any API-driven campaign management, not a full admin token |

---

## 7. Observability

- **Logging convention (scope decision, accepted):** every codepath in this module logs with the bracket-tag prefix already used elsewhere in this repo (`[reputation.isolation] reason=... request_id=...` precedent) — use `[comment_automation] event=<name> campaign_id=<id> trigger_id=<id> comment_id=<id> request_id=<id>`. Never log the raw comment body or DM content at info level (PII); log lengths/hashes if content-shape debugging is needed.
- **Metrics:** matched-comment rate, public-reply success rate, DM-dispatch success rate, engagement rate (dm_sent → engaged), short-link click rate. One dashboard panel per stage of the funnel — the funnel *is* the health check.
- **Alerting:** alert on `dm_failed` rate exceeding a threshold (token expiry, platform-side block) and on webhook signature-verification failure rate (possible attack or misconfigured secret).
- **Runbook:** token-expiry alert → re-auth via existing Chatwoot channel re-connect flow (already built for `Channel::Instagram`/`Channel::Tiktok`). Webhook-verification-failure spike → check `app_secret` rotation didn't desync from Meta/TikTok app config.
- **Retention job (scope decision, accepted):** Sidekiq scheduled job, Phase 5, purges non-engaged `message_logs` rows older than 90 days (query backed by the added index in §4). Logged with the same `[comment_automation]` tag, one summary line per run (`event=retention_purge rows=N`).

---

## 8. Rollout & rollback

- **Feature flag:** add `comment_automation` to `config/features.yml` (matches the existing `reputation_demo_surfaces`/`advanced_assignment` entries) — per-account enablement via Super Admin, not a global switch. Matches the reference doc's "feature-flagged rollout" requirement using an existing mechanism instead of inventing one.
- **Migration safety:** four new tables, zero changes to existing tables — additive, zero-downtime, no lock risk.
- **Deploy order:** migrate → deploy code (webhook branches are no-ops until a campaign exists for that `post_id`) → enable flag per account.
- **Rollback:** disable the feature flag (immediate, no deploy needed) → if needed, code rollback is a standard revert (no other module depends on these tables) → migrations are additive so no down-migration is required for a code-only rollback.
- **Smoke test post-deploy:** seed one test campaign/trigger via console (`Seeders`-style, per reference doc's "no admin UI, seed-script driven" decision for v1), post a matching test comment on a real sandbox IG post, confirm public reply + DM land, confirm short-link redirects and increments `clicks_count`.

---

## 9. Test plan

| New codepath | Test type | Happy path | Failure path | Edge case |
|---|---|---|---|---|
| Webhook HMAC verify (IG comment) | Request spec | Valid signature → 200, job enqueued | Invalid signature → 401 | Missing header → 401 |
| Comment normalization | Unit | Well-formed payload → normalized struct | Malformed JSON → 400, logged | Empty body → 400 |
| `CommentAutomation::MatchEngine` | Unit | Exact/contains keyword matches trigger | No match → no-op | Self-comment (commenter = page) excluded; case sensitivity; duplicate `comment_id` → dedup rejects |
| Public reply rotation | Unit | Rotates through `public_replies`, no immediate repeat | — | Single-reply array (no rotation possible) doesn't crash |
| DM dispatch (IG) | Unit + integration (stubbed API) | Sends via `Instagram::SendOnInstagramService` extension, buttons render | API timeout → retried, then `dm_failed` | Token expired (code 190) → `authorization_error!` fires |
| DM dispatch (TikTok) | Unit + integration (stubbed API) | Sends via existing `Tiktok::SendOnTiktokService` | Same | Same |
| Rate limiter | Unit | Under limit → sends | At limit → queues/delays | Redis unavailable → **fail closed (decided in eng review)**: delay/retry rather than burst-send past platform limits — write a test asserting a `Redis::BaseError` on `current_count` results in the job re-enqueuing, not an immediate send |
| Dedup ordering | Integration | Single webhook → one message_log row, one send | **Regression-class test:** replay the same webhook payload concurrently (2+ threads/jobs) → exactly one `message_logs` INSERT succeeds, the other raises `ActiveRecord::RecordNotUnique` and is swallowed *before* either thread calls the Send API — assert the external API client received exactly one call, not two | Retry arrives after the first attempt already completed (`status: dm_sent`) → INSERT still fails on uniqueness, no new send attempted |
| Attribution handoff | Integration | Real DM reply → contact created → `custom_attributes` patched with campaign id | Contact creation race (two webhooks same commenter) → attribution applies once, idempotent | — |
| Short-link redirect | Request spec | Valid code → 302 + click counted | Unknown code → 404 branded page | Malformed/expired code |
| Retention cleanup job | Unit | Purges eligible rows | DB timeout → retries | Zero eligible rows → no-op, still logs a run line |

Chaos/2am-confidence test: replay the same webhook payload 50x concurrently — exactly one `message_log` row and one DM should result (proves the unique index is the real gate, not app-level locking).

---

## 10. Phase plan (revised)

Same 5 core phases as the reference doc, TikTok folded in rather than deferred:

| Phase | Scope | Notes vs. original doc |
|---|---|---|
| 1 — Foundations | Schema (§4), `CommentAutomation::` models, **both** Instagram and TikTok comment-webhook intake (extend `webhooks/instagram_controller.rb` + `webhooks/tiktok_controller.rb`) | Original doc scoped Phase 1 to Instagram only; TikTok's webhook already has HMAC handling, so adding its comment branch here is incremental, not a new phase |
| 2 — Keyword Engine & Anti-Spam | Match engine, self-comment exclusion, rotating replies, `AutoAssignment::RateLimiter`-pattern throttle | Reuse existing rate-limiter shape (§2), don't build new |
| 3 — DM Dispatch & Link Tracking | Extend `Instagram::BaseSendService` for buttons (net-new, §2); reuse `Tiktok::SendOnTiktokService` as-is; short-link redirect controller + click counting | Instagram button support is real work here, size it in, don't treat as free |
| 4 — Attribution Handoff & Security Hardening | Patch `custom_attributes` in `Instagram::WebhooksBaseService#find_or_create_contact` (and TikTok's equivalent); dedicated low-priv agent token; open-redirect validation on short-link writes | Unchanged from reference doc, confirmed sound by audit |
| 5 — Observability, Deployment & QA | `[comment_automation]` structured logging, dashboards/alerts (§7), retention cleanup job (new, §7), feature flag via `config/features.yml`, RSpec coverage per §9 | Retention job is new scope vs. the original doc |

TikTok's own Business Messaging partner-approval application should still be filed on day one (external dependency, unaffected by any of the above) — that timeline, not engineering effort, remains the actual TikTok gate.

---

## 11. NOT in scope (this round)

- Campaign admin UI — stays Phase 7 per reference doc, unchanged.
- Generalized/repo-wide short-link service — deferred to `TODOS.md`, no second consumer exists yet to justify it.
- Per-campaign credential storage — cut entirely (§2), campaigns never hold a secret.
- Wildcard keyword matching, A/B testing, scheduled campaigns, Facebook Page comments — unscoped per reference doc, build only if requested later.
- Multi-language matching, sentiment filtering, CRM/e-commerce integrations, broadcast messaging — explicitly out per reference doc's own scope note.

---

## 12. Open questions before Phase 1 starts

One implementation-level decision left to whoever picks up Phase 3, since it doesn't change architecture and is cheap to revisit:

1. **Short-link `code` generation** — recommend reusing whatever random-token generator pattern already exists in the repo for tokens (e.g. the `/r/:token` reputation feature's token generation) rather than adding a new one; confirm the pattern at Phase 3 implementation time.

Resolved in eng review (2026-09-01): rate limiter fail-closed on Redis unavailability (§9), dedup-row-before-send ordering (§3), `post_id` index (§4) — see the review report at the bottom of this doc's companion review log, or the eng review's AskUserQuestion trail in this session.
