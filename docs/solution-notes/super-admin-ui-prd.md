# PRD — Super Admin UI visual match

**Status:** Draft · **Owner:** Super Admin UI · **Last updated:** 2026-08-24
**Source of truth (visual):** [https://super-admin-ui-one.vercel.app/](https://super-admin-ui-one.vercel.app/)
**Companion:** `ADMIN_UI_DEV.md`

This is a **visual-parity** PRD, not a new-feature PRD. The Vercel mock is the pixel
target. Super Admin already has layout, tokens, and many pages. The job is to make
every live `/super_admin` screen look and behave like that mock, without changing
backend contracts.

---

## 1. Problem & Goal

Instance operators use Super Admin (`/super_admin`) to manage accounts, users,
billing, plans, and platform config. A new design exists as a static prototype.
Some of that design is already in this repo (sidebar, header, tokens, dashboard
Vue, collection tables). What is live today still mixes:

- Design-system pages (Dashboard, Users list, Accounts list)
- Administrate leftovers (native `<select>`, hardcoded hex, `slate-*` / `violet-*`)
- Pages that never got the new kit (Account Hierarchy, payment gateway country
  tags, some notice banners)

**Goal:** a Super Admin who opens our app cannot tell it apart from
`super-admin-ui-one.vercel.app` on layout, color, type, tables, forms, modals,
empty states, and navigation. Data stays real. No mock CRUD.

**Who:** Super Admin operators (internal). Not tenant dashboard users.

**Done when:** every screen in §4 passes the visual checklist in §8 against the
Vercel mock at desktop (1280+) and collapsed sidebar. Dark mode matches the mock
`.dark` tokens.

---

## 2. Source of truth

| Kind | Source | Rule |
|---|---|---|
| Visual | https://super-admin-ui-one.vercel.app/ | If our screen disagrees with the mock, the mock wins. |
| Tokens | Mock CSS vars **and** `app/javascript/dashboard/assets/scss/super_admin/index.scss` | They already match. Do not invent new hex. |
| Behavior / APIs | Existing Rails Super Admin + Administrate | Do not add mock-only CRUD. Wire real endpoints. |
| Copy | Mock labels (English) | Match page titles, button labels, empty-state text. |

The mock is a single HTML/JS prototype (`script.js` + page containers). It is
**not** a Vue rewrite target. Keep Administrate ERB + Tailwind + the existing
`super_admin/index.scss` kit.

Mock comment in `script.js`: *"Faithful replication of Design-System-NR
patterns."* Our SCSS already names the same classes (`sidebar-menu-btn`,
`page-title`, `table-card`, `nr-select`, `feature-flag-card`). Finish that kit
on every page; do not start a second design system.

---

## 3. Current state (audited 2026-08-24)

### Already in place (keep, polish)

| Piece | File(s) | Match vs mock |
|---|---|---|
| Color / type tokens | `super_admin/index.scss` `:root` / `.dark` | **Same hex** as the live mock (`--primary: #4f46e5`, `--sidebar: #f9fafd`, Geist, radius `0.75rem`) |
| App chrome | `layouts/super_admin/application.html.erb`, `_navigation.html.erb`, `_header.html.erb` | Shell is the same: 240px sidebar, brand card, ⌘K search pill, theme toggle, notifications, user pill |
| Dashboard | `dashboard/index.html.erb` + `superadmin_pages/views/dashboard/Index.vue` | Same 4 stat cards + Conversation Activity chart. Extra Avg / Trend stats in our Vue vs mock header (mock shows Total + Peak). Align to mock. |
| Collection index | `application/index.html.erb`, `_collection.html.erb`, `_filters.html.erb`, `_search.html.erb` | Table card, sort icons, filter dropdown, search field, New button, row edit/delete icons |
| Show / New / Edit shells | `application/show.html.erb`, `new.html.erb`, `edit.html.erb`, `_form.html.erb` | Card + field grid exists. Native selects and hex hover borders remain. |
| Feature flag cards | `views/fields/enterprise_features_field/_form.html.erb` + SCSS `.feature-flag-card` | Pattern exists. Show page still uses key/value rows instead of read-only flag cards. |
| Custom select kit | SCSS `.nr-select` + mock `initCustomSelects()` | CSS exists. Most ERB forms still render native `<select>`. |
| Sign-in | `devise/sessions/new.html.erb` | Mock has **no login**. Keep ours; it already uses tokens. |
| Settings / plan / push / inquiries | respective `show.html.erb` / `index.html.erb` | Structure exists; leftover `green-*` / `violet-*` / `slate-*` classes. |

