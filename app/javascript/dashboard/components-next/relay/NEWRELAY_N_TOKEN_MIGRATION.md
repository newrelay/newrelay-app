# `n-*` → Relay semantic token migration map

Reviewed mapping for retiring the legacy `n-*` design tokens in favour of the
Relay semantic tokens. **Read this before migrating any area.** Pairs with
`TOKENS.md` (semantic token reference) and `NEWRELAY_PORTING_MAP.md`.

## Why this is not a blind rename

`n-*` classes render *today* — `n` is a real palette namespace in
`theme/colors.js`, backed by Radix CSS vars (`--slate-12`, `--blue-9`, …).
The Relay semantic tokens (`--foreground`, `--primary`, …) are **separate**
vars defined in `_relay-theme.scss`. So most maps **change the rendered
colour**. Scope: **5,278 usages** across `dashboard/` (excl. `relay/`).

`_relay-theme.scss` already **bridges** a handful of legacy vars to the new-ui
values inside `[data-relay]` (`--slate-12`, `--background-color`, `--card-color`,
`--border-strong/weak`, `--solid-*`, `--surface-*`, `--woot-brand`). Those maps
are **exact** (zero visual change). Everything else is a real recolour.

## Confidence tiers

- **A — Exact.** Backed by identical values (bridged in `_relay-theme.scss`). Safe to auto-migrate.
- **B — Intent.** Neutral/surface tokens; minor shade shift. Migrate per-area, eyeball once.
- **C — Recolour.** Deliberate design change (e.g. old blue brand → indigo `primary`). Needs your sign-off before running — a wrong map hits thousands of sites.

## Mapping

### Tier A — Exact (safe)
| `n-*` token | Uses | → semantic | Note |
|---|---|---|---|
| `n-slate-12` | 479 | `foreground` | `--slate-12` bridged = `--foreground` |
| `n-background` | 170 | `background` | `--background-color` = `--background` |
| `n-brand` | 89 | `primary` | `--woot-brand` = `--primary` |
| `n-card` | 5 | `card` | `--card-color` = `--card` |
| `n-solid-1` | 37 | `card` | `--solid-1` = `--card` |
| `n-surface-2` | 7 | `card` | `--surface-2` = `--card` |
| `n-weak` | 202 | `border` | `--border-weak` = `--border` (light exact; dark ≈) |
| `n-strong` | 100 | `border` | `--border-strong` = `--border` (light exact; dark ≈) |

### Tier B — Intent (neutral / surface; review per area)
| `n-*` token(s) | Uses | → semantic | Note |
|---|---|---|---|
| `n-slate-11`, `n-gray-11` | 455 | `muted-foreground` | secondary text |
| `n-slate-10` | 109 | `muted-foreground` | secondary text (lighter) |
| `n-slate-9` | 44 | `muted-foreground` | mid gray text/icon |
| `n-slate-1`, `n-slate-50` | 22 | `background` | app canvas |
| `n-slate-2`, `n-slate-3` | 124 | `muted` | subtle surface / hover |
| `n-slate-4`, `n-slate-5` | 48 | `muted` / `accent` | hover / active surface |
| `n-slate-6`, `n-slate-7`, `n-slate-8` | 63 | `border` | Radix steps 6–8 = borders/inputs → `border` / `input` |
| `n-gray-12` | 2 | `foreground` | alias of slate-12 |
| `n-gray-10` | 2 | `muted-foreground` | |
| `n-solid-2` | 24 | `secondary` | light=card / dark=secondary |
| `n-solid-3` | 32 | `accent` | active/selected surface |
| `n-surface-1` | 34 | `muted` | subtle panel |
| `n-container` | 28 | `card` | container surface |
| `n-alpha-1` | 33 | `muted` | subtle overlay |
| `n-alpha-2` | 103 | `accent` | hover overlay |
| `n-alpha-3` | 54 | `accent` | stronger hover/active |
| `n-alpha-black1/2` | 62 | `bg-black/5`, `bg-black/10` | dark overlay/backdrop (per-use opacity) |
| `n-alpha-white` | 3 | `bg-white/10` | light overlay (per-use opacity) |
| `n-black` | 2 | `foreground` or `bg-black` | pure black — check intent |
| `n-input-background` | 1 | `background` | field surface |
| `n-label-color` / `n-label-border` | 2 | `foreground` / `border` | |

### Tier C — Recolour (design sign-off required)
| `n-*` token(s) | Uses | → semantic | Note |
|---|---|---|---|
| **`n-blue-9`** | **2502** | `primary` | ⚠️ **old brand blue → indigo `primary`**. Biggest single change; confirm before running. |
| `n-blue-11`, `n-blue-text` | 80 | `primary` | brand text |
| `n-blue-10` | 6 | `primary` | |
| `n-blue-1…8, 12`, `n-blue-border` | ~20 | `primary` (+ opacity for tints) | tints → `primary/10`, `primary/20`, `ring` for border |
| `n-button-color`, `n-solid-blue`, `n-solid-active` | 6 | `primary` | brand action |
| `n-ruby-9` | 64 | `destructive` | danger fill |
| `n-ruby-11` | 35 | `destructive` | danger text |
| `n-ruby-2…8, 10, 12` | ~40 | `destructive` (+ opacity for tints) | |
| `n-red-9` | 2 | `destructive` | |
| `n-teal-9…12` | 63 | `success` | success fill/text |
| `n-teal-2…7` | ~20 | `success` (+ opacity for tints) | |
| `n-amber-9…12` | 33 | `warning` | warning fill/text |
| `n-amber-2…7` | ~30 | `warning` (+ opacity for tints) | |
| `n-iris-9`, `n-violet-9` (+ tints) | ~20 | `primary` / `accent` | purple accents |

## Recommended execution order

1. **Tier A first** — 8 tokens, ~919 usages, exact values. Lowest risk; can be a
   single scripted pass, spot-checked.
2. **Tier C brand decision** — confirm `n-blue-9 → primary` (2502×). Once approved,
   the blue family is mechanical.
3. **Tier C status colours** — ruby→destructive, teal→success, amber→warning.
   Watch the tint steps (2–8): those need an opacity suffix, not a flat token.
4. **Tier B neutrals** — slate/solid/surface/alpha, migrated **per component area**
   with a visual pass each. This is where blanket sed is unsafe (shade nuance,
   hover states, opacity).

## Do NOT blanket-migrate
- **Tint/alpha steps** (`n-*-2…8`, `n-alpha-*`) — map to a base token **plus an
  opacity suffix** decided per use, not a flat semantic token.
- Anything where the `n-*` step encodes a hover/active state — verify the
  interactive states still read correctly after the swap.
