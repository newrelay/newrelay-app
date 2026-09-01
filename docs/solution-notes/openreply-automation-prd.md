# PRD: Social Media Comment-to-DM Automation (OpenReply Alternative)

> **Superseded 2026-09-01** — see [`comment-to-dm-automation-prd.md`](comment-to-dm-automation-prd.md). This proposal's core idea (extend `AutomationRule` with `send_dm`/`reply_to_comment` actions) was reviewed against the current codebase and rejected: `AutomationRule` has no comment/lead concepts today and is enterprise-audited, so extending it is more invasive than building an isolated module. Kept here for history only.

## 1. Overview
The goal is to build an automation feature similar to **OpenReply** (or ManyChat) directly into the Chatwoot/NewRelay platform. This feature will allow businesses to automatically send Direct Messages (DMs) or publicly reply to users who comment on their Instagram Posts/Reels or Facebook Posts with specific keywords. 

## 2. Goals
- **Automate Engagement:** Automatically respond to Instagram & Facebook comments.
- **Lead Generation:** Drive engagement by sending resources, links, or promos via DM when a user comments a keyword (e.g., "Comment 'INFO' to get the link").
- **Seamless Integration:** Leverage the existing Chatwoot `AutomationRule` engine rather than building a separate rules engine from scratch.

## 3. User Stories
- As a business owner, I want to set a rule that sends a DM containing a purchase link whenever someone comments "BUY" on my Instagram Reel.
- As a marketer, I want to auto-reply to the comment publicly (e.g., "Just sent you a DM!") to boost post engagement algorithms.
- As an agent, I want these automated conversations to show up in the Chatwoot inbox seamlessly, tagged with a specific label.

## 4. Features & Requirements

### 4.1 Trigger Events
- Support for Instagram and Facebook `comment` webhooks via the official Meta Graph API.
- Introduce a new event trigger in Automations (e.g., `Comment Created`) or extend the existing `Message Created` event to handle comment types.

### 4.2 Automation Conditions
- **Message Type:** Must equal `comment`.
- **Content/Keyword:** Must `equal` or `contain` specific keywords (e.g., "link", "info").
- **Source/Channel:** Must equal `Instagram` or `Facebook Page`.

### 4.3 Automation Actions
- **Send Direct Message (DM):** Triggers a private message to the user who commented.
- **Reply to Comment:** Posts a public reply thread under the user's comment.
- **Standard Chatwoot Actions:** Add labels, assign to teams, change priority, etc.

---

## 5. Technical Implementation Plan (Native)

Since Chatwoot already handles Meta authentication, webhooks, and has a robust automation engine, **building this natively is the easiest and most stable approach**. 

### 5.1 Webhook Processing
- Enhance the Facebook/Instagram webhook controller (`app/controllers/webhooks/facebook_controller.rb` / `app/services/facebook/webhook_handler.rb`) to correctly parse incoming comment events.
- Save these as `Message` records in the database with a specific `message_type` or `content_type` indicating it is a public comment.

### 5.2 Extending Automation Rules
Update `app/models/automation_rule.rb`:
- Add new condition attributes if necessary (e.g., `message_type`).
- Add new action attributes: `send_dm`, `reply_to_comment`.

### 5.3 Execution Workers
- Update the Action handlers (e.g., `Automation::Action::SendDm`, `Automation::Action::ReplyToComment`) to call the respective Meta Graph API endpoints to send a DM or reply to a comment using the `page_access_token`.

---

## 6. Recommended External Repositories (For Reference)

If you are looking for external repositories to integrate or reference, the primary open-source project in this space is:

### [diwenne/openreply](https://github.com/diwenne/openreply)
- **What it is:** An open-source alternative to ManyChat specifically for Instagram comment-to-DM automation. 
- **How to use it:** 
  - **Option A (Reference):** Read their source code to see exactly how they interact with the Meta Graph API for the comment-to-DM flow.
  - **Option B (Microservice):** You could theoretically deploy OpenReply as a separate microservice and use webhooks to sync data back to Chatwoot, but this introduces unnecessary complexity (managing two Meta App reviews, two databases, etc.).
- **Recommendation:** Do **not** inject the entire repo into the codebase. Instead, use their API patterns as a reference and build the feature natively inside Chatwoot's existing `AutomationRule` framework.
