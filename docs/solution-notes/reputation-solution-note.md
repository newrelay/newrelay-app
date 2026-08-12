# Reputation Management Module — Solution Note

**Date:** 09 Jul 2026  
**Author/Owner:** Lead Product Architect / Developer

---

## 1. Overview

The **Reputation Management** module lets businesses (`accounts`) collect, monitor, and respond to customer reviews from Google Business Profile (GBP) and Facebook, request reviews via automated/manual SMS and Email templates, and showcase their social proof on their website using embeddable widgets. Additionally, it intercepts low ratings (1-3 stars) for private resolution and facilitates video testimonials collection.

### What we are building

* **Client/Dashboard Workspace**: An interface integrated into the Newrelay dashboard (using the approved vertical navigation sidebar from Tab 2) allowing business owners to respond to reviews, trigger campaigns, and configure settings.
* **Review Widgets & Collectors**: Public-facing embeddable JS widgets (carousel/grid) to showcase star ratings, plus custom video review collector pages.
* **Integrations Engine**: OAuth connection portals for Google Business Profile and Facebook Pages, backed by Sidekiq periodic pollers.

### Phased Roadmap

```mermaid
flowchart LR
    P0["<strong>PHASE 0</strong><br/>DB & Models<br/><font size=2>Set up core tables & scoped models</font>"]
    P1["<strong>PHASE 1</strong><br/>OAuth & Reviews Sync<br/><font size=2>Google & FB OAuth + pollers</font>"]
    P2["<strong>PHASE 2</strong><br/>AI Replies & Requests<br/><font size=2>Reply sync + templates engine</font>"]
    P3["<strong>PHASE 3</strong><br/>Widgets & Testimonials<br/><font size=2>Widgets, Video, and Interception</font>"]

    P0 --> P1 --> P2 --> P3
    
    style P0 fill:#f3f4f6,stroke:#d1d5db,stroke-width:1px
    style P1 fill:#eff6ff,stroke:#bfdbfe,stroke-width:1px
    style P2 fill:#f5f3ff,stroke:#ddd6fe,stroke-width:1px
    style P3 fill:#f0fdf4,stroke:#bbf7d0,stroke-width:1px
```

* **Phase 0 Outcome:** Core database migrations and ActiveRecord models successfully defined and verified.
* **Phase 1 Outcome:** Functional read-only reviews dashboard showing synced listings.
* **Phase 2 Outcome:** Ability to compose/AI-draft replies and dispatch automated SMS/Email request templates.
* **Phase 3 Outcome:** Live embeddable widgets, negative review private routing, and video collector portals.

---

## 2. Business Understanding

| Core Rule / Constraint | Business Implication / Rationale |
| :--- | :--- |
| **Multi-Tenancy** | Every review, integration, template, and request MUST be scoped by `account_id` (tenant) to prevent data leaks. |
| **Encrypted Credentials** | Google and Facebook access/refresh tokens must be encrypted in the database (`Rails.encrypts`) to prevent exposure. |
| **Negative Interception** | Ratings $\le 3$ stars are routed to private feedback lists, allowing businesses to resolve customer complaints before they affect public SEO rankings. |

---

## 3. The Core Problem We Are Solving

Many businesses struggle to maintain active customer review streams, leading to low local SEO search rankings and drop-offs. Manually managing replies across Google Maps and Facebook Pages is highly inefficient. 

```mermaid
flowchart TD
    subgraph Surface["THE SURFACE (User-Facing / Easy to replicate)"]
        direction LR
        S1["Star Badges"]
        S2["Response Textbox"]
        S3["Simple Templates"]
    end
  
    subgraph Core["THE CORE VALUE / INFRASTRUCTURE (What actually matters)"]
        direction LR
        C1["OAuth Token Managers"]
        C2["Sidekiq Sync Rollups"]
        C3["AI Agent Drafts"]
    end
  
    subgraph Outcome["THE DESIRED OUTCOME"]
        direction TB
        Out["Compounded Customer Trust & Optimized Local SEO Rankings"]
    end

    Surface -->|sits on top of| Core
    Core -->|makes possible| Outcome

    style Surface fill:#eff6ff,stroke:#bfdbfe,stroke-width:1px
    style Core fill:#f5f3ff,stroke:#ddd6fe,stroke-width:1px
    style Outcome fill:#f0fdf4,stroke:#bbf7d0,stroke-width:1px
```

---

## 4. Product Architecture Block Diagram

