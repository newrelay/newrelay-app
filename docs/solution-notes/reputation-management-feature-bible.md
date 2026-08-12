# 📖 FEATURE BIBLE: Reputation Management (Google Business Profile)

**Status:** In Progress
**Owner:** Chandresh
**Last updated:** July 14, 2026
**Related module:** Newrelay — Reputation Management (GoHighLevel-style)

---

## 1. WHAT — Feature Summary

**One-liner:** Business owners connect their Google Business Profile to Newrelay and manage/reply to all their Google reviews from one dashboard.

**Elevator pitch:** Newrelay users often manage multiple client businesses. Instead of logging into each client's separate Google account to check reviews, this feature pulls all reviews into Newrelay, lets users reply directly, and tracks reputation metrics — same as GoHighLevel's reputation module.

---

## 2. WHY — Problem & Justification

**Problem statement:** Agencies/businesses managing multiple locations have to log into each Google Business Profile separately to see and reply to reviews — no centralized view, no bulk reply, no alerting.

**Who needs this:** Agency admins managing multiple client GBP accounts; single business owners who want review alerts.

**What happens without it:** Manual login per business, missed reviews, no response-time tracking, feature parity gap vs GoHighLevel.

**Business value:** Core differentiator matching GoHighLevel; retention driver for agency-tier subscribers.

---

## 3. USER STORIES

- As an **agency admin**, I want to **connect multiple client GBP accounts**, so that **I can manage all reviews from one dashboard**.
- As a **business owner**, I want to **get notified of new reviews**, so that **I can respond quickly**.
- As a **user**, I want to **reply to a review from Newrelay**, so that **I don't need to log into Google separately**.

---

## 4. SCOPE

### ✅ In Scope
- Google OAuth connection per business location with manual location selection
- Review sync (pull reviews from GBP API)
- Reply to reviews from within Newrelay
- Background sync job (periodic, every 30 mins)
- AI-generated reply drafts
- Public review widgets for website embedding
- Video testimonials (recording and collecting)

### ❌ Out of Scope (explicitly excluded)
- Multi-platform (Yelp/FB) reviews (Facebook is marked "Coming Soon" in UI)

### 🔮 Future / Phase 2
- Sentiment analysis

---

## 5. HOW IT ACTIVATES — Trigger & Lifecycle

**Activation trigger:** User clicks "Connect Google Business Profile" → OAuth consent flow.

**Preconditions:** *[Which plan tier gets this? Any location limit?]*

**Lifecycle states:**
| State | Meaning | Next state trigger |
|---|---|---|
| `pending` | OAuth initiated, not yet confirmed | Google callback success |
| `active` | Connected, syncing normally | — |
| `error` | Token expired / revoked / API failure | Re-auth or auto-retry |
| `disabled` | User manually disconnected | User reconnects |

**Deactivation/rollback:** *[Does disconnecting delete synced review history, or just stop new syncs?]*

---

## 6. EXTERNAL DEPENDENCIES & LEAD TIME

> ⚠️ Critical: coding takes hours, but Google's approval can take days/weeks. Start this in parallel with dev, not after.

| Dependency | Needed for | Who applies | Approval/setup time | Status | Blocker risk |
|---|---|---|---|---|---|
| Google Cloud Project + OAuth consent screen | Base OAuth flow | Chandresh | Same day (self-serve) | *[fill status]* | Low |
| GBP API access (Business Profile API) | Read/reply to reviews | Chandresh | Google manually reviews access requests — **historically 1-2 weeks, sometimes longer** | *[fill status]* | **High — this is the real bottleneck** |
| OAuth app verification (if requesting sensitive scopes) | Production use beyond test users | Chandresh | Can take **weeks**, needs privacy policy, demo video, security assessment for certain scopes | *[fill status]* | High |
| Domain/brand verification | App trust/consent screen | Chandresh | Few days | *[fill status]* | Medium |

**Action item:** Apply for GBP API access and start OAuth verification **on Day 1**, before writing any sync/reply code. Build the OAuth connection + DB schema while waiting.

**Fallback plan if approval delayed:** Use Google's "test users" mode (limited to ~100 pre-added test accounts) to build and demo the feature internally while production approval is pending. Don't block dev work on approval status.

---

## 7. DATA MODEL

**Core Tables:**
1. `reputation_integrations`: Stores OAuth tokens, provider (`google`), and `location_id`.
2. `reputation_reviews`: Caches synced reviews from external providers.
3. `reputation_review_replies`: Stores drafted or published replies to reviews.
4. `reputation_templates`: Stores standard and video review invite templates (subject, body, channel).
5. `reputation_review_requests`: Logs review invites sent to contacts (tracks sent, clicked, completed status).
6. `reputation_widgets`: Configurations for embeddable website widgets (min rating, style, watermark).

