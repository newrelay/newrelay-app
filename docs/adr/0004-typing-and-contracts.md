# 0004. Typing and contracts

Date: 2026-08-31
Status: Accepted

## Context

The ask was "entire backend 100% typed, no `any` types." The backend is
Ruby on Rails. There is no TypeScript `any` in `app/` / `enterprise/`.
Sorbet/RBS are not in the Gemfile. The dashboard is Vue 3 + JavaScript
(PropTypes, strong params), not a TypeScript codebase.

A big-bang Sorbet or TS migration would freeze feature work for months
and still miss the runtime failures that tests and Sentry catch.

## Decision

- **Backend contracts:** strong params at controllers; service objects
  with explicit `pattr_initialize` / keyword args; validations on models;
  no silent `rescue StandardError`. That is the type system we enforce.
- **Do not** add Sorbet or convert the monolith to TypeScript as a
  stability project.
- **Frontend:** keep JS + PropTypes. NewRelay UI stays in the existing
  Vue SFC style. If a new isolated package is written in TS, `any` is
  forbidden there.
- **Revisit** only if we extract a greenfield TS service.

## Consequences

"No any" is satisfied today because Ruby has no `any`. Stability comes
from specs on trust boundaries, not from a type-checker we do not run.
