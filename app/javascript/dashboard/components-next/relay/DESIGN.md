# Relay / new-ui Design System

Source of truth for **new dashboard UI** work. Visual reference: `/Users/deependrasankhala/Documents/chandresh/NewRelay-UI` (Geist + shadcn tokens). Runtime tokens live in `app/javascript/dashboard/assets/scss/_relay-theme.scss`. Color mapping: [TOKENS.md](./TOKENS.md).

When building or migrating a Vue page/component under the Relay shell (`[data-relay]`), follow this guide. Prefer Relay primitives over legacy dashboard widgets.

---

## Hard rules

1. **Composition API** — `<script setup>` only.
2. **Tailwind only** — no scoped CSS, no inline `style=`, no custom CSS files for new UI.
3. **Semantic tokens** — use `bg-background`, `text-foreground`, `bg-primary`, `border-input`, `text-muted-foreground`, `bg-sidebar`, etc. Never hardcode hex / invent purple/indigo one-offs (`bg-[#4f46e5]`, `bg-violet-*`). Primary is already indigo `#4f46e5` / dark `#4F46E5` via CSS vars.
4. **Relay primitives** — `RelayButton`, `RelayInput`, `RelayTextarea`, `RelayLabel`, `RelayCheckbox`, `RelaySwitch`, `RelayBadge`, `RelayTabs*` from `dashboard/components-next/relay`. Do **not** use legacy `Button` / `Input` / form chrome for new Relay pages.
5. **i18n** — no bare strings in templates; update **EN only** (`en.json` / `en.yml`).
6. **Icons** — Lucide via Uno/iconify classes (`i-lucide-*`) or existing icon patterns. Size with `size-4` / `size-5`; inherit `currentColor`.
7. **Dark mode** — class-based (`.dark` on `<html>`). Prefer token colors that auto-flip; avoid `dark:` color overrides unless a one-off is required.
8. **AI product name** — user-facing copy: **Relay AI** (not “Captain” in new UI strings).

---

## Typography & font

| Role | Value |
| --- | --- |
| Sans | Geist (`--font-sans`) |
| Mono | Geist Mono (`--font-mono`) |
| App header title | `text-base font-medium` |
| Page H1 (in-page title) | `text-base font-medium tracking-tight text-foreground` (`text-[16px] font-medium`) |
| Card / block title | `text-base font-semibold text-foreground` |
| Body / help | `text-[13.5px]` or `text-sm` + `text-muted-foreground` |
| Form label | `text-[13.5px] font-medium` (`RELAY_FORM_LABEL_CLASS`) |
| Table header (settings lists) | `text-[14px] font-medium text-muted-foreground` — not uppercase |
| Table header (autoresponder automations / AR notifications) | `text-[12px] font-medium text-muted-foreground` |
| Empty-state title | `text-[20px] font-[600] text-foreground` — **sharp**, no `drop-shadow`, blur, or hover tooltip on the title unless product explicitly asks |

Antialiasing is applied on `[data-relay]` via `_relay-theme.scss`.

---

## Color tokens (use these class names)

Full hex + dark values: [TOKENS.md](./TOKENS.md) and `_relay-theme.scss`.

| Purpose | Tailwind |
| --- | --- |
| Page / shell bg | `bg-background` |
| Default text | `text-foreground` |
| Secondary text | `text-muted-foreground` |
| Muted surface | `bg-muted` |
| Cards | `bg-card`, `border-border` / `border-border/60` |
| Primary CTA | `bg-primary text-primary-foreground` |
| Borders / inputs | `border-border`, `border-input` |
| Focus ring | `focus-visible:ring-1 focus-visible:ring-primary/30` on inputs/textareas/search (see `relay/form/constants.js`); `ring-ring` for non-form chrome |
| Destructive | `bg-destructive text-destructive-foreground` / `text-destructive` |
| Sidebar | `bg-sidebar`, `text-sidebar-foreground`, `border-sidebar-border`, active `text-sidebar-primary` |
| Soft elevation | `shadow-xs` (not heavy multi-layer shadows) |

Legacy `n-*` utilities (`bg-n-background`, `text-n-brand`) are bridged inside `[data-relay]` — prefer the semantic names above for new code.

---

## Page shell

### Standard content page (lists, FAQs, settings content)

```html
<div class="mx-auto flex h-full w-full max-w-7xl flex-col p-6 lg:px-10">
  <!-- header row: no border-b on inner page headers -->
  <!-- body -->
</div>
```

- Padding: **`p-6 lg:px-10`**, width **`max-w-7xl mx-auto`**.
- **Inner page headers do not use `border-b`.** Separation is spacing (`mb-6`, `space-y-*`), not a rule under the title.
- Optional enter motion: `animate-in fade-in duration-300` when matching new-ui.

### App chrome header (`RelayHeader`)

- Sticky bar: `h-16`, **`border-b border-border`**, `bg-background`, `px-4 py-3 sm:px-6`.
- Center search trigger: `h-10 max-w-md rounded-full border border-input shadow-xs`.
- Icon actions (theme, notifications): **`size-9 rounded-full border border-input shadow-xs`**, hover `hover:border-transparent hover:bg-accent`.

