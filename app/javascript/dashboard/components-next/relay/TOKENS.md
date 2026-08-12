# Relay token mapping (new-ui → Chatwoot)

Canonical values live in `app/javascript/dashboard/assets/scss/_relay-theme.scss` (ported from new-ui `src/style.css`).  
**Patterns & layout rules:** [DESIGN.md](./DESIGN.md).

Inside `[data-relay]`, prefer semantic Tailwind classes (`bg-primary`, `border-input`, …). Legacy `n-*` classes are bridged to the same surfaces for nested pages.

## Semantic → Tailwind

| Role | Tailwind class | CSS variable |
| --- | --- | --- |
| Page background | `bg-background` | `--background` |
| Default text | `text-foreground` | `--foreground` |
| Card surface | `bg-card` / `text-card-foreground` | `--card` |
| Popover | `bg-popover` / `text-popover-foreground` | `--popover` |
| Primary / brand | `bg-primary` / `text-primary` | `--primary` (`#4f46e5` light / `#4F46E5` dark) |
| On-primary | `text-primary-foreground` | `--primary-foreground` |
| Secondary | `bg-secondary` / `text-secondary-foreground` | `--secondary` |
| Muted surface / text | `bg-muted` / `text-muted-foreground` | `--muted` |
| Accent (hover chips) | `bg-accent` / `text-accent-foreground` | `--accent` |
| Destructive | `bg-destructive` / `text-destructive-foreground` | `--destructive` |
| Border | `border-border` | `--border` |
| Input border | `border-input` | `--input` |
| Focus ring | `ring-ring` / `focus-visible:ring-ring` | `--ring` |
| Sidebar | `bg-sidebar` / `text-sidebar-foreground` | `--sidebar` |
| Sidebar accent | `bg-sidebar-accent` / `text-sidebar-accent-foreground` | `--sidebar-accent` |
| Sidebar primary (active) | `text-sidebar-primary` / `bg-sidebar-primary` | `--sidebar-primary` |
| Sidebar border / ring | `border-sidebar-border` / `ring-sidebar-ring` | `--sidebar-border` / `--sidebar-ring` |
| Success / warning | `text-success` / `text-warning` | `--success` / `--warning` |
| Charts | `bg-chart-1` … `bg-chart-5` | `--chart-1` … `--chart-5` |

## Soft shadow

| Token | Tailwind | Notes |
| --- | --- | --- |
| Extra-small elevation | `shadow-xs` | Matches Tailwind v4 / shadcn; configured in `tailwind.config.js` |

## Legacy bridge (prefer semantic names above)

| new-ui / semantic | Older Chatwoot utility (bridged under `[data-relay]`) |
| --- | --- |
| `bg-primary` / `text-primary` | `bg-n-brand` / `text-n-brand` |
| `text-primary-foreground` | `text-white` |
| `bg-destructive` | `bg-n-ruby-9` |
| `text-destructive-foreground` | `text-white` |
| `bg-secondary` | `bg-n-alpha-2` |
| `text-secondary-foreground` | `text-n-slate-12` |
| `bg-background` | `bg-n-background` |
| `text-foreground` | `text-n-slate-12` |
| `text-muted-foreground` | `text-n-slate-11` |
| `border-input` / `border` / `border-border` | `border-n-weak` |
| `bg-accent` / hover accent | `bg-n-alpha-2` |
| `bg-muted` | `bg-n-alpha-1` |
| `ring-ring` | `ring-n-brand` |
| `bg-sidebar` | `bg-n-solid-1` |
| `border-sidebar-border` | `border-n-weak` |
| `text-sidebar-foreground` | `text-n-slate-12` |
| `bg-sidebar-accent` | `bg-n-alpha-2` |
| `text-sidebar-primary` | `text-n-brand` |

## Light / dark hex (reference)

| Token | Light | Dark (`.dark`) |
| --- | --- | --- |
| `--background` | `#ffffff` | `#10141d` |
| `--foreground` | `#141822` | `#fafafa` |
| `--primary` | `#4f46e5` | `#4F46E5` |
| `--muted` | `#f2f4f9` | `#242933` |
| `--muted-foreground` | `#6c727e` | `#9ba2ae` |
| `--border` | `#e4e7ee` | `#ffffff1a` |
| `--input` | `#e4e7ee` | `#ffffff26` |
| `--sidebar` | `#f9fafd` | `#181d27` |
| `--radius` | `0.75rem` | same |

Do **not** invent alternate purple palettes — use these indigo primary tokens.
