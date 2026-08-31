# 0002. Observability: Sentry, logging, and alerts

Date: 2026-08-31
Status: Accepted

## Context

The ask was "100% log coverage and alerting for anything which can break."
Logging every branch and paging on every `warn` creates alert fatigue and
hides real outages. The app already has Sentry (`sentry-ruby`, `sentry-rails`,
`sentry-sidekiq`, `@sentry/vue`) and `ChatwootExceptionTracker`. `/health` is
intentionally dependency-free for ALB liveness.

## Decision

- **Exceptions:** unhandled errors go to Sentry. App code uses
  `ChatwootExceptionTracker` when it rescues and still needs a report.
  Sidekiq/Rails report automatically when `SENTRY_DSN` is set.
- **Logs:** prefix domain failures (`[stripe_webhook]`, `[plan_checkout]`,
  `[exception]`). Never empty `rescue StandardError`. Billing must not fail
  silently (see project conventions).
- **Alerts:** Sentry issue alerts on new/regressed errors in production.
  Load balancers use `GET /health` (liveness) and `GET /ready` (Postgres +
  Redis). Page on `/ready` 503, not on every application log line.
- **PII:** `send_default_pii` stays on unless `DISABLE_SENTRY_PII` is set.
  Releases are tagged with `GIT_HASH` so fixes can be tied to deploys.

## Consequences

We will not add a log line to every method. New breakable paths (payments,
webhooks, channel ingest, jobs that mutate account state) must log on
failure and reach Sentry if they swallow the exception. Production without
`SENTRY_DSN` logs a boot warning.
