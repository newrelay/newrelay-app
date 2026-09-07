---
name: merging-upstream-chatwoot
description: >-
  Use when pulling a new upstream Chatwoot release/version into this fork —
  "sync with upstream", "merge chatwoot update", "upgrade chatwoot version",
  "bring in the new chatwoot release", or any git fetch/merge against the
  `chatwoot-upstream` remote. Also use before touching `vendor/chatwoot-*`,
  `upgrade/*-merge*` branches, or resolving conflicts between fork
  customizations and upstream code.
---

# Merging upstream Chatwoot

## Why this isn't a plain `git merge`

`main` / `feature/ui-changes` (the active line) has **squashed, disjoint
history** — it shares no common ancestor with real upstream Chatwoot
(`git merge-base` returns nothing). A direct `git merge chatwoot-upstream/main`
on this line cannot 3-way merge; it will conflict-storm every file.

`vendor/chatwoot-<version>` branches carry **real upstream ancestry** (they
trace back to Chatwoot's actual initial commit) and are the only valid merge
base. Always merge upstream onto a vendor branch first, then bring that
result into the fork.

## Recipe

1. `git fetch chatwoot-upstream --tags`. Diff `v<current>..chatwoot-upstream/v<new>`
   to scope what's new.
2. Branch a new vendor ref from the **existing** vendor branch (don't recreate
   from scratch): `git checkout -b vendor/chatwoot-<new> vendor/chatwoot-<current>`,
   then `git merge chatwoot-upstream/v<new>`. This is a real 3-way merge —
   upstream-only files apply cleanly.
3. Regenerate version-derived artifacts on top as a follow-up commit:
   `bundle install`, `db/schema.rb`, `Gemfile.lock`, `pnpm-lock.yaml`, swagger docs.
4. Merge the updated vendor branch into a new integration branch cut from the
   **current** active tip: `git checkout -b upgrade/<new>-merge feature/ui-changes`
   → `git merge vendor/chatwoot-<new>`. Resolve conflicts by policy (below).
   Keep it a real merge commit — never squash to one parent; that's how the
   last attempt (`upgrade/4.17.1-merge-v2`) silently detached from
   `feature/ui-changes` and was never reconciled back in.
5. Write the ledger: copy the structure of
   `docs/solution-notes/chatwoot-4.17.1-upgrade-comparison.md` into a new
   `docs/solution-notes/chatwoot-<new>-upgrade-comparison.md` — kept-ours /
   adopted-upstream / bugs-found-during-merge / deliberate-gaps tables. This
   is the only durable record of *why* a conflict was resolved one way; the
   diff alone doesn't explain intent.
6. **Audit third-party UI npm packages for style drift.** Upstream bumps
   packages like `floating-vue`, `vue-datepicker-next`, `vuedraggable` on its
   own schedule. These ship their own CSS and render with the package's
   default look, not Relay's — they don't pick up Relay tokens automatically
   the way Chatwoot's own `.vue` components do. Diff `package.json` for
   version bumps or new UI deps, then visually check anything that renders
   (tooltips, popovers, datepickers, drag handles, emoji pickers) against the
   Relay reference at localhost:5174. Override drift by targeting the
   package's own class names (e.g. `.v-popper__inner`, `.dp__theme_light`,
   `.sortable-ghost`) in `_relay-theme.scss` — see [[newrelay-port]] for the
   token system; this is not a component swap, it's a CSS override of a
   library you don't control the markup of.
7. `bundle exec rubocop -a`, `pnpm eslint:fix`, run full Ruby + JS suites,
   smoke-test Relay-ported pages by hand (upstream restructuring
   `components-next/` is the most common source of silent breakage).
8. Merge `upgrade/<new>-merge` into `feature/ui-changes` as its own PR —
   never fold it into unrelated feature work.

## Conflict-resolution policy

| Situation | Resolution |
|---|---|
| Upstream touched a file the fork heavily customized (Relay design, enterprise overlay, billing, custom roles) | Keep the fork's version; re-skin any *new* upstream feature onto the Relay design system rather than importing upstream's raw markup/tokens. |
| Upstream shipped a genuinely new feature with no fork equivalent | Adopt it, then port it through Relay components per [[newrelay-port]] conventions. |
| Fork and upstream both fixed the same latent bug differently | Diff both fixes — 3-way merges routinely surface real bugs (undefined store getters, dead code, missing plugin registration); don't assume "ours" is correct by default. |
| Feature collides with fork-specific UI (e.g. custom sidebar chrome) | Leave unported, log it in the ledger's "deliberate gaps" table for a follow-up decision — don't silently drop it. |
| Upstream bumped a third-party UI package (tooltip/popover, datepicker, drag list, emoji picker, etc.) | Take the version bump, but re-check its rendered output against Relay tokens (step 6) — a clean merge here can still ship visual regressions since these packages carry their own CSS. |

## Known state (check before starting)

- `feature/ui-changes-4.17.1` (the completed 4.17.1 upgrade, tip `76a2c1747`)
  diverged from the current `feature/ui-changes` tip at `b06cdb09b` and was
  **never merged back** — reconcile that first, or the next upgrade compounds
  the drift. Check `git merge-base feature/ui-changes feature/ui-changes-4.17.1`
  before assuming either branch is current.
- `upgrade/4.17.1-merge` (v1) faked shared ancestry with synthetic graft
  commits — fragile, do not reuse this technique.

## Quick reference

- Upstream remote: `chatwoot-upstream` → `github.com/chatwoot/chatwoot`
- Fork remote: `origin` → `auzadev/DakshAI`
- Real-ancestry base: `vendor/chatwoot-4.17.1`
- Ledger template: `docs/solution-notes/chatwoot-4.17.1-upgrade-comparison.md`
- Enterprise-overlay checklist: see CLAUDE.md § Enterprise Edition Notes —
  run it during step 4/6 conflict resolution, not as an afterthought.
- No `patch-package`/patches infra exists yet for third-party UI packages —
  overrides live in `_relay-theme.scss` by class name (step 6). Known
  UI-rendering deps in `package.json` today: `floating-vue`,
  `vue-datepicker-next`, `vuedraggable`.