### Hard gaps (must fix)

| Gap | Where | Why it fails the mock |
|---|---|---|
| Hardcoded hex | Many ERB files: `hover:border-[#cac7f7]` | Mock uses `var(--ring)` / `var(--focus-border)`. Hardcoded hex also breaks dark mode. |
| Hardcoded Tailwind palette | Hierarchy, notices, Discord CTA, payment tags | `slate-*`, `violet-*`, `green-50`, `bg-violet-600` are forbidden. Use `border-border`, `bg-primary`, `text-success`, `bg-destructive/10`. |
| Native `<select>` | Forms, filters, account-user role, payment gateways | Mock replaces every select with `.nr-select` (trigger + menu + check). Native OS popups are out. |
| Account Hierarchy | `enterprise/app/views/super_admin/account_hierarchy/show.html.erb` | Still `main-content__page-title` + `border-slate-*`. Mock has page subtitle, search, and design-system cards. |
| Sidekiq placement | `_navigation.html.erb` footer vs mock main list | Mock puts Sidekiq in the **main** nav (external-link icon), not the footer. Footer is Settings + Log Out. |
| Delete confirm | Administrate `data-confirm` browser dialog | Mock uses a custom delete modal (`#deleteConfirmModal`: title, item name, Keep / Delete). |
| Toasts | Flash partial only | Mock uses a toast container for success after save. Keep flashes **and** add the toast for in-page actions that do not redirect. |
| Command palette results | `_search_modal.html.erb` | Mock lists jump-to pages with label + description + Jump chip. Ours is a placeholder. |
| Empty table | `_collection.html.erb` | Mock empty state is a boxed icon + "No {Resource} found." Match icon size, muted color, padding. |
| Chart | Dashboard Vue vs mock canvas | Mock: spline canvas, `#5b5bd6` / `#7373f7` dark, 45° x labels, hover tooltip, Total + Peak only. Ours: Chart.js line + Avg + Trend. Match mock chrome; keep real `@data`. |

---

## 4. Screen inventory (nothing dropped)

Legend — **Match** = already close · **Partial** = chrome/tokens yes, details no · **Gap** = still old kit.

### A. Shell (every page)

| # | Surface | Mock | Our file | State |
|---|---|---|---|---|
| A1 | Sidebar 240px, brand "N" + New Relay + Super Admin Console | yes | `_navigation.html.erb` | Match |
| A2 | Nav order + icons (Lucide 16px) | Dashboard, Accounts, Users, Agent Bots, Platform Apps, Platform Banners, Account Hierarchy, Enterprise Inquiries, Sidekiq (external), Instance Health, Push Diagnostics | same file | Partial — Sidekiq is footer; Cloudflare is extra (cloud-only, keep) |
| A3 | Accounts submenu tree | Enterprise Contracts, Subscriptions, Billing Activity Logs, Billing Coupons, Marketplace Plan Prices | same | Match |
| A4 | Hierarchy submenu | Plan Management, Payment Gateways | same | Match |
| A5 | Settings submenu | General, SAML SSO, Custom Branding, Relay AI, Email, Messenger, Instagram, TikTok, Google, Microsoft, Linear, Notion, Slack, WhatsApp Embedded, Shopify | `_settings_menu.html.erb` + `features.yml` | Match (driven by config_key) |
| A6 | Collapsed flyouts | card + header + links | `_navigation.html.erb` | Match |
| A7 | Header: panel toggle, ⌘K pill, theme, bell + red dot, user pill | yes | `_header.html.erb` | Match |
| A8 | Log Out in sidebar footer | yes | `_navigation.html.erb` | Match |
| A9 | Dark mode tokens | `.dark` on `<html>` | `index.scss` + `navigation_and_theme.js` | Match |
| A10 | Command palette | page jump list | `_search_modal.html.erb` | Gap — wire jump results to real Super Admin paths |
| A11 | Custom delete modal | Keep {Item} / Delete {Item} | none | Gap |

