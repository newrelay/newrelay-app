# 0003. Test coverage policy

Date: 2026-08-31
Status: Accepted

## Context

The ask was 95%+ coverage across the board. This is a large Rails + Vue
monolith. A hard 95% gate on the existing suite would fail CI immediately
and push people to write empty tests. We already run SimpleCov (backend)
and Vitest coverage (frontend) in CircleCI and publish to Qlty.

Project conventions already require: new service classes get a happy path
and a failure path; billing/webhooks/payments always get specs.

## Decision

- **Target:** 95% line coverage on *new* code in money, auth, webhooks,
  channel ingest, and jobs that mutate account state.
- **Floor:** optional CI ratchet via `COVERAGE_MINIMUM` (RSpec/SimpleCov)
  and `VITEST_COVERAGE_MIN` (Vitest). Unset means report-only so we do
  not brick the current suite.
- **Do not** require 95% on the historical tree in one change. Raise the
  floor after a measured baseline.

## Consequences

Coverage is a ratchet, not a rewrite. A PR that adds a checkout service
without specs is incomplete. A PR that does not lift global coverage from
~current to 95% is not incomplete.
