# Reputation Manager — Review API Provider Research

**Date:** 2026-08-20
**Question:** For the NewRelay "Reputation Manager" feature, is **Ayrshare** a good API provider to (1) read Google Business Profile (GBP) reviews and (2) post replies to them programmatically, via a self-serve, real-time REST API that manages Google OAuth for us? Or is there a better alternative?

**One-line recommendation:** **Use Ayrshare** — it is the only established, production-ready provider with a self-serve instant API key, documented REST endpoints for GBP *get reviews* + *reply*, managed Google OAuth (no Google allow-listing needed), and reviews synced roughly every ~10 minutes (not the once-a-day batch that got GMBapi rejected). **Runner-up: ReviewHook** (purpose-built GBP review read/reply REST API, one-click managed OAuth, free during beta — but beta-stage, so unproven for production).

---

## 1. Ayrshare — verdict: **YES, recommended (primary choice)**

### Does it support GBP get-reviews AND reply? Yes.
Ayrshare's Reviews API explicitly covers "reviews on your connected social accounts including Facebook page ratings and Google Business Profile reviews," with three operations: **get, reply, delete**.
Source: <https://www.ayrshare.com/docs/apis/reviews/overview>

**GET reviews (GBP):**
- Endpoint: `GET https://api.ayrshare.com/api/reviews?platform=gmb`
- Auth header: `Authorization: Bearer API_KEY`
- Required param: `platform=gmb` (Google Business Profile)
- Response — per-review fields:
  - `id` — review id
  - `created` — timestamp posted
  - `rating` — star rating as string: `"ONE"`, `"TWO"`, `"THREE"`, `"FOUR"`, `"FIVE"`
  - `review` — review text
  - `reviewer.name` — reviewer name
  - `reviewer.profile` — reviewer profile picture URL
  - `updated` — last-update timestamp
  - `reviewReply` — optional object with the business reply + timestamp
- Response — envelope fields: `averageRating`, `totalReviewCount`, `lastUpdated`, `nextUpdate`.
Source: <https://www.ayrshare.com/docs/apis/reviews/get-reviews>

**POST reply (GBP):**
- Endpoint: `POST https://api.ayrshare.com/api/reviews/reply`
- Required body params: `platform`, `reviewId` (from the get-reviews call), `reply` (the reply message)
Source: <https://www.ayrshare.com/blog/reviews-api-review-management-with-an-api/> and <https://www.ayrshare.com/docs/apis/reviews/overview>

### Real-time or synced? **Periodically synced (~10 min), not real-time reads — but far faster than GMBapi's daily.**
The response's `lastUpdated` / `nextUpdate` fields expose a scheduled-sync model rather than a live poll of Google on every call. In Ayrshare's own example the interval between `lastUpdated` and `nextUpdate` is ~10–11 minutes, i.e. periodic syncing, not live polling.
Source: <https://www.ayrshare.com/blog/reviews-api-review-management-with-an-api/>

> Practical read: a ~10-minute freshness window is acceptable for an interactive inbox, and is an order of magnitude better than **GMBapi's once-a-day** sync that we rejected. Replies are a `POST` relayed onward to Google; note the reply's *public appearance* is then subject to Google's own review-reply moderation queue (a Google-side limitation shared by every provider, including Google's own API — see §2).

### Plan / tier required
- Reviews API is "Available on the Premium, Launch, Business, Enterprise plans." No Max Pack add-on required. So the entry tier that unlocks reviews is **Premium**.
  Source: <https://www.ayrshare.com/docs/apis/reviews/overview>
- Pricing (from official pricing page):
  - **Premium — $149/mo**: 1 social profile, up to 13 accounts. Single user.
  - **Launch — $299/mo**: up to 10 profiles, ~130 accounts, unlimited team members.
  - **Business — $599/mo**: 30 profiles (scales to 300), ~390 accounts — designed for multi-account/multi-client management.
  - **Enterprise — custom**.
  Pricing is not seat-based; multiple connected accounts within one profile count as one billable unit.
  Source: <https://www.ayrshare.com/pricing/>