```
                  ┌──────────────────────────────────────────────┐
                  │              [USER FRONTEND]                 │
                  │             (Newrelay Dashboard)             │
                  └──────────────┬────────────────┬──────────────┘
                                 │                │
                  ┌──────────────▼──────┐  ┌──────▼──────────────┐
                  │   Public Widgets    │  │  Sidebar Navigation │
                  │  (Grid / Carousel)  │  │  (Overview/Reviews) │
                  └──────────────┬──────┘  └──────┬──────────────┘
                                 │                │
   ┌─────────────────────────────┼────────────────┼──────────────────────────────┐
   │                             ▼                ▼                              │
   │                 ┌────────────────────────────────────────┐                  │
   │                 │             [BACKEND API]              │                  │
   │                 │   (Reputation Controllers & Workers)   │                  │
   │                 └────────────────────────────────────────┘                  │
   └─────────────────────────────────────┬───────────────────────────────────────┘
                                         │
 ┌───────────────────────────────────────▼───────────────────────────────────────┐
 │                     BEHIND THE SCENES / SHARED SERVICES                       │
 │    [Sidekiq] · [ActiveRecord / PG] · [OpenAI/Claude API] · [OAuth Providers]  │
 └───────────────────────────────────────────────────────────────────────────────┘
```

1. **User Frontend**: Houses public embed widgets (Grid/Carousel formats) and the private sidebar accordion menu containing the 8 Reputation Management sections.
2. **Backend API**: Processes sync polling, replies publishing, and triggers review request webhook notifications.
3. **Behind the scenes**: Encrypted token storage, Sidekiq background workers, and AI completion services.

---

## 5. User Roles

* **Business Owner / Account Admin** *(Uses Dashboard Interface)*
  * Installs Google Business Profile & Facebook Pages integrations.
  * Manages settings, default templates, and widget configurations.
  * Accesses analytics.
* **Support Agent** *(Uses Dashboard Interface)*
  * Reviews incoming reviews, resolves feedback, and drafts responses (manually or via AI).
  * Sends manual review/video testimonial requests.
* **End Customer** *(Uses Widgets/Collector Pages)*
  * Submits ratings, public reviews, or records/uploads video testimonials.

---

## 6. The Happy Path — Sequential User Journey

```mermaid
flowchart TD
    Step1["<strong>1. Integration</strong><br/>Admin connects Google Business Profile location via OAuth"]
    Step2["<strong>2. Automatic Pull</strong><br/>Worker syncs recent reviews into local cache"]
    Step3["<strong>3. Request Dispatch</strong><br/>Agent sends template review request to a contact"]
    Step4["<strong>4. Customer Action</strong><br/>Customer clicks link, rates 5 stars, posts review"]
    Step5["<strong>5. AI Response</strong><br/>Agent reviews notification, clicks 'Draft with AI', sends response"]

    Step1 --> Step2 --> Step3 --> Step4 --> Step5
    
    Step5 -->|Success path| Success["<strong>[Success State]</strong><br/>5-star review published, AI reply posted, SEO ranking increases."]
    Step5 -->|Exception path| Exception["<strong>[Negative Interception / Support Action]</strong><br/>A. Customer rates ≤3 stars<br/>B. Redirected to private feedback form<br/>C. Alert sent to agent; resolved internally"]

    style Step1 fill:#eff6ff,stroke:#bfdbfe
    style Step2 fill:#eff6ff,stroke:#bfdbfe
    style Step3 fill:#eff6ff,stroke:#bfdbfe
    style Step4 fill:#eff6ff,stroke:#bfdbfe
    style Step5 fill:#eff6ff,stroke:#bfdbfe
    style Success fill:#dcfce7,stroke:#86efac
    style Exception fill:#fee2e2,stroke:#fca5a5
```

---

## 7. Capability Matrix by Phase

| Capability / Feature Area | Phase 0 | Phase 1 | Phase 2 | Phase 3 |
| :--- | :---: | :---: | :---: | :---: |
| **Migrations & Models** | Yes | Yes | Yes | Yes |
| **GBP & Facebook OAuth** | — | Yes | Yes | Yes |
| **Periodic Reviews Polling** | — | Yes | Yes | Yes |
| **Responses / AI reply drafting** | — | — | Yes | Yes |
| **SMS/Email Templates & requests** | — | — | Yes | Yes |
| **Grid/Carousel Widgets** | — | — | — | Yes |
| **Negative Interceptor Routing** | — | — | — | Yes |
| **Video Testimonials Builder** | — | — | — | Yes |