### Relay AI / Captain pages

Use `dashboard/components-next/captain/PageLayout.vue`:

- Shell already applies `max-w-7xl` + `p-6 lg:px-10` + `bg-background`.
- Header: assistant switcher + vertical divider (`h-5 w-px bg-border`) + muted page title.
- Primary action: `RelayButton` `h-9` with plus icon.
- Slots: `search`, `emptyState`, `body`, `controls`, `paywall`.

---

## Component patterns

### Imports

```js
import {
  RelayButton,
  RelayInput,
  RelayLabel,
  RelayCheckbox,
  RelaySwitch,
  RelayBadge,
  RelayTabs,
  RelayTabsList,
  RelayTabsTrigger,
  RelayTabsContent,
} from 'dashboard/components-next/relay';
```

### RelayButton

| Variant | Use |
| --- | --- |
| `default` | Primary CTA — `bg-primary … shadow-xs` |
| `outline` | Secondary — `border-input … shadow-xs`; hover clears border |
| `secondary` / `ghost` / `link` / `destructive` | As named |
| Sizes | `default` `h-9`, `sm` `h-8`, `lg` `h-10`, `icon` `size-9` |

**Ghost / transparent buttons** that need a visible edge: add `border border-input` (or `border-border`) and `hover:border-transparent`.

### RelayInput

Default: `h-9 rounded-md border border-input bg-background shadow-xs text-sm`.

**Search field pattern:**

```html
<div class="relative w-full sm:w-64">
  <span class="i-lucide-search absolute left-2.5 top-2.5 size-4 text-muted-foreground" />
  <RelayInput
    v-model="query"
    :placeholder="t('…')"
    class-name="h-9 pl-9 bg-background"
  />
</div>
```

### RelayLabel

`text-sm font-medium leading-none`. In dense forms / modals prefer `text-[13.5px] font-medium text-foreground`.

### RelayCheckbox / RelaySwitch

Both ship with **`p-0`** so legacy global `button { padding }` does not crush `size-4` / `h-5 w-9`. Do not remove `p-0`. Checkbox row: `flex items-center gap-3` (no manual `mt-0.5` on the control).

### RelayBadge / Tabs

- Badge: compact `text-xs`, variants `default | secondary | destructive | outline`.
- **Pill tabs** (`RelayTabs`): list `bg-muted … h-9 rounded-lg p-1`; active trigger `bg-background shadow-sm`.
- **Underline tabs** (Inbox status, list filters, entity details): list `flex gap-6 border-b border-border`; inactive `text-muted-foreground hover:text-foreground`; active text `text-foreground`; indicator `absolute inset-x-0 bottom-0 h-px bg-primary` (**1px**, never `h-0.5` or `border-b-2` on `<button>`). See `.cursor/rules/relay-underline-tabs.mdc`.

### Inbox / nested list chrome

Locked Inbox QA (do not invent a second pattern):

| Piece | Class / behavior |
| --- | --- |
| Section label (Views, Channels) | `text-xs font-bold uppercase tracking-wider text-muted-foreground` |
| Count badge | `h-5 min-w-[20px] px-1.5 rounded-full text-[11px] font-semibold` |
| Website channel | `i-lucide-globe` — not `message-circle` |
| Tab-row bulk action | **Select All** / Deselect All text (`RelayButton` ghost `h-8 text-xs`). No icon-only cluster. Selected rows → Mark all as read + Delete |
| Display chevron | `size-3.5` (match section chevrons) |
| Filter / sliders icon | `size-[18px]` |
| Star | `InboxStarIcon` — same SVG outlined and filled; starred `text-amber-400` |
| Row channel glyph | Well `size-5 rounded-full bg-primary/10 text-primary`; icon `size-3.5` |

Reference: `routes/dashboard/inbox/`, `components-next/Inbox/`. Agent rule: `.cursor/rules/relay-inbox-chrome.mdc`.

### Resetting legacy form chrome

Inside Relay pages, prefer Relay controls. If a native `<input>` / `<button>` is unavoidable, mirror Relay classes (`border-input`, `h-9`, `shadow-xs`, `rounded-md`) and reset padding (`p-0` on checkbox-like controls).

---

## Layout patterns

### Sidebar (`RelaySidebar` / AppSidebar)

- Width: expanded `w-60`, collapsed `w-16`.
- Surface: `bg-sidebar text-sidebar-foreground border-r border-sidebar-border`.
- Brand block: primary square logo + name + muted subtitle.
- Nav item: `rounded-md p-2 gap-3 text-sm`; icons `size-4` stroke muted; **active**: `text-sidebar-primary` + left bar (`before:… bg-sidebar-primary`) when expanded; collapsed active uses soft `bg-sidebar-primary/10`.
- Nested: left border rail `border-l border-sidebar-border pl-5`.
- Collapsed: tooltips / hover cards for labels.

### Settings (side accordion + cards)

From new-ui `SettingsView`:

