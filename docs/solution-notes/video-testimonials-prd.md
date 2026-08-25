# PRD — Video Testimonials

**Status:** Draft · **Owner:** Reputation squad · **Last updated:** 2026-08-25 (Phase 3 complete — E1–E6 + B7)
**Companion docs:** `reputation-roadmap.md`, `reputation-demo-inventory.md`

Rule inherited from the roadmap: **no feature ships as "real" until its backend exists.** Until
then it stays mock with a `Demo` badge. This PRD lists every capability the current UI *implies*,
marks what is real vs. mock, and sequences the build so nothing is missed.

---

## 1. Problem & Goal

Businesses convert better with authentic customer **video** testimonials than with star ratings alone.
Today the Reputation module can request/collect written reviews but the Video Testimonials page is a
**fully mocked UI** (`VideoTestimonialsPage.vue` runs on `mockVideos`). The thin backend
(`Reputation::VideoTestimonial`: token + title + email + one attached video + status string) can accept an
uploaded video via a public link, but nothing else the UI promises exists.

**Goal:** a customer receives a request → records/uploads a video on a public page → it lands in the
dashboard → staff review/approve/publish → it can be shared or embedded, with AI assist where it earns its place.

---

## 2. Current State (audited 2026-08-24)

### Backend — what EXISTS
| Piece | File | Reality |
|---|---|---|
| Model | `app/models/reputation/video_testimonial.rb` | `token`, `title`, `email`, `status` (default `pending`), `has_one_attached :video`. **No** rating/topics/transcript/views/likes/duration/contact link/approval fields. |
| Dashboard controller | `api/v1/accounts/reputation/video_testimonials_controller.rb` | `index`, `destroy`, `requests_index` (video-type review requests), `dispatch_request` (email a record link). |
| Public controller | `reputation/public_video_testimonials_controller.rb` | `new` (upload page), `create` (attach video, mark linked review_request `completed`). |
| API shape | `index.json.jbuilder` | returns `id, title, email, status, created_at, video_url`. |
| Routes | `config/routes.rb:223`, `:728` | dashboard `index/destroy/dispatch_request/requests_index`; public `new`/`create`. |

### Frontend — what the UI SHOWS (all mock)
`VideoTestimonialsPage.vue` renders from `mockVideos` and **fabricates**: author, company, avatar,
thumbnail, duration, rating, views, likes, platform, AI tags, topics, transcript summary, sentiment,
confidence, marketing score, quotable line, activity timeline, notes, grid/list/timeline views, and
filters (platform/rating/duration/status/AI-tags/sort). Modals: `RequestVideoTestimonialModal`,
`ExportVideoTestimonialsModal`.

### The gap in one line
**UI promises ~25 capabilities; backend delivers ~4 (upload, list, delete, email-request).** Everything
else is Demo.

---

## 3. Full Feature Inventory (nothing dropped)

Legend — **Real** = backend exists & wired · **Partial** = some backend, UI ahead · **Mock** = UI only, no backend.