### B. Dashboard

| # | Surface | Mock | Our file | State |
|---|---|---|---|---|
| B1 | Title "Admin Dashboard" | yes | `Index.vue` | Match |
| B2 | 4 stat cards: icon in accent square, value, label | Accounts / Users / Inboxes / Conversations | same | Match |
| B3 | Conversation Activity card | title + subtitle; Total + Peak | same (also Avg + Trend) | Partial — drop Avg/Trend **or** keep if product wants them; default = **match mock** (Total + Peak only) |
| B4 | Chart line + fill + peak dot + rotated dates | canvas spline | Chart.js `LineChart` | Partial — restyle to mock series color, 2.2px stroke, tooltip |

### C. Collection index (all Administrate resources)

Shared layout: `page-header` (h1 left) + `page-actions` (filter, search, primary New).

| # | Page | Mock actions | Columns (mock) | Our state |
|---|---|---|---|---|
| C1 | Accounts | All records filter (Active / Suspended / Recent / Marked For Deletion), Search, **New account** | ID, Name, Locale, Users, Conversations, Status (green `active`) | Partial — New button exists; status color + filter labels must match |
| C2 | Users | Filter (All / Super Admin / Confirmed / Unconfirmed / Recent), Search, **New user** | Id, Name (avatar + name), Email, Accounts, Type | Partial — avatar cell exists in mock; confirm our Users collection shows avatar |
| C3 | Enterprise Contracts | New | per dashboard | Partial |
| C4 | Subscriptions | search | per dashboard | Partial |
| C5 | Billing Activity Logs | search | per dashboard | Partial |
| C6 | Billing Coupons | New | per dashboard | Partial |
| C7 | Marketplace Plan Prices | search | per dashboard | Partial |
| C8 | Agent Bots | Search, **New agent bot** | Id, Account (avatar), Name, Outgoing Url | Partial |
| C9 | Platform Apps | **New platform app** | Id, Name | Partial |
| C10 | Platform Banners | **New platform banner** | Id, Banner Message, Banner Type (badge), Active (badge), Created at | Partial |
| C11 | Empty | boxed inbox icon + "No {Name} found." | `_collection.html.erb` | Partial |

Row actions on hover: pencil + trash icon buttons (Users/Accounts). Some resources in the mock use **Edit** outline + **Delete** danger-soft text buttons (Agent Bots, Platform Apps). Match **per resource** as the mock does. Do not invent a third pattern.

### D. Show pages

| # | Page | Mock pattern | Our file | State |
|---|---|---|---|---|
| D1 | Account show | Back + title `Show #{id} {name}` + Edit. Attribute list. Feature flags as **read-only cards**. Account users table. Add-user form. Subscription card. Seed / reset / custom domain blocks. | `accounts/show.html.erb` | Partial — features still key/value rows |
| D2 | User show | Back + title. Attributes. Access token masked with eye + copy. Account-user table + add form. Impersonate caution + button. | `users/show.html.erb` | Partial |
| D3 | Generic show | Attribute sections in a card | `application/show.html.erb` | Partial |
| D4 | Subscription / coupon / contract / billing log show | same card pattern | Administrate show | Partial |

### E. New / Edit forms

