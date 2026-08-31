# 0001. Record architecture decisions

Date: 2026-08-31
Status: Accepted

## Context

This repo grew from Chatwoot OSS plus a NewRelay enterprise overlay. Solution
notes live under `docs/solution-notes/`, but they mix product intent with
implementation. Significant technical choices (webhooks, billing, custom
domains, observability) were not recorded in one place, so later work
contradicts earlier ones.

## Decision

Use `docs/adr/` for durable engineering decisions. Product scope stays in
solution notes / feature bibles. One ADR per decision, numbered, with
Context / Decision / Consequences.

## Consequences

PRs that change a recorded seam must update or supersede the ADR. We will not
write an ADR for every class in the tree; that is noise, not architecture.
