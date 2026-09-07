# FRD Program — Plan & Index

**Goal:** one FRD per feature — what it is, how it works today, DB tables, API/backend, frontend, existing test coverage, dev tools — for (1) every Chatwoot/newrelay OSS+Enterprise feature already in this codebase, then (2) our own custom features (Reputation, CRM, Comment-to-DM, Billing, etc.).

**Status:** In progress. Pacing: one phase at a time, review between phases.

**Progress:**
- [x] Phase 1 — Core: [01-conversations.md](01-conversations.md), [02-messages.md](02-messages.md), [03-contacts.md](03-contacts.md), [04-inboxes.md](04-inboxes.md), [05-channels.md](05-channels.md)
- [x] Phase 2 — Productivity: [06-automation-rules.md](06-automation-rules.md), [07-macros.md](07-macros.md), [08-canned-responses.md](08-canned-responses.md), [09-labels-custom-attributes.md](09-labels-custom-attributes.md), [10-teams-agents.md](10-teams-agents.md)
  - Not yet covered from section B: Custom Filters, Bulk Actions, Working Hours — roll into Phase 3 or a later pass, TBD
- [x] Phase 3 — Outreach & Reporting: [11-campaigns.md](11-campaigns.md), [12-csat-surveys.md](12-csat-surveys.md), [13-reports.md](13-reports.md), [14-help-center.md](14-help-center.md)
- [x] Phase 4 — newrelay custom: [15-reputation-management.md](15-reputation-management.md), [16-crm-deals-pipelines.md](16-crm-deals-pipelines.md), [17-comment-to-dm-automation.md](17-comment-to-dm-automation.md)
- [x] Phase 5 — Platform: [18-captain-ai.md](18-captain-ai.md), [19-sla-custom-roles.md](19-sla-custom-roles.md), [20-billing-subscription.md](20-billing-subscription.md), [21-super-admin.md](21-super-admin.md), [22-webhooks-integrations.md](22-webhooks-integrations.md)

**All 5 phases complete, plus the deferred Phase 2 leftovers — 25 FRDs total.**
- [x] Phase 2 leftovers: [23-custom-filters.md](23-custom-filters.md), [24-bulk-actions.md](24-bulk-actions.md), [25-working-hours.md](25-working-hours.md)

See [22-webhooks-integrations.md](22-webhooks-integrations.md) for the program-wide summary of cross-cutting findings (Billing test coverage is the top-priority gap).

---

## 1. Template

We already have `docs/templates/feature-bible-template.md`, but it's a **forward-looking spec** template (External Dependencies & Lead Time, AI Implementation Instructions, Rollout Plan — for features not yet built).

For documenting **existing/shipped** features, those sections don't fit. I'll use a leaner **as-built** template instead: `docs/frd/_template.md` (see below), with sections matching exactly what you asked for — what it is, how it works, data model, API, frontend, test coverage, dev tools, edge cases.

For **new custom features not yet built**, we keep using `docs/templates/feature-bible-template.md` as-is (already proven — see `docs/solution-notes/*-feature-bible.md`, `*-prd.md`).

---

## 2. Feature Inventory (from codebase scan — models, routes, enterprise/)

### A. Core Messaging & Conversations
1. Conversations (status, priority, assignment, SLA)
2. Messages (content types, attachments, private notes)
3. Contacts & Contact Merge / Import
4. Inboxes (general settings, assignment policy, working hours, capacity limits)
5. Channels: Web Widget, Email, WhatsApp (incl. Calls), SMS/Twilio, Facebook, Instagram, Telegram, Line, TikTok, API channel
6. Teams & Team Members
7. Agents, Agent Bots, Agent Capacity Policies
8. Mentions, Notes, Conversation Participants
9. Notifications & Notification Settings

### B. Productivity & Automation
10. Canned Responses
11. Macros
12. Automation Rules
13. Labels & Custom Attributes
14. Custom Filters
15. Bulk Actions (+ audit log)
16. Working Hours & Business Availability

### C. Campaigns & Customer Outreach
17. Campaigns (one-off & ongoing)
18. CSAT Surveys
19. Email Templates

### D. Help Center
20. Portals, Articles, Categories, Folders

### E. CRM (newrelay custom)
21. Companies / Deals / Pipelines / Pipeline Stages / Tasks

### F. Reputation Management (newrelay custom — largest module)
22. Reputation Integrations (GBP OAuth connect)
23. Listings & Listing Members
24. Reviews & Review Replies (incl. AI reply)
25. Review Requests
26. Feedback Submissions (gated funnel)
27. Reputation Reports & Snapshots
28. Reputation Widgets (embeddable)
29. Video Testimonials
30. Reputation Templates & Settings

### G. Comment-to-DM Automation (newrelay custom)
31. Comment Automation Campaigns/Triggers
32. Response Controls, Social Accounts, Message Logs

### H. AI (Captain)
33. Captain Assistants, Scenarios, Documents, Custom Tools
34. Copilot Threads/Messages
35. Reply/Summary/Label-suggestion/Rewrite/Follow-up services

### I. Enterprise / Admin / Platform
36. SLA Policies & Events
37. Custom Roles
38. Account SAML Settings
39. Super Admin (accounts, users, billing coupons, app config, platform banners)
40. Subscriptions & Billing (plan feature limits, marketplace plan prices, payment transactions, commission rules)
41. Installation Config / White-labeling
42. Webhooks & Integration Hooks (Slack, Dialogflow, etc.)
43. Reporting (overview, CSAT, SLA, agent/team reports)

> Several of these (Reputation, CRM, Subscription, White-label, Comment-to-DM) already have partial docs in `docs/solution-notes/`. Those will be **consolidated into**, not duplicated by, the new FRDs.

---

## 3. Proposed Order (phased — confirm or reorder)

**Phase 1 — Core (foundation, everything else references these):** Conversations, Messages, Contacts, Inboxes, Channels overview
**Phase 2 — Productivity:** Automation Rules, Macros, Canned Responses, Labels/Custom Attributes, Teams/Agents
**Phase 3 — Outreach & Reporting:** Campaigns, CSAT, Reports, Help Center
**Phase 4 — newrelay custom, our differentiators:** Reputation (split into sub-FRDs per row 22-30), CRM, Comment-to-DM
**Phase 5 — Platform:** Captain AI, SLA/Custom Roles, Billing/Subscription, Super Admin, Webhooks/Integrations

Each FRD = 1 file, e.g. `docs/frd/01-conversations.md`, `docs/frd/22-reputation-integrations.md`.

---

## 4. What each FRD will contain (as-built template)

See `docs/frd/_template.md`:
- What it is / one-liner + who uses it
- How it works (user flow, step by step)
- Data model (actual tables/columns from `db/schema.rb`, relationships)
- Backend/API (real routes from `config/routes.rb`, controllers, jobs, services)
- Frontend (actual Vue components/store modules touched)
- Existing test coverage (real spec files, what's covered / gaps)
- Dev tools used (gems, JS libs, external services actually wired in)
- Edge cases / failure modes observed in code
- Open gaps (things noticed while documenting, not feature requests)