| # | Pattern | Mock | Our file | State |
|---|---|---|---|---|
| E1 | Page header | Title left; Back + Show {resource} right | `new.html.erb`, `edit.html.erb` | Match structure |
| E2 | Form card | `rounded-xl border bg-card p-6/8` | same | Match |
| E3 | Fields | label 13.5px medium, input h-9, ring on focus | `_form.html.erb` | Partial — still native select |
| E4 | Account edit | Name, locale custom select, status custom select, feature-flag grids (Manually managed / Basic + Select All / Premium + Select All), Update Account | `enterprise_features_field/_form.html.erb` | Partial |
| E5 | Submit | primary right-aligned | `_form.html.erb` | Match |
| E6 | File / avatar | custom file row, not native ugly control | user edit | Gap on Administrate file fields |

### F. Special pages (not generic Administrate)

| # | Page | Mock | Our file | State |
|---|---|---|---|---|
| F1 | Plan Management | Subtitle; plan price cards; Resource Limits table; Feature matrix with Select All per column; Save Plans | `plan_management/show.html.erb` | Partial — green notice; native checkboxes vs `.custom-checkbox` |
| F2 | Payment Gateways | Gateway cards; country tag pills; custom selects | `payment_gateways/show.html.erb` + `payment_gateway_form.js` | Gap — `slate-*` / `violet-*` tags |
| F3 | Account Hierarchy | Subtitle; search; reseller cards (not slate details) | `enterprise/.../account_hierarchy/show.html.erb` | **Gap** |
| F4 | Enterprise Inquiries | Subtitle; table + Review modal | `enterprise_inquiries/index.html.erb` | Partial |
| F5 | Settings | Subtitle; Installation Identifier (mask/copy); Current Plan + Refresh; Need Help (Community = **primary**, not Discord purple); feature showcase cards | `settings/show.html.erb` | Partial — `bg-violet-600` Discord button, `green-100` EE tag |
| F6 | App Configs | Title `Configure Settings - {Name}`; per-tab forms; secret inputs with eye toggle | `app_configs/show.html.erb` | Partial |
| F7 | Instance Health | Health cards | `instance_statuses/show.html.erb` | Partial |
| F8 | Push Diagnostics | Lookup → user card → subscriptions table / empty → send test → delivery log | `push_diagnostics/show.html.erb` | Partial — `bg-green-100` status |
| F9 | Cloudflare Domains | Custom domain table + add | `cloudflare_domains/show.html.erb` | Partial (cloud-only; keep even if mock sidebar omits it) |
| F10 | Sidekiq | External link to monitoring | `sidekiq_web_path` | Match behavior; fix **placement** (A2) |

### G. Overlays

| # | Overlay | Mock | Ours | State |
|---|---|---|---|---|
| G1 | Search modal | ⌘K, ESC, jump list | `_search_modal.html.erb` | Partial |
| G2 | Delete modal | title, body, Keep / Delete | browser `confirm` | Gap |
| G3 | Review inquiry modal | inquiry summary + process / reject | check current inquiry UI | Partial |
| G4 | Toast | bottom stack, ~2.5s | flashes only | Gap |
| G5 | Global loader | spinner on first paint | layout loader | Match |

---

## 5. Shared UI kit (implement once)

Do not restyle each page ad hoc. Finish these classes in `super_admin/index.scss` and use them everywhere. Tokens only: `bg-background`, `bg-card`, `bg-primary`, `text-foreground`, `text-muted-foreground`, `border-border`, `text-success`, `bg-destructive/10`.