**Migration notes:** None required.

---

## 8. BACKEND / API

**Endpoints:**
| Method | Route | Purpose | Auth |
|---|---|---|---|
| GET | /gbp/oauth/callback | Handle Google OAuth redirect | User session |
| GET | /reviews | List synced reviews | User session |
| POST | /reviews/:id/reply | Post reply to Google | User session |

**Background jobs:** Sidekiq job for periodic review sync — *[what's the sync frequency? every 15 min? hourly?]*

**External integration:** Google Business Profile API — *[rate limits confirmed? quota per project?]*

**Existing pattern to follow:** Match existing Sidekiq job structure already used in your codebase.

---

## 9. FRONTEND / UI

**Screens touched:** Reputation dashboard, review list/thread view, connection settings page.

**States to handle:** empty (no reviews yet), loading (syncing), error (auth expired — needs reconnect banner), success.

**Design reference:** *[GoHighLevel UI as reference, or Chatwoot's existing Vue component style?]*

---

## 10. FLOW — Step by Step

1. User clicks "Connect GBP" → redirected to Google OAuth consent
2. Google redirects back with auth code → Newrelay caches session in Redis (`$alfred`)
3. User selects the specific business location from a modal (`google_locations` endpoint)
4. Newrelay finalizes the integration and stores the permanent tokens and `location_id`
5. Sidekiq job (`Reputation::ReviewSyncJob`) pulls reviews periodically via GBP API
6. Reviews appear in dashboard, sorted by date/rating
7. User can generate an AI draft, or write a manual reply
8. User clicks publish → `Reputation::ReplyPublisherJob` posts reply via GBP API

**Acceptance criteria:**
- [x] Given a valid Google account, when user completes OAuth, they can select a specific location
- [x] Given a selected location, the connection status shows `active`
- [x] Given an active connection, when sync job runs, new reviews appear automatically
- [x] Given a review, user can generate an AI draft reply
- [ ] Given a review, when user submits a reply, it appears on the actual Google listing

---

## 11. EDGE CASES & FAILURE MODES

| Scenario | Expected behavior |
|---|---|
| OAuth token expires | Show reconnect banner, pause sync, alert user |
| GBP API rate limit hit | Backoff + retry, log warning |
| User has multiple locations under one Google account | *[Need clarity — auto-detect all locations or manual select?]* |
| Reply fails to post (Google-side error) | Show error, allow retry, don't lose draft |
| User disconnects mid-sync | Job should gracefully stop, no orphaned data |

---

## 12. NON-FUNCTIONAL REQUIREMENTS

- **Performance:** *[target sync time per business?]*
- **Security:** OAuth tokens must be encrypted at rest.
- **Scalability:** *[how many businesses/locations expected at launch — 50? 500?]*
- **Logging:** Sync failures and reply failures must be traceable per business.

---

## 13. AI IMPLEMENTATION INSTRUCTIONS

**Tech stack constraints:** Rails + Vue (Chatwoot base) + Sidekiq for background jobs.

**Files likely to touch:** *[fill with actual paths once you have them, e.g., app/models/gbp_connection.rb, app/jobs/gbp_review_sync_job.rb]*

**Step-by-step build order:**
1. OAuth connection model + controller
2. Token storage + refresh logic
3. Sidekiq sync job (reviews pull)
4. Reply endpoint + Google API post
5. Frontend dashboard + reply UI

**Do NOT:** Don't create a separate auth system — reuse existing OAuth/session pattern already in the codebase.

**Test expectations:** *[unit tests for token refresh, integration test for full OAuth→sync→reply flow]*

---

## 14. ROLLOUT PLAN

- **Feature flag:** *[yes/no — recommended yes given external API dependency]*
- **Rollout order:** *[internal test business → beta agency clients → all]*
- **Success metric:** *[e.g., "X% of connected businesses get at least 1 reply sent within first week"]*

---

## 15. RESOLVED QUESTIONS & DECISIONS

- **Tables:** We have defined 6 core tables (`reputation_integrations`, `reputation_reviews`, `reputation_review_replies`, `reputation_templates`, `reputation_review_requests`, `reputation_widgets`).
- **Sync frequency:** Periodic via `sidekiq-cron` (typically 30/60 min).
- **Multiple locations:** Manual selection via a modal during the OAuth flow.
- **AI-assisted reply:** Yes, `Reputation::AiDraftService` is implemented.
- **Video Testimonials:** Yes, dedicated templates and public recording interface built.

## PENDING QUESTIONS
- [ ] Which plan tier(s) get access to this feature?
- [ ] Expected scale at launch (number of businesses/locations)?
