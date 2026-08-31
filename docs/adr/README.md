# Architecture Decision Records

This folder is the source of truth for durable technical decisions.

Write an ADR when you change payment flow, idempotency, plan matrix, DNS,
observability, typing, or any choice that a future engineer would otherwise
re-litigate from code comments.

## How to add one

1. Copy `NNNN-title.md` using the next number.
2. Fill Context / Decision / Consequences.
3. Link it from the PR.

Template:

```markdown
# NNNN. Title

Date: YYYY-MM-DD
Status: Accepted

## Context

What problem, and what would go wrong if we pick poorly.

## Decision

What we chose, in one paragraph.

## Consequences

What we gain, what we give up, and how to revisit.
```

Do not backfill an ADR for every historical file. Record the seams that
matter, then add one ADR per new significant decision.