| Component | Class / pattern | Spec from mock |
|---|---|---|
| Page title | `.page-title` | ~22–24px, 600, `text-foreground` |
| Page header | `.page-header` + `.page-actions` | title left, controls right, gap, wrap on small |
| Primary button | `.btn.btn-primary` or existing `bg-primary` h-9 px-4 | plus icon on New |
| Outline / ghost | border `border-input`, hover `bg-accent` + `border-ring` (not hex) | Back, Show |
| Danger | `text-destructive` / `hover:bg-destructive/10` | Delete icon or `.btn-danger-soft` |
| Table | `.table-card` | rounded-xl, header `--table-header-bg`, no vertical rules, hover row |
| Status active | `.status-text-active` | `--success` green text, not a green pill unless mock uses a badge |
| Filter | `.filter-dropdown` | funnel + label + chevron; open menu with check on selected |
| Table search | `.table-search-wrap` | icon inside, h-9, w-64 |
| Custom select | `.nr-select` | **required** on every select. Hide native. |
| Feature flag | `.feature-flag-card` | icon wrap + name + checkbox; premium variant; Select All |
| Read-only flag | `.feature-flag-card.is-read-only` | check / x badge instead of checkbox |
| Empty | `.empty-table-state` | 48px muted inbox icon + "No X found." |
| Toast | `.toast-container` / `.toast` | success after in-page save |
| Delete modal | overlay `bg-background/80 backdrop-blur-[8px]` | header 18/600, description 14 muted, Keep outline + Delete destructive |
| Custom checkbox | `.custom-checkbox` | used in plan feature matrix |

**Banned:** `bg-blue-*`, hex text/border classes, `slate-*`, `violet-*`, `green-50`, native date/select popups, scoped CSS, leftover Administrate class names (`main-content__page-title`) on new work.

---

## 6. Navigation differences to resolve (locked)

These are product decisions already implied by the mock. Treat as requirements:

1. **Sidekiq** lives in the **main** nav list with an external-link icon, not in the footer. Footer = Settings + Log Out.
2. **Cloudflare Domains** stays in our nav when `ChatwootApp.chatwoot_cloud?` even if the public mock hides it. Cloud-only, real product.
3. **No login screen** in the mock. Keep `devise/sessions/new.html.erb` as-is visually (already tokenized).
4. **Notifications bell** is visual in the mock (red dot). No new notification backend in this PRD. Bell can be inert.
5. **User pill** links to Settings (already does).

---

## 7. Implementation plan (smallest diffs)

Work in this order so later pages inherit the kit.

### Phase 0 — Kit cleanup (1 pass)

- Replace every `hover:border-[#cac7f7]` with `hover:border-ring` (or a shared class).
- Replace `bg-violet-*`, `text-violet-*`, `slate-*`, `green-50/200/700` in Super Admin views and `payment_gateway_form.js`.
- Mount `.nr-select` on all Super Admin `<select>` (reuse mock `initCustomSelects` logic in `app/javascript/superadmin/navigation_and_theme.js` or a small `custom_select.js`).
- Add delete modal partial; swap Administrate `data-confirm` for it.
- Command palette: static list of Super Admin routes (Dashboard, Accounts, Users, …) matching mock jump pages.

### Phase 1 — Shell + list pages

- Move Sidekiq nav item.
- Collection empty state, status text, Users avatar cell, Accounts status color.
- Confirm New button labels: "New account", "New user", "New agent bot", etc. (mock copy).

### Phase 2 — Show / Edit / New

- Account show: read-only feature-flag grids like the mock.
- Account edit: Select All on basic/premium grids (already sketched).
- User show: token mask/copy, impersonate caution.
- File inputs: styled "Choose file" + filename, not raw native.

### Phase 3 — Special pages

- Account Hierarchy restyle (highest visual debt).
- Plan Management: subtitle, `.custom-checkbox`, Save Plans.
- Payment gateway country tags → primary/accent pills.
- Settings Community CTA → `bg-primary` (not `bg-violet-600`); EE tag → muted/primary chip.
- Push diagnostics status chips → semantic tokens.
- Dashboard chart chrome (Total/Peak, colors, tooltip).

### Phase 4 — Overlay polish + dark mode pass

- Delete modal, toast, inquiry review modal, search results.
- Walk every page in `.dark` against the mock (toggle in the prototype).

No new tables, endpoints, or Vue SPA. No specs unless asked.

---

## 8. Acceptance criteria

Pass/fail. Compare at 1280×800 against the Vercel mock.