### A. Collection & Intake
| # | Feature | State | Notes |
|---|---|---|---|
| A1 | Public record/upload page (`/reputation/video/:account_id/new`) | Partial | Page + create + record/upload UX exist; needs size/type/duration limits, consent, token-token → tokens (§7.5), missing states (§7.2). |
| A2 | Request via email (`dispatch_request`) | Real | Sends `{{video_link}}`; uses default video template. |
| A3 | Request via SMS / WhatsApp | Mock | No channel path; reuse `ReviewRequestSendService` channels. |
| A4 | Request modal (recipients, channel, message, schedule) | Partial | `RequestVideoTestimonialModal` UI exists; wire to real send + schedule (reuse RequestsPage patterns). |
| A5 | Link a submission to a contact | Mock | Model has `email` only; add `contact_id`. |
| A6 | Link a submission to its originating review_request | Partial | `create` matches by `token` and marks it completed; store the FK on the testimonial. |
| A7 | In-browser webcam recording | **Real** | `MediaRecorder` capture + preview + timer already built in `new.html.erb`; corrected from "Mock" during design review. |
| A8 | Upload constraints (max size, mime, max duration) | Mock | 90s + 100MB (§7.6 #3); validate server-side + client hint + shown up front. |
| A9 | Consent / rights-to-use capture | Mock | Hard-block submit (§7.6 #1). Store `consented_at`. Wireframe in §10. |

### B. Library, Views & Filters
| # | Feature | State | Notes |
|---|---|---|---|
| B1 | Grid / List / Timeline views | Mock (UI real) | Pure FE; works once list data is real. |
| B2 | Search (author/transcript) | Mock | Needs real fields to search. |
| B3 | Filter: Platform | Mock | Requires `platform`/destination field. |
| B4 | Filter: Rating | Mock | Requires `rating`. |
| B5 | Filter: Duration | Mock | Requires `duration_seconds`. |
| B6 | Filter: Status | Partial | `status` exists (string); formalize enum. |
| B7 | Filter: AI Tags | Mock | Requires AI tagging (Section E). |
| B8 | Sort (newest/oldest/rating/views) | Mock | Needs `rating`, `views`. |
| B9 | Pagination ("1–N of 321") | Mock | Add real paging to `index`. |
| B10 | KPI cards (Total, Published %, Avg rating, Awaiting, AI highlights) | Mock | Compute server-side from real rows. |

### C. Playback & Detail Panel
| # | Feature | State | Notes |
|---|---|---|---|
| C1 | Video player (real file) | Partial | `video_url` exists; wire `<video>` to it, replace thumbnail-only mock. |
| C2 | Poster/thumbnail generation | Mock | Extract a frame on upload (server) or first-frame client capture. |
| C3 | Duration capture | Mock | Read on upload; persist `duration_seconds`. |
| C4 | Quick-info row (platform/date/duration/rating) | Mock | Real once fields exist. |
| C5 | Tabs: Overview / Transcript / AI Insights / Activity / Notes | Mock | Each needs its own backend (below). |

### D. Moderation & Lifecycle
| # | Feature | State | Notes |
|---|---|---|---|
| D1 | Status workflow: pending → approved → published / rejected | Partial | String today; make enum + transitions + timestamps + `PATCH update`. |
| D2 | Approve / Reject / Publish actions | Mock | UI dropdown only; add endpoints. |
| D3 | Activity timeline (submitted/approved/published/shared) | Mock | Needs an events/audit trail table or reuse. |
| D4 | Team notes / comments | Mock | New `video_testimonial_notes` (or reuse notes infra). |
| D5 | Delete | Real | `destroy` wired. |

### E. AI Assist (each is its own backend)
| # | Feature | State | Notes |
|---|---|---|---|
| E1 | Transcript (timed) | Mock | Needs STT provider; store cues. Gate behind flag. |
| E2 | AI summary | Mock | Reuse `Reputation::AiInsightsService` LLM path over transcript. |
| E3 | Topics extraction | Mock | LLM tags from transcript. |
| E4 | Sentiment + confidence | Mock | Reuse sentiment path; per-testimonial. |
| E5 | Marketing score + "most quotable line" | Mock | LLM over transcript. |
| E6 | Suggested reply | Mock | Reuse `AiDraftService`. |
| E7 | Auto-clip highlights for social | Mock | Heavy (video processing); **defer**, keep flag off. |

### F. Distribution & Output
| # | Feature | State | Notes |
|---|---|---|---|
| F1 | Reply to author | Mock | Depends on channel back to contact. |
| F2 | Share link (public testimonial page) | Mock | Public show by token; copyable URL. |
| F3 | Download single video | Partial | `video_url` is downloadable; wire button. |
| F4 | Export ZIP of videos | Mock | `ExportVideoTestimonialsModal` UI only; needs a packaging job. |
| F5 | Export report (PDF) / data (CSV) | Mock | CSV is cheap; PDF via existing report path. |
| F6 | Embed on website / widget | Mock | Tie into `Reputation::Widget`. |
| F7 | Publish to platforms (Instagram/site) | Mock | Timeline claims it; **defer**, out of MVP. |

---

## 4. Data Model — target schema

Extend `reputation_video_testimonials` (migrations, additive):

```
contact_id          :bigint  (fk, nullable)        # A5
review_request_id   :bigint  (fk, nullable)        # A6
customer_name       :string                        # display (from contact or form)
company             :string
rating              :integer                        # B4/B8
duration_seconds    :integer                        # B5/C3
thumbnail (attach)  ActiveStorage                   # C2
platform            :string                         # B3 (destination the review was aimed at)
status              :string enum                     # D1: pending|approved|published|rejected
approved_at         :datetime
published_at        :datetime
rejected_at         :datetime
consented_at        :datetime                        # A9
views               :integer default 0              # B8/B10
transcript          :jsonb  (cues[])                 # E1  (flag-gated)
ai                  :jsonb  {summary,topics[],sentiment,confidence,marketing_score,quote,tags[]}  # E2–E5
```

Supporting (only if reuse isn't available):
- `reputation_video_testimonial_events` (id, testimonial_id, kind, actor, created_at) — D3.
- `reputation_video_testimonial_notes` (id, testimonial_id, user_id, body, created_at) — D4.

Keep `ai`/`transcript` as jsonb to avoid table sprawl (ponytail: one column, not five tables).

---

## 5. API surface — target

Dashboard (`/api/v1/accounts/:id/reputation/video_testimonials`):
- `GET index` — **add** paging, filters (platform/rating/duration/status/tag), sort; return full row + `video_url`, `thumbnail_url`. (B1–B10, C)
- `PATCH :id` — status transitions + edit title/customer_name. (D1/D2)
- `POST :id/notes`, `GET :id/notes` — D4.
- `GET :id/events` — D3 (or embed in show).
- `POST :id/ai` (or auto on upload) — trigger E2–E6, cached. Flag-gated.
- `GET summary` — KPI card numbers computed server-side. (B10)
- `POST dispatch_request` — **extend** to channel + schedule + message (align with `ReviewRequestSendService`). (A3/A4)
- `DELETE :id` — exists.

Public:
- `GET reputation/video/:account_id/new` — exists; add record UX + limits + consent. (A1/A7/A8/A9)
- `POST reputation/video/:account_id` — **extend** create to persist contact/rating/consent/duration and set `review_request_id`. (A5/A6)
- `GET reputation/video/t/:token` — **new** public testimonial page for share links. (F2)

---

## 6. Phasing (ship in slices; update this doc after each — never repeat a missed item)

### Phase 1 — "Real library" (make the page stop lying)
Backend for the core loop; drop the mock list.
- Schema: `contact_id, review_request_id, customer_name, company, rating, duration_seconds, platform, status enum, *_at, consented_at, views, thumbnail`. (Model/DB)
- `index`: real rows + paging + filters + sort + `thumbnail_url`. (B1–B9)
- `summary`: KPI numbers. (B10)
- `PATCH :id`: status workflow + timestamps. (D1/D2)
- Player wired to real `video_url`; duration + thumbnail captured on upload. (C1–C4)
- Public create extended: contact link, review_request link, consent, rating. (A1,A5,A6,A8,A9)
- Request modal wired to real send + channel + schedule. (A2–A4)
- **Exit:** upload → appears in list → approve/publish → visible. Zero Demo badges on library/detail basics.

### Phase 2 — "Distribution"
- Public share page by token + copy link. (F2)
- Download button wired; CSV export. (F3/F5-CSV)
- Notes + activity timeline real. (D3/D4)
- Embed via `Reputation::Widget`. (F6)
- **Exit:** an approved testimonial can be shared/embedded; team can annotate.

### Phase 3 — "AI assist" (flag-gated, `reputation_demo_surfaces`) — **COMPLETE (E1–E6 + B7)**
- Transcript (STT) → summary, topics, sentiment, marketing score, quotable line, suggested reply. (E1–E6) ✅
  - STT decision (open Q #1) **resolved by reuse**: codebase already commits to OpenAI transcription
    (`gpt-4o-mini-transcribe`, used by `Messages::AudioTranscriptionService`). No new provider.
  - One service `Reputation::VideoInsightsService` (transcribe + one JSON LLM pass), run async by
    `Reputation::VideoInsightsJob`, triggered by `POST video_testimonials/:id/analyze` (flag-gated).
    Stored in a single `ai_insights` jsonb column. FE: Transcript + AI Insights tabs render real data,
    hidden unless the flag is on, with an "Analyze video" trigger + poll.
  - 25MB transcription cap (OpenAI limit); videos above it skip transcription honestly (blank + error note).
- AI-tag filter becomes real. (B7) ✅ — the (previously mock) "Relay AI Tags" dropdown now lists the
  distinct `ai_insights.topics` across loaded rows and filters the list client-side. Demo-flag only.
  ponytail: client-side filter (no backend) — move to a jsonb `WHERE ... ? tag` query when real paging lands.
- **Exit:** AI fields reflect the real video; blank/absent until processed (honest, no fabrication). ✅

### Deferred (keep flag OFF, don't build until asked)
- E7 auto-clip highlights (video processing pipeline).
- F4 ZIP export (packaging job) — unless a customer needs it; then Phase 2.5.
- F7 publish to Instagram/site (social posting).
- SMS/WhatsApp record links if channel proves unused.

---

## 7. Design review (added 2026-08-24 via /plan-design-review)

Design review of this PRD. Initial design completeness **5/10 → 8/10** after the additions
below. The dashboard UI already exists as a rich mock (`VideoTestimonialsPage.vue`, ~1032 lines);
the public record page already does webcam recording (`new.html.erb`, ~247 lines). So this is a
**de-mock + fill-the-state-gaps** effort, not a greenfield design.

### 7.1 What already exists (reuse, don't reinvent)
- **Relay `DESIGN.md` + `TOKENS.md`** — semantic tokens are the source of truth for the dashboard.
- **Dashboard page** — grid/list/timeline views, master-detail panel (5 tabs), filter bar, KPI row: all built (mock data).
- **Public record page** — `MediaRecorder` webcam capture, preview, record/upload toggle, recording timer, success state: all built.
- **Request-send patterns** — channel validation + date/timezone scheduling from `RequestsPage.vue` (built this session). The video request modal must reuse these, not re-implement.
- **AI services** — `Reputation::AiInsightsService`, `AiDraftService` for Phase-3 summary/sentiment/reply.

### 7.2 Interaction state matrix (Pass 2 — was the biggest gap)
"What the user SEES," not backend behavior. Video is state-heavy; specify all of these.

| Surface / feature | Loading | Empty | Error | Success | Partial |
|---|---|---|---|---|---|
| Library grid/list | skeleton cards (not spinner) | warm empty state + "Request your first video" primary CTA + 1-line context | inline retry banner, keeps last data | rows render | "Showing N of M" + load-more |
| KPI row | shimmer numbers | all `0` with muted "No videos yet" | hide card, don't show broken `NaN%` | numbers | — |
| Detail: video player | poster + buffering ring | n/a | "This video can't be played" + Download fallback | plays | buffering mid-play = inline ring |
| Detail tabs (Phase 1) | — | **Transcript / AI Insights hidden until Phase 3** (not empty tabs) | — | Overview/Activity/Notes show | — |
| Public: camera | "Starting camera…" | n/a | **permission-denied state** → steps + "Upload instead" (see wireframe) | live preview | — |
| Public: upload | **progress % + size** (see wireframe) | n/a | file-too-big / unsupported-codec inline, before submit | thank-you state | transcode = "processing, we'll email you" |
| Moderation action | button spinner | — | toast + revert optimistic state | status badge flips | — |

Approved wireframe for the three record-page states: **§10 Approved Mockups**.

### 7.3 User journey storyboards (Pass 3)
**Customer (mobile-first — most testimonials are filmed on a phone):**

| Step | Does | Feels | Design supports it |
|---|---|---|---|
| 1 | Taps link in email/SMS | curious, low commitment | branded record page, one clear ask, "takes 1 minute" |
| 2 | Grants camera / picks upload | mild friction | permission primed with why; upload fallback always visible |
| 3 | Records / previews | self-conscious | re-record freely, 90s cap shown, no forced retakes |
| 4 | Consent | cautious | plain-language rights, "private until you agree", removable |
| 5 | Submits, waits | impatient | progress %, keep-tab warning, "usually under a minute" |
| 6 | Done | good | warm thank-you + what happens next |

**Reviewer (staff):** notified → opens detail → watches → Approve/Publish/Reject in the footer control (exists) → status badge flips optimistically. Emotional need: fast triage of a queue. The "Awaiting Approval" KPI is the entry point.

### 7.4 Responsive & accessibility (Pass 6)
- **Mobile-first record page** is the PRIMARY viewport (phones film video). 44px touch targets, big record button, no hover-only affordances.
- **Dashboard master-detail**: on <1024px the detail panel is a full-screen overlay (already coded); ensure focus moves into the panel on open and returns to the card on close.
- **Captions = a11y + SEO**: the Phase-3 transcript (E1) doubles as the `<track kind="captions">` source. Note this so E1 isn't treated as AI-only sugar.
- Keyboard: grid is arrow-navigable, Enter opens detail, Esc closes; tab order through the 5 tabs.
- Contrast: body ≥16px, ≥4.5:1; status badges must not rely on color alone (keep the text label).

### 7.5 Design-system alignment (Pass 5)
- **Port the public record page to Relay tokens.** Today it loads `cdn.tailwindcss.com` and hardcodes `slate-*` — a `DESIGN.md` violation. Either compile Tailwind with the Relay token config, OR explicitly bless the public page as a standalone branded surface with its own documented token set (don't leave it as an accidental fork).
- Video request modal: build from `RelayButton/Input/Badge` + reuse the channel + scheduling components, matching `RequestReviewsModal.vue`.

### 7.6 Pass-7 decisions (resolved — recommended defaults, override any later)
| # | Decision | Resolved | Why |
|---|---|---|---|
| 1 | Consent gating | **Hard-block submit** until the rights-of-use box is checked | legal/rights protection before a video can be used publicly |
| 2 | Rating source | **Customer rates on the record page** (1–5★) | feeds the same 1–3★ private-feedback interceptor funnel the reviews flow already uses |
| 3 | Recording limits | **90s max + 100MB**, shown up front | keeps files deliverable, sets expectations, avoids silent upload failures |
| 4 | Moderation default | **New videos land `pending`** — staff approves before public | consent + brand safety; never auto-publish a customer's face |
| 5 | Upload UX | **Processing screen with keep-tab warning; email fallback** if transcode runs long | honest wait UX, no dead-end blank screen |

---

## 8. Open questions (still unresolved — need a real answer before their phase)
1. ~~**STT provider** for transcripts (cost/PII)?~~ **Resolved (2026-08-25):** reuse the codebase's existing OpenAI transcription (`gpt-4o-mini-transcribe`). Still gates captions (§7.4) — transcript is stored, captions UI not yet wired.
2. **Storage/CDN** for video delivery at scale — ActiveStorage service + signed URLs enough?
3. **`platform` semantics** — is a video tied to a review destination, or platform-agnostic? Affects B3 filter.

_(Prior open questions 4 "rating source" and 5 "moderation default" are now resolved — see §7.6.)_

---

## 9. NOT in scope (design decisions deliberately deferred)
- **AI auto-clip highlights (E7)** — needs a video-processing pipeline; flag OFF until asked.
- **ZIP export (F4)** — packaging job; browser multi-download or CSV covers the near term.
- **Social auto-post (F7)** — the mock timeline claims it; out of v1.
- **Video editing / trimming in-app** — customers submit as-is; no editor.
- **Real-time transcode preview** — processing is async with an email fallback (§7.6 #5), not a live editor.

## 10. Approved Mockups
| Screen / state | Path | Direction | Notes |
|---|---|---|---|
| Record page — consent / permission-denied / uploading | scratchpad `video-record-states.html` | Theme-aware Relay-token wireframe, mobile-first, trust-focused | Buildable spec for the 3 states the PRD lacked (A9/A7/A8). AI-image path was blocked (no OpenAI key); hand-built HTML used instead. |

## 11. Non-goals (v1)
Live streaming, video editing suite, multi-clip stitching, auto-posting to social networks,
face/voice redaction, multi-language dubbing.

## 12. Implementation Tasks
Synthesized from the design review. Each derives from a specific finding. P1 blocks Phase 1 ship.

- [ ] **T1 (P1, human: ~1d / CC: ~30m)** — public-record-page — Port `new.html.erb` to Relay tokens; add consent gate, 90s/100MB limits, camera-permission-denied + uploading/processing states.
  - Surfaced by: Pass 5 + Pass 2 — CDN Tailwind + hardcoded slate; missing states. Wireframe §10.
  - Files: `app/views/reputation/public_video_testimonials/new.html.erb`
- [ ] **T2 (P1, human: ~1d / CC: ~20m)** — model-schema — Extend `reputation_video_testimonials` (contact_id, review_request_id, rating, duration_seconds, status enum, consented_at, thumbnail, platform, *_at, views).
  - Surfaced by: §4 target schema; Pass 2 states need real fields.
  - Files: `app/models/reputation/video_testimonial.rb`, `db/migrate/*`
- [ ] **T3 (P1, human: ~1d / CC: ~20m)** — dashboard — Real `index` (paging/filters/sort/thumbnail_url) + `summary` KPIs; drop `mockVideos`.
  - Surfaced by: Pass 1/2 — B1–B10 mock.
  - Files: `.../reputation/video_testimonials_controller.rb`, `.../pages/VideoTestimonialsPage.vue`
- [ ] **T4 (P1, human: ~0.5d / CC: ~15m)** — moderation — `PATCH :id` status workflow (default `pending`) + optimistic UI.
  - Surfaced by: Pass 7 #4; D1/D2 mock.
  - Files: `.../reputation/video_testimonials_controller.rb`
- [ ] **T5 (P2, human: ~0.5d / CC: ~15m)** — detail-panel — Hide Transcript/AI Insights tabs until Phase 3; keep Overview/Activity/Notes.
  - Surfaced by: Pass 1 — 3 empty AI tabs in Phase 1.
  - Files: `.../pages/VideoTestimonialsPage.vue`
- [ ] **T6 (P2, human: ~0.5d / CC: ~15m)** — a11y — Master-detail focus management + keyboard nav; caption track from Phase-3 transcript.
  - Surfaced by: Pass 6 — a11y silent; captions = transcript.
  - Files: `.../pages/VideoTestimonialsPage.vue`

## 13. Engineering review (added 2026-08-24 via /plan-eng-review)

Reviewed Phase 1 (the buildable slice). Scope accepted as-is (well-phased, ~7 existing files + 1 migration).
6 findings; 1 architecture fork resolved (A2 → client-side); 5 must-fixes folded into Phase 1.

### 13.1 Findings
| # | Sev | Conf | Finding | Resolution |
|---|---|---|---|---|
| A1 | P1 | 8 | DRY: `video_testimonials_controller#dispatch_request:37-43` hand-rolls contact find-or-create + mailer, duplicating `ReviewRequestSendService#send!` | **Route video requests through `ReviewRequestSendService`** with a `video` template type; delete the parallel path. |
| A2 | P1 | 9 | Thumbnail + duration extraction unspecified (server ffmpeg vs client) | **Client-side capture** — canvas grab for thumbnail + `video.duration`, uploaded with the video. Zero new infra (no ffmpeg dep). |
| A3 | P1 | 8 | Public-exposure authz gap: share/embed could serve non-approved videos | **Invariant:** public read endpoints (`/r/t/:token`, embed) serve only `status IN (approved, published)`; everything else 404s. Specify now, enforce in Phase 2. |
| CQ1 | P1 | 9 | Consent not server-enforced (`public_video_testimonials_controller#create:13-16` saves w/o consent) | `validates :consented_at, presence: true` + reject create without it. Client checkbox alone is bypassable. |
| CQ2 | P2 | 7 | `status:string` vs FE labels ("Pending Approval" etc.) mismatch | Rails string-backed **enum** `pending/approved/published/rejected`; align FE labels to enum keys. |
| P1 | P1 | 8 | N+1 in `index` (`index.json.jbuilder` calls `video.attached?`+`url_for` per row) | Scope `.with_attached_video.includes(:contact)` (+ thumbnail when added). |
| P2 | P2 | 7 | Video streamed through Rails (`url_for(video)` disk redirect) | Fine for MVP; CDN/signed-URL at scale = open-Q2. Flag only. |

### 13.2 Test plan (3 critical specs — CLAUDE.md defers specs, but these guard security/correctness)
- **`video_testimonial_spec.rb`** — consent validation rejects create without `consented_at` (CQ1); status transitions (CQ2).
- **`public_video_testimonials_controller_spec.rb`** — E2E: submit with consent succeeds, without consent 422 (CQ1). CRITICAL: bypass = public leak.
- **Phase-2 share read** — non-approved status → 404 (A3). CRITICAL: prevents leaking un-moderated videos.

### 13.3 Failure modes (new codepaths)
| Codepath | Realistic failure | Test? | Error handling? | User sees? |
|---|---|---|---|---|
| public create | consent omitted | add (CQ1) | add validation | 422 + inline error |
| client thumbnail/duration | browser can't decode frame | — | fall back to server default poster + `duration=nil` | silent, acceptable |
| index | ActiveStorage N+1 | perf, not test | — | slow list |
| share read (Ph2) | serves pending video | add (A3) | status filter | 404 |
**Critical gap:** consent-omitted create (no test + no handling today = silent public exposure). Closed by CQ1.

### 13.4 Parallelization
`Lane A: T2 (model/migration) → T3 (dashboard index/summary) → T4 (moderation PATCH)` — sequential, shared `video_testimonials_controller` + model.
`Lane B: T1 (public record page)` — independent (`new.html.erb` + public controller).
Launch A + B in parallel worktrees; merge; T5/T6 (FE polish) after T3.

## 14. Implementation Tasks (eng review — appended to §12)
- [ ] **T7 (P1, human: ~2h / CC: ~15m)** — request-consolidation — Route video requests through `ReviewRequestSendService` (video template type); delete `dispatch_request`'s parallel contact/mailer path.
  - Surfaced by: A1. Files: `app/controllers/api/v1/accounts/reputation/video_testimonials_controller.rb`, `app/services/reputation/review_request_send_service.rb`
- [ ] **T8 (P1, human: ~3h / CC: ~15m)** — client-capture — Canvas thumbnail + `video.duration` on the record page, sent with upload; persist `thumbnail`/`duration_seconds`.
  - Surfaced by: A2. Files: `app/views/reputation/public_video_testimonials/new.html.erb`, `.../public_video_testimonials_controller.rb`
- [ ] **T9 (P1, human: ~1h / CC: ~10m)** — consent-enforcement — `validates :consented_at, presence: true`; reject create without it.
  - Surfaced by: CQ1. Files: `app/models/reputation/video_testimonial.rb`, `.../public_video_testimonials_controller.rb`
- [ ] **T10 (P1, human: ~30m / CC: ~5m)** — index-n1 — `.with_attached_video.includes(:contact)` on the index scope.
  - Surfaced by: P1. Files: `.../video_testimonials_controller.rb`
- [ ] **T11 (P1, human: ~1h / CC: ~10m)** — status-enum — Rails enum + aligned FE labels; document the public-read `approved/published`-only invariant.
  - Surfaced by: CQ2 + A3. Files: `app/models/reputation/video_testimonial.rb`, `.../pages/VideoTestimonialsPage.vue`

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | issues_open | 6 issues, 1 critical gap (consent), all folded into Phase 1 |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | issues_open | score 5/10 → 8/10, 5 decisions resolved |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

- **CROSS-MODEL:** Outside voice skipped — Codex not installed; no Claude subagent dispatched (cost containment). Single-model review.
- **VERDICT:** ENG + DESIGN CLEARED — Phase 1 ready to implement (T1–T11). 1 critical gap (consent, CQ1) closed by plan. Outside voice not run.

**UNRESOLVED DECISIONS:**
- STT provider for transcripts (gates Phase 3 + captions)
- Storage/CDN strategy for video delivery at scale (P2 / open-Q2)
- `platform` field semantics (destination-tied vs platform-agnostic)
