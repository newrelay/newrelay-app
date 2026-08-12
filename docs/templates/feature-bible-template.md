# 📖 FEATURE BIBLE: [Feature Name]

> **Purpose of this doc:** Is single file mein feature ka poora context hai — kya hai, kyun hai, kaise kaam karega, aur AI coder ko exactly kya instruct karna hai. Isse copy karke naye feature ke liye fill karo, phir Claude Code / Antigravity / Cursor ko de do as context.

**Status:** `Draft / In Progress / Shipped`
**Owner:** Chandresh
**Last updated:** [date]
**Related module:** [e.g., Reputation Management, GBP Integration]

---

## 1. WHAT — Feature Summary

**One-liner:** [Feature ek line mein kya karta hai]

**Elevator pitch (3-4 lines):** [Non-technical banda bhi samjhe]

---

## 2. WHY — Problem & Justification

**Problem statement:** [Konsa pain point solve ho raha hai]

**Who needs this:** [User persona — e.g., "Agency admin managing 20 client GBP profiles"]

**What happens without it:** [Current workaround / gap]

**Business value:** [Revenue, retention, competitive parity — e.g., "GoHighLevel has this, we need parity"]

---

## 3. USER STORIES

- As a **[role]**, I want **[action]**, so that **[outcome]**.
- As a **[role]**, I want **[action]**, so that **[outcome]**.

---

## 4. SCOPE

### ✅ In Scope
-
-

### ❌ Out of Scope (explicitly excluded)
-
-

### 🔮 Future / Phase 2 (noted but not now)
-

---

## 5. HOW IT ACTIVATES — Trigger & Lifecycle

**Activation trigger:** [Manual toggle? Webhook? Cron? User action?]

**Preconditions:** [What must exist before this feature can turn on — e.g., "OAuth connected", "Plan tier = Pro"]

**Lifecycle states:**
| State | Meaning | Next state trigger |
|---|---|---|
| `pending` | | |
| `active` | | |
| `error` | | |
| `disabled` | | |

**Deactivation / rollback:** [How does user or system turn this off cleanly]

---

## 6. EXTERNAL DEPENDENCIES & LEAD TIME

> ⚠️ Critical: coding takes hours, but external approvals can take days/weeks. Track this FIRST so it doesn't block launch.

| Dependency | Needed for | Who applies | Approval/setup time | Status | Blocker risk |
|---|---|---|---|---|---|
| [e.g., Google Cloud OAuth app] | | | | `not started / pending / approved` | |
| [e.g., API key/quota increase] | | | | | |
| [e.g., domain verification] | | | | | |
| [e.g., app review/publishing to production] | | | | | |

**Action item:** Start these applications on Day 1 — even before writing code — so approval runs in parallel with development.

**Fallback plan if approval delayed:** [e.g., use test/sandbox mode with limited test users while waiting for production approval]

---

## 7. DATA MODEL

**New/modified tables:**
```
table_name
  - field_name: type (constraints)
  - field_name: type (constraints)
```

**Relationships:** [FK links to existing tables]

**Migration notes:** [Backfill needed? Default values?]

---

## 8. BACKEND / API

**Endpoints:**
| Method | Route | Purpose | Auth |
|---|---|---|---|
| | | | |

**Background jobs:** [Sidekiq/queue jobs — name, trigger, retry policy]

**External integrations:** [3rd party APIs, rate limits, auth type]

**Existing patterns to follow:** [e.g., "match existing Sidekiq job structure in app/jobs/gbp_sync_job.rb"]

---

## 9. FRONTEND / UI

**Screens/components touched:** [New or modified]

**States to handle:** empty state, loading, success, error, permission-denied

**Design reference:** [Screenshot/Figma link or "match existing dashboard style"]

---

## 10. FLOW — Step by Step

1.
2.
3.

**Acceptance criteria (Definition of Done):**
- [ ] Given [context], when [action], then [result]
- [ ] Given [context], when [action], then [result]

---

## 11. EDGE CASES & FAILURE MODES

| Scenario | Expected behavior |
|---|---|
| API rate limit hit | |
| Auth token expired | |
| Duplicate/race condition | |
| User has no permission | |
| Third-party service down | |

---

## 12. NON-FUNCTIONAL REQUIREMENTS

- **Performance:** [e.g., "sync job must complete under 30s for 500 reviews"]
- **Security:** [e.g., "OAuth tokens encrypted at rest"]
- **Scalability:** [expected load]
- **Logging/monitoring:** [what needs to be traceable]

---

## 13. AI IMPLEMENTATION INSTRUCTIONS

> Ye section directly AI coder (Claude Code/Antigravity) ke liye hai — jitna specific utna better output.

**Tech stack constraints:** [e.g., "Rails + Sidekiq, no new gems without approval"]

**Files likely to touch:** [paths if known]

**Step-by-step build order:**
1.
2.
3.

**Do NOT:** [explicit anti-patterns — e.g., "don't create new auth middleware, reuse existing GbpAuthenticatable concern"]

**Test expectations:** [unit/integration coverage needed]

---

## 14. ROLLOUT PLAN

- **Feature flag:** [yes/no, name]
- **Rollout order:** [internal → beta → all users]
- **Success metric:** [how you'll know it worked]

---

## 15. OPEN QUESTIONS

- [ ]
- [ ]