- **Multi-location / multi-client:** managing many businesses' GBPs requires **User Profiles + Profile Keys**, which are a **Business/Enterprise** feature. You pass the profile via a `Profile-Key: PROFILE_KEY` header (alongside `Authorization: Bearer API_KEY`) to act on behalf of a specific client profile.
  Sources: <https://www.ayrshare.com/docs/multiple-users/manage-user-profiles>, <https://docs.ayrshare.com/multiple-client-accounts/create-manage-multi-account-profiles>

  > So: a single-tenant integration works on **Premium ($149)**; a multi-tenant SaaS where each NewRelay account connects its own GBP needs **Business ($599)** for Profile Keys.

### Manages Google OAuth? Yes — no Google allow-listing needed.
The GBP account is connected through Ayrshare's own linking flow; Ayrshare holds the platform authorization, so we do **not** file Google's Business Profile API access request or wait for allow-listing. (This is the core value vs. Google direct, §2.)
Source: <https://www.ayrshare.com/docs/introduction>

### Self-serve? Yes.
Self-serve signup with the API key available in the dashboard "in seconds"; 28-day free trial, no credit card required.
Sources: <https://app.ayrshare.com/signup>, <https://www.ayrshare.com/pricing/>

### Rate limits / GBP caveats
- Official docs give no published Reviews-API rate-limit number; plans advertise "standard" (Premium) vs "expanded" (Launch/Business) API rate limits — a support/plan question, not a documented figure.
  Source: <https://www.ayrshare.com/pricing/>
- GBP reply publication is gated by Google's own content-moderation queue (see §2) — not an Ayrshare limitation.

---

## 2. Alternatives

### 2a. Direct Google Business Profile API (Google's own) — **runner-up on capability, fails the "no-approval / managed-OAuth" requirement**
- Real-time, first-party, and **free**.
- List reviews: `GET https://mybusiness.googleapis.com/v4/accounts/{accountId}/locations/{locationId}/reviews`
- Reply: `PUT https://mybusiness.googleapis.com/v4/accounts/{accountId}/locations/{locationId}/reviews/{reviewId}/reply` (creates/updates the reply; verified locations only).
  Sources: <https://developers.google.com/my-business/content/review-data>, <https://developers.google.com/my-business/reference/rest/v4/accounts.locations.reviews/updateReply>
- **Requires OAuth 2.0** (scope `https://www.googleapis.com/auth/business.manage`); it rejects API keys with 401 because the data is user-owned. **We** manage the OAuth app + token refresh.
  Source: <https://developers.google.com/my-business/content/implement-oauth>
- **Access is gated:** you must submit Google's Business Profile API access request form; quota starts at **0** and is raised only after manual approval, typically **3–10 business days (up to a few weeks)**.
  Sources: <https://developers.google.com/my-business/content/faq>, <https://developers.google.com/my-business/content/basic-setup>

> Verdict: best raw capability and free, but it violates two hard requirements — instant self-serve (approval takes days) and provider-managed OAuth. Keep as a **future direct-integration fallback** once/if we obtain our own Google approval and want to drop the middleman fee.

### 2b. ReviewHook — **strong runner-up (emerging, purpose-built)**
- Purpose-built GBP review REST API. Endpoints: `GET /reviews`, `GET /reviews/{id}`, `POST /reviews/{id}/reply`, `DELETE /reviews/{id}/reply`, `GET /locations`.
- **Manages OAuth:** "One-click OAuth flow. ReviewHook handles authentication, refresh tokens, and account/location ID discovery automatically" — and explicitly **"no approval queue required."**
- **Self-serve:** "Get your API key in seconds," no credit card.
- **Pricing:** free during beta ("3 months free at launch").
- Reply publication subject to "Google's standard content review queue (10 minutes to 30 days)" — same Google-side gate as everyone.
  Source: <https://reviewhook.dev/google-reviews-api>

> Verdict: capability-wise it matches the exact use case more cleanly than Ayrshare (review-only REST, no social-posting bloat) and is free. **Risk:** beta-stage, unproven longevity, undisclosed post-launch pricing. Good candidate to prototype against in parallel, not the safe production default yet.

### 2c. Rannkly / Localo / Podium / Birdeye — **not self-serve REST for GBP reply**
- **Rannkly:** review reply is a **dashboard/UI** feature (typed, template, or AI reply in a popup); no public self-serve REST developer docs for GBP reply were found.
  Source: <https://www.rannkly.com/guide-review-management/how-to-reply-to-reviews-in-rannkly>
- **Podium / Birdeye:** full reputation SaaS platforms sold via **sales/onboarding** (same enterprise pattern as Yext, which we rejected); no instant self-serve developer API key for GBP review reply. (No first-party self-serve REST reply doc found.)
- **Localo:** primarily a GBP optimization SaaS UI; no first-party self-serve REST reply API surfaced in docs.

