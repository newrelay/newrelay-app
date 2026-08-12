# Prompt: Google Business Profile — Fetch Reviews & Reply Feature (Newrelay Reputation Manager)

## Context (paste this as-is to the coding agent)

I'm building **Newrelay**, a Chatwoot (Rails + Vue) based SaaS platform, GoHighLevel-style
architecture. I already have a **Reputation Management module** in progress, and a
**"Connect to Google Business Profile"** OAuth feature already implemented (OAuth 2.0 flow,
tokens stored per account/location).

Now I need to build the **review sync + reply** feature on top of that connection.

## Goal

When a user connects their Google Business Profile location, Newrelay should:
1. Fetch all reviews for that location (and keep fetching new/updated ones on a schedule)
2. Show reviews inside the Reputation Management UI (list, filter by rating/reply status)
3. Let the user reply to a review from Newrelay UI, and push that reply back to Google
4. Reflect Google-side edits/deletions of reviews during sync

## API details (Google Business Profile API v4 — reviews live under Account Management + Business Information APIs)

- List reviews:
  `GET https://mybusiness.googleapis.com/v4/accounts/{accountId}/locations/{locationId}/reviews`
  - Paginated via `pageToken`, page size max 50
  - Each review has: `reviewId`, `reviewer` (displayName, profilePhotoUrl), `starRating`
    (enum: ONE..FIVE), `comment`, `createTime`, `updateTime`, `reviewReply` (if already replied)
- Reply to a review:
  `PUT https://mybusiness.googleapis.com/v4/accounts/{accountId}/locations/{locationId}/reviews/{reviewId}/reply`
  Body: `{ "comment": "reply text" }`
- Delete a reply:
  `DELETE .../reviews/{reviewId}/reply`
- Auth: Bearer token from the already-stored OAuth credentials (refresh if expired)
- Note: there's no webhook/push for reviews by default — Google Business Profile supports
  Pub/Sub notifications for review updates, but that needs a public HTTPS endpoint
  (verified domain) — not usable purely from localhost. For local dev, use polling.

## What I need from you

### 1. Data model (Rails/ActiveRecord, fits Chatwoot's existing schema conventions)
- `GbpReview` model: `account_id` (Newrelay account), `location_id`/`google_location_id`,
  `google_review_id` (unique), `reviewer_name`, `reviewer_photo_url`, `star_rating`,
  `comment`, `google_create_time`, `google_update_time`, `reply_comment`, `replied_at`,
  `synced_at`
- Migration + indexes on `(account_id, google_location_id)` and unique index on `google_review_id`

### 2. Sync service
- `Gbp::ReviewSyncService` — given a connected location, calls the list-reviews endpoint,
  paginates through all results, upserts into `GbpReview`, handles token refresh on 401
- Background job `Gbp::SyncReviewsJob` (ActiveJob/Sidekiq) — runs per location on a schedule
  (e.g. every 30 min via sidekiq-cron) and can also be triggered manually ("Sync now" button)
- Rate-limit awareness: handle 429s with exponential backoff

### 3. Reply service
- `Gbp::ReplyToReviewService` — takes a `GbpReview` + reply text, calls the PUT reply
  endpoint, updates `reply_comment`/`replied_at` locally on success
- Should surface Google API errors cleanly (e.g. review already has a reply conflict,
  token expired, location not found)

### 4. Controllers/API endpoints (Chatwoot-style, under existing account-scoped API namespace)
- `GET /api/v1/accounts/:account_id/gbp_reviews` — list with filters (rating, replied/unreplied, location)
- `POST /api/v1/accounts/:account_id/gbp_reviews/:id/reply` — send a reply
- `POST /api/v1/accounts/:account_id/gbp_locations/:id/sync_reviews` — manual sync trigger

### 5. Frontend (Vue, matching existing Chatwoot dashboard patterns)
- Reviews list view inside Reputation Management module: star rating, reviewer name/photo,
  comment, reply box (inline), "replied"/"pending" badge
- Filter/sort by rating and reply status
- Loading + error states for sync and reply actions

## Constraints
- Follow existing Chatwoot code conventions (service objects under `app/services`, Vuex/Pinia
  store patterns already used in the dashboard, RSpec tests for services and controllers)
- Don't touch the existing OAuth connection code — assume `GbpConnection` (or whatever it's
  named in my codebase) already gives me a valid access token per location; just ask me to
  point you to that model/service if you need its interface
- Write RSpec specs for `ReviewSyncService` and `ReplyToReviewService` with stubbed API responses
- No hardcoded credentials; use the existing OAuth token storage

## Deliverable
Give me the migration, models, services, jobs, controllers, routes, and Vue components,
in that order, so I can review each piece before moving to the next.