- Shell: `p-4 sm:p-8` → inner `max-w-7xl` row: **left nav `lg:w-56`** + **content `max-w-3xl` / `max-w-4xl`**.
- Accordion section headers: muted, `rounded-lg`, chevron; one section open at a time.
- Sub-items: `border-l` rail; active item `bg-muted text-foreground` + primary dot on the rail.
- **Cards:** `border border-border/60 bg-card rounded-xl shadow-xs overflow-hidden`.
  - Card header: `p-4 sm:p-6 border-b border-border/40` + optional icon in `size-10 rounded-lg bg-primary/10`.
  - Card body: padded form fields; footer actions often `border-t border-border/40`.

### List / toolbars

- Title left, search + primary CTA right (`flex … justify-between gap-4 mb-6`).
- Bulk selection bar: `rounded-xl border border-border bg-card shadow-xs p-3 px-4`.

### Empty states

Prefer sharp, calm empty states (`PremiumEmptyState` pattern):

- Icon in `size-16 rounded-full bg-primary/10 ring-8 ring-primary/5`.
- Title `text-[20px] font-[600]` — **no** drop-shadow / backdrop-blur on title/copy unless intentional product flourish.
- Description `text-sm text-muted-foreground max-w-md`.
- Primary + outline secondary (`border-input shadow-xs`).

Dev-only “show working state” toggles are fine in prototypes; do not ship them to production.

### Modals / header

- Header wrapper: `RELAY_MODAL_HEADER_CLASS` — `flex shrink-0 items-start justify-between p-6` (no `border-b`; NewRelay Agent/Label/Role use spacing, not a rule). **Add Bot** is the exception: `RELAY_MODAL_HEADER_PLAIN_CLASS` uses `border-b border-border/40` with `px-8 py-6`.
- Title: `text-base font-medium tracking-tight text-foreground` (`RELAY_MODAL_TITLE_CLASS`).
- Description under title: `text-[14px] font-normal leading-normal text-muted-foreground` (`RELAY_MODAL_DESCRIPTION_CLASS`).
- Form body follows the header (`p-6` or flush `px-6`/`px-7`). Footer uses `border-t border-border/40` when actions sit on a bar.

### Modals / forms

- Field stack: `flex flex-col gap-1.5` (`RELAY_FORM_FIELD_CLASS`).
- Label: `text-[13.5px] font-medium leading-normal text-foreground` (`RELAY_FORM_LABEL_CLASS`). Override global `leading-7` on `<label>` with `leading-normal` — avoid `leading-none` (too tight) and bare labels (too loose).
- Input / textarea / search: `text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30` — use `RelayInput`, `RelayTextarea`, or `RELAY_FORM_INPUT_CLASS` from `relay/form/constants.js`. No browser default outlines or hardcoded hex focus colors.
- Checkbox + label row: `flex items-center gap-3` (`RELAY_FORM_CHECKBOX_ROW_CLASS`). Do not use manual top margins (e.g. `mt-0.5`) to align checkboxes.
- Primary submit stays **disabled** until required fields are valid.

### Overlays

Use existing `anim-pop` / `anim-overlay` classes from `_relay-theme.scss` for open/close (match new-ui reka-ui motion).

---

## Do / Don’t

| Do | Don’t |
| --- | --- |
| `bg-primary`, tokens from `_relay-theme.scss` | Random purple themes or screenshot hex dumps |
| `RelayButton` / `RelayInput` | Legacy dashboard Button/Input on new pages |
| Inner pages: spacing only | `border-b` under every page h1 |
| App header: `border-b` | Borderless sticky chrome |
| `shadow-xs` | Heavy glow / multi-shadow stacks |
| Sharp empty titles | Default drop-shadow + blur + title tooltips |
| `en.json` only for new copy | Editing every locale file |
| Inbox section labels uppercase `font-bold` | `font-medium` title-case “Views” |
| Select All text on Inbox tab row | Icon-only cluster next to New / In Progress |

---

## Checklist for a new page

1. Wrap content in `max-w-7xl` + `p-6 lg:px-10` (or `PageLayout` for Relay AI).
2. Header row without `border-b`; actions use Relay controls.
3. Search = icon + `pl-9` + `h-9`.
4. Colors only from semantic tokens; verify light **and** dark.
5. Strings via i18n (EN).
6. No scoped CSS.
7. Match an existing sibling page (Settings card, FAQs list, or PageLayout) before inventing a new layout.

---

## File map

| Path | Role |
| --- | --- |
| `components-next/relay/*` | Primitives + shell |
| `components-next/captain/PageLayout.vue` | Relay AI page template |
| `assets/scss/_relay-theme.scss` | CSS variables + `[data-relay]` bridge |
| `tailwind.config.js` | Maps vars → Tailwind color keys |
| `TOKENS.md` | Token ↔ class quick reference |
| `.cursor/rules/relay-new-ui-design.mdc` | Agent enforcement |
| `.cursor/rules/relay-underline-tabs.mdc` | 1px underline tab indicator |
| `.cursor/rules/relay-inbox-chrome.mdc` | Inbox nested-list chrome |