> Verdict: fail the self-serve instant-API-key requirement; not pursued further.

### 2d. Read-only (CANNOT reply — fail the reply requirement)
These return review data only (scraping / SERP data); **none can post a reply** to Google:
- **SerpApi** Google Maps Reviews API — read-only scraper. <https://serpapi.com/google-maps-reviews-api>
- **Outscraper** — read-only Google Maps reviews scraper. <https://outscraper.com/google-serp-api/>
- **DataForSEO** — read-only reviews/SERP data API.
- **Google Places API** — read-only, returns up to 5 reviews, no reply. (First-party read data, not management.)

> Useful only if we ever need cheap read-only review ingestion; irrelevant for the reply requirement.

---

## 3. Comparison table

| Provider | GBP read? | GBP reply? | Self-serve instant key? | Real-time? | Manages Google OAuth (no allow-listing)? | Pricing | Setup time | Doc quality |
|---|---|---|---|---|---|---|---|---|
| **Ayrshare** ⭐ | Yes [get-reviews] | Yes `POST /api/reviews/reply` [overview] | Yes, dashboard + free trial [pricing] | ~10-min sync (near-real-time) [blog] | Yes [intro] | Premium $149 / Business $599 (multi-loc via Profile Keys) [pricing] | Minutes | Good, versioned REST docs |
| **ReviewHook** | Yes `GET /reviews` | Yes `POST /reviews/{id}/reply` | Yes, key "in seconds" | Not stated (Google moderation queue on reply) | Yes, "no approval queue" | Free (beta) | Minutes | Focused REST docs; beta |
| **Google GBP API (direct)** | Yes `GET .../reviews` | Yes `PUT .../reviews/{id}/reply` | **No** — access request, quota starts 0 | Yes, live | **No** — we own OAuth app | Free | **3–10 business days approval** | Excellent (first-party) |
| **Rannkly** | Yes (UI) | Yes (UI only) | No public self-serve REST | n/a | n/a | SaaS | Onboarding | UI help center, no dev API |
| **Podium / Birdeye** | Yes | Yes (platform) | **No** (sales-led) | n/a | Managed (via platform) | Enterprise/sales | Weeks | Sales-gated |
| **SerpApi** | Yes | **No (read-only)** | Yes | Real-time reads | n/a | Per-search | Minutes | Good |
| **Outscraper** | Yes | **No (read-only)** | Yes | Sync/async | n/a | Per-record | Minutes | Good |
| **DataForSEO** | Yes | **No (read-only)** | Yes | Async | n/a | Per-request | Minutes | Good |
| **Google Places API** | Yes (≤5) | **No (read-only)** | Yes (GCP key) | Real-time reads | n/a | Per-request | Minutes | Excellent |

Citations for the capability claims are the source URLs listed in §1–§2 above (Ayrshare get-reviews/overview/blog/pricing/intro; Google review-data/faq/implement-oauth; ReviewHook page; Rannkly help; SerpApi/Outscraper pages).

---

## 4. Recommendation

**Primary: Ayrshare.** It is the only *established* provider that clears every hard requirement — self-serve instant API key, documented REST GBP `get reviews` + `POST reply`, managed Google OAuth (no multi-day Google allow-listing), and ~10-minute review freshness that decisively beats GMBapi's rejected once-a-day sync. Start on **Premium ($149/mo)** for a single connected GBP; move to **Business ($599/mo)** when we go multi-tenant and need **Profile Keys** (`Profile-Key` header) so each NewRelay account connects its own location.

**Runner-up: ReviewHook.** Purpose-built for exactly this (review read + reply only), one-click managed OAuth with "no approval queue," free during beta. Cleaner fit than Ayrshare's broader social-posting API, but beta-stage with undisclosed launch pricing — worth prototyping in parallel, not yet the production default.

**Fallback for later: Google's direct GBP API** — free and real-time, adopt once we obtain our own Google API approval and want to remove the intermediary fee. Rejected for now purely because it requires the multi-day approval and self-managed OAuth we are explicitly trying to avoid.

**Shared caveat (all providers, including Google direct):** a posted reply's *public visibility* passes through Google's own content-moderation queue (minutes to, worst case, up to 30 days). No provider can bypass this — it is a Google-side gate, not a differentiator.