1. Sidebar width 240px expanded; collapsed icon rail + flyout cards work.
2. Active nav: primary color icon + text, no focus ring box.
3. ⌘K opens command palette; typing filters pages; click navigates; Esc closes.
4. Every list page: title, filter (if mock has it), search, primary New, table-card, sort headers, hover row actions.
5. Empty list shows boxed icon + "No {Resource} found." not a bare table cell.
6. No native OS `<select>` popup on any Super Admin form or filter.
7. No hardcoded hex or `slate-*` / `violet-*` / `green-50` in Super Admin views/JS.
8. Account show features render as flag cards (enabled check / disabled x), not a 20-row boolean table.
9. Delete uses the in-app modal (Keep / Delete), not `window.confirm`.
10. Dark mode: sidebar, cards, table header, chart, and inputs use `.dark` tokens; no leftover white flashes.
11. Dashboard stat cards and Conversation Activity match mock layout; chart uses primary series color.
12. Account Hierarchy uses the same page-title / card / table-card language as Accounts.
13. Sign-in still works (local seed) and still uses tokens.

---

## 9. Out of scope

- Rewriting Super Admin as a Vue SPA
- New Super Admin features the mock fakes (client-only create row, fake toasts as source of truth)
- Changing Administrate dashboards' **columns/fields** unless needed for a visual cell (avatar, status color)
- Tenant dashboard (`/app`) Relay UI
- Real notification inbox behind the bell
- Login redesign beyond current tokenized page
- i18n besides `en.yml` / `en.json` if any string moves

---

## 10. Files reference

| File | Role |
|---|---|
| `app/javascript/dashboard/assets/scss/super_admin/index.scss` | Tokens + kit |
| `app/views/layouts/super_admin/application.html.erb` | Shell |
| `app/views/super_admin/application/_navigation.html.erb` | Sidebar |
| `app/views/super_admin/application/_header.html.erb` | Top bar |
| `app/views/super_admin/application/_search_modal.html.erb` | ⌘K |
| `app/views/super_admin/application/_collection.html.erb` | Tables |
| `app/views/super_admin/application/{index,show,new,edit,_form}.html.erb` | CRUD shells |
| `app/javascript/superadmin_pages/views/dashboard/Index.vue` | Dashboard |
| `app/javascript/superadmin/navigation_and_theme.js` | Collapse, theme, selects |
| `enterprise/app/views/super_admin/account_hierarchy/*.html.erb` | Hierarchy (biggest leftover) |
| `app/views/super_admin/plan_management/show.html.erb` | Plans |
| `app/views/super_admin/settings/show.html.erb` | Settings |
| `app/javascript/superadmin/payment_gateway_form.js` | Country tags |

---

## 11. How to test

1. Open the mock: https://super-admin-ui-one.vercel.app/ — click every sidebar item, plus one Show / Edit / New per resource, plus Settings tabs, Plan Management, Hierarchy, Push Diagnostics, ⌘K, delete.
2. Open ours: `http://localhost:3000/super_admin` (see `ADMIN_UI_DEV.md`).
3. Walk the same path. Flag any screen that still looks Administrate-era or uses a native popup.
4. Toggle dark mode on both. Cards, sidebar, and table headers must both invert.

---

## 12. Effort (rough)

| Phase | Work | Note |
|---|---|---|
| 0 Kit cleanup | ~0.5–1 day | Search-replace hex + select enhancer + delete modal |
| 1 Lists + nav | ~0.5 day | Sidekiq move, empty state, copy |
| 2 Show/Edit | ~1 day | Feature cards, file input, user token |
| 3 Special pages | ~1–1.5 days | Hierarchy is the long pole |
| 4 Overlays + dark | ~0.5 day | Palette, search, toasts |

Total: about **4 days** of UI work if we reuse the existing SCSS kit and do not rewrite pages.

---

## Related

- `ADMIN_UI_DEV.md` — how to run Super Admin locally
- Design mock: https://super-admin-ui-one.vercel.app/
- Relay tokens for the tenant app are separate (`components-next/relay/TOKENS.md`). Super Admin has its **own** `:root` in `super_admin/index.scss`. Do not mix the two palettes on these pages.