---

### 7.1 Phase 0 — DB & Models (Multi-Tenancy)
* **Goal**: Establish the secure Postgres database tables and Rails ActiveRecord definitions.
* **What gets built**: Migrations and active models for `Integration`, `Review`, `ReviewReply`, `Template`, `ReviewRequest`, `Widget`, and `FeedbackSubmission`.
* **What does NOT get built in Phase 0**: OAuth controllers, sync pollers, widgets, and frontend interfaces.

### 7.2 Phase 1 — Integrations & Sync
* **Goal**: Enable Google and Facebook page linking and initiate background pulling of reviews.
* **What gets built**: OAuth connection callback flows, Sidekiq synchronization workers.

### 7.3 Phase 2 — Responses & Outbound Requests
* **Goal**: Enable reply publishing (including AI drafting) and dispatching request templates.
* **What gets built**: AI prompts service, Google/Facebook reply publisher job, email/SMS template composers.

### 7.4 Phase 3 — Public Widgets & Video Testimonials
* **Goal**: Enable public review display widgets, private routing, and video collector portals.
* **What gets built**: Embed widget generator, 1-3 star feedback routing interceptor, video testimonial recording setup pages.

---

## 8. Complete Solution Architecture

Once all phases are complete:
* **The Newrelay App**: Integrates the vertical navigation sidebar accordion, holding Onboarding checklists, Responses feeds, templates dispatch logs, and settings tabs.
* **Public Testimonials**: Web pages displaying carousel review widgets and smartphone testimonial recorders.
* **API Worker Layer**: Background workers executing cron sync tasks, OAuth token renewals, and NLP sentiment analysis.

---

## 10. Conclusion

This phased approach guarantees early value validation (database and reviews polling setup first), limits scope creep, ensures OAuth security, and scales up to a complete Reputation Management solution.

---

## 11. Step-by-Step Implementation Approach

Below is the step-by-step build sequence that we will follow to implement the Reputation Management module:

### 🗄️ Phase 1: Database & Models (Multi-Tenancy)
1. **Migrations**: Create core tables scoped by `account_id` for multi-tenant data isolation:
   - `reputation_integrations`: Credentials for Google Business Profile and Facebook Pages.
   - `reputation_reviews`: Cache of customer reviews (ratings, text, sentiment, platform source).
   - `reputation_review_replies`: Tracks business responses synced to external APIs.
   - `reputation_templates`: Outbound SMS and Email request templates.
   - `reputation_review_requests`: Log of sent templates and click states.
   - `reputation_widgets`: Website reviews display configurations.
   - `reputation_feedback_submissions`: Intercepted private surveys.
2. **Models**: Write Active Record models with validations, associations, and standard Rails `encrypts` declarations to secure OAuth tokens.

### 🔌 Phase 2: Integrations & Background Sync
1. **OAuth Callbacks**: Set up authentication callback controllers for Google Business Profile and Facebook Pages.
2. **Sidekiq Sync Jobs**: Implement background workers to periodically pull new customer reviews and cache them locally in `reputation_reviews`.

### 💬 Phase 3: Responses & AI Drafting
1. **Reviews Feed API**: Backend routes and controller actions to fetch cached reviews and submit replies.
2. **AI Reply Service**: Connect the "Draft with AI" button action to the existing LLM integration to auto-generate replies.

### ✉️ Phase 4: Templates & Outbound Requests
1. **Request Templates**: Implement customized SMS and Email templates with dynamic merge fields (e.g. `{{contact.name}}`, `{{review_link}}`).
2. **Funnels Tracker**: Add tracking tokens to outbound links to monitor delivery states (Sent → Delivered → Clicked → Completed).

### 📹 Phase 5: Video Testimonials & Public Widgets
1. **Video Collector Wizard**: Setup page layout configurator to let users construct the video recording prompt page (Welcome, spokesperson upload, attribution).
2. **Review Widgets**: Code dynamic carousel/grid website widgets with custom rating filters.
3. **Private Interceptor**: Route $\le 3$ star widget scores to private customer feedback logs rather than public review portals.

### 🎨 Phase 6: Frontend Sidebar Navigation & Views
1. **Sidebar Accordion**: Integrate the collapsible left vertical sidebar submenu matching the Tab 2 layout standard.
2. **Sub-Menu Views**: Code each interactive dashboard view (Overview, Reviews, Requests, Video Testimonials, Widgets, Listing, GBP Operations, Settings).
