# Settings UI — NewRelay Design Port PRD

**Reference (live):** https://new-relay-ui.vercel.app/settings
**Reference (source):** `/Users/deependrasankhala/Documents/chandresh/NewRelay-UI/src/views/settings/`
**Scope root:** `app/javascript/dashboard/routes/dashboard/settings/`
**Design source of truth:** `app/javascript/dashboard/components-next/relay/NEWRELAY_PORTING_MAP.md` (+ `TOKENS.md`, `DESIGN.md`)
**Status date:** 2026-08-25 · **Scope locked:** search deferred, all 10 legacy files in one pass

---

## 1. Objective

Bring every page under `settings/` to visual + IA parity with the NewRelay
reference: a grouped, collapsible secondary nav on the left and card-based,
Relay-tokened content on the right — eliminating all remaining legacy
`woot-*` / `WootModal` / scoped-CSS widgets.

**Success in one line:** `grep -r "woot-\|WootModal\|scoped" settings/` returns
nothing, and every subpage renders as Relay cards on the dark theme identical
to the reference.

## 2. Non-goals (this pass)

- Global settings **search + ⌘K** in the top bar (reference has it; **deferred**).
- New reference-only features not present in Chatwoot (e.g. Branding "Brand
  Colors" palette, Billing plan cards, Notifications "Quiet hours"). Port the
  *look* of existing Chatwoot pages; do not invent new functionality.
- Backend/API changes. This is a frontend restyle only.

## 3. Design system contract (non-negotiable)

Tokens are a **1:1 port** of NewRelay — classes carry over verbatim. Never
hardcode hex, never use `n-*` legacy classes.

| Thing | Token / class |
|-------|---------------|
| Brand / primary | `bg-primary` / `text-primary` (indigo `#4f46e5`) |
| Surfaces | page `bg-background`, card `bg-card`, muted `bg-muted` |
| Text | `text-foreground`, `text-muted-foreground` |
| Borders | `border-border` (cards often `border-border/60`, dividers `border-border/40`) |
| Radius | inputs/buttons `rounded-lg`, cards `rounded-xl` |
| Font | `font-sans` (Geist), `font-mono` (Geist Mono) |
| Shadow | cards `shadow-xs` / `shadow-sm` |

**Components** — import from `dashboard/components-next/relay`:
`RelayButton` (`default`/`outline`/`ghost`, `size="icon"`), `RelayInput`,
`RelayLabel`, `RelaySwitch`, `RelayCheckbox`, `RelayTabs*`, `RelayModal`
(add/edit forms), `RelayConfirmModal` (deletes). Toasts → `useAlert()`
composable (no toast component). Dropdowns → `components-next/dropdown-menu/DropdownMenu.vue`.

## 4. Shared shell (already built — reuse, do not rebuild)

| Piece | Path | Role |
|-------|------|------|
| `SettingsWrapper` | `settings/SettingsWrapper.vue` | Side menu + `<router-view>` |
| `SettingsSideMenu` | `settings/components/SettingsSideMenu.vue` | Collapsible grouped secondary nav, active primary-dot |
| `settings.navigation.js` | `settings/settings.navigation.js` | Nav sections / route names / `activeOn` / feature flags |
| `BaseSettingsHeader` | `settings/components/BaseSettingsHeader.vue` | Page title, description, help link, search + actions slots |
| `SettingsSubPageHeader` | `settings/SettingsSubPageHeader.vue` | In-flow section title + muted description (inbox tabs, steps) |
| `SettingsLayout` | `settings/SettingsLayout.vue` | List subpage wrapper: loading / empty / `#body` |
| `SettingsListCard` / `SettingsListRow` | `settings/components/` | Searchable list tables |

## 5. Canonical markup recipes (verified against reference)

### 5a. Form subpage — `BaseSettingsHeader` + stacked `SectionLayout` cards (`max-w-3xl`)
```html
<section class="grid grid-cols-1 gap-5 overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs">
  <header class="flex gap-4 border-b border-border/40 p-4 sm:p-6">
    <span class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary/10"><!-- icon --></span>
    <div>
      <h4 class="text-base font-semibold text-foreground">Section title</h4>
      <p class="mt-1 text-sm leading-relaxed text-muted-foreground">Section note.</p>
    </div>
  </header>
  <div class="flex flex-col gap-1.5 p-4 sm:p-6"><!-- RelayLabel + RelayInput rows --></div>
</section>
<div class="flex justify-end gap-2"><!-- RelayButton outline cancel + default submit --></div>
```

### 5b. List subpage — `SettingsLayout #body` + `SettingsListCard` + `SettingsListRow`
```html
<div class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs">
  <div class="flex flex-col justify-between gap-4 border-b border-border/40 p-4 sm:p-6 md:flex-row md:items-center">
    <div>
      <h3 class="text-base font-medium text-foreground">Section title</h3>
      <p class="mt-1 text-sm text-muted-foreground">Description.</p>
    </div>
    <!-- search (i-lucide-search + RelayInput h-9 pl-9) + RelayButton primary -->
  </div>
  <div class="divide-y divide-border/40"><!-- SettingsListRow: group hover:bg-muted/10 --></div>
</div>
```

### 5c. Add/edit modal — `RelayModal` (never `woot-modal`)
```html
<RelayModal :show="show" :title="..." :description="..." @close="close">
  <form @submit.prevent="submit">
    <div class="space-y-5 px-7 pb-2"><!-- RelayLabel + RelayInput fields --></div>
    <div class="flex justify-end gap-3 border-t border-border/40 px-7 py-6">
      <RelayButton variant="outline" ...>Cancel</RelayButton>
      <RelayButton type="submit" ...>Submit</RelayButton>
    </div>
  </form>
</RelayModal>
```

### 5d. Icons
Search adornment `size-4 text-muted-foreground` (input `pl-9 h-9`); row action
`RelayButton variant="ghost" size="icon"` (`size-8`) with `size-3.5` glyph.

## 6. Current state — DONE

Shell + IA are fully ported and match the reference groups/sub-items 1:1:

- **General** — Account Setting, Branding, Custom Domain, Billing
- **People** — Agents, Teams, Roles, Agent Assignment
- **Communication** — Inboxes, Labels, Notifications
- **Automation** — Workflows, Bots, Macros, Canned, SLA
- **Customer Data** — Custom Attributes
- **Integrations** — Apps, API Keys, Webhooks
- **Security** — Security, Audit Logs

Pages already on Relay (no legacy widgets, ~85 files): account, agents, teams,
integrations, security, billing, branding, customDomain, labels, canned,
macros, automation, notifications, attributes, customRoles, assignmentPolicy,
agentBots, reports. `account/Index.vue` (the reference screenshot page) is the
reference implementation of recipe 5a.

## 7. Current state — DONE (10/10 files ported, 2026-08-25)

Each file mapped to the recipe it adopted.

| # | File | Recipe | Notes |
|---|------|--------|-------|
| 1 | `inbox/Settings.vue` | 5a (tabbed sections) | Per-inbox settings shell; use `RelayTabs*` + `SettingsSubPageHeader` |
| 2 | `inbox/ImapSettings.vue` | 5a | IMAP credential form → `RelayInput`/`RelayLabel` rows |
| 3 | `inbox/SmtpSettings.vue` | 5a | SMTP credential form |
| 4 | `inbox/settingsPage/ConfigurationPage.vue` | 5a | Inbox configuration form |
| 5 | `inbox/settingsPage/CollaboratorsPage.vue` | 5b | Agent/collaborator list + `RelayButton` |
| 6 | `profile/UserBasicDetails.vue` | 5a | Name/avatar/email form |
| 7 | `profile/ChangePassword.vue` | 5a | Password form; primary submit |
| 8 | `profile/AccessToken.vue` | 5a | Token card w/ copy action (`useAlert` on copy) |
| 9 | `sla/SlaForm.vue` | 5a or 5c | If shown as modal → `RelayModal`; if inline → `SectionLayout` |
| 10 | `sla/SlaTimeInput.vue` | field | Leaf input used by SlaForm → `RelayInput` styling |

### 7b. Settings search — DONE (2026-08-25), scope adjusted
- Built as a **live filter box at the top of `SettingsSideMenu`** that filters
  `SETTINGS_NAV_SECTIONS` by item label, force-expands matching sections, and
  shows a "No settings found" empty state.
- **No ⌘K binding:** Chatwoot already ships a global ⌘K/Ctrl+K command palette
  (`ninja-keys`, `routes/dashboard/commands/commandbar.vue`) — the reference's
  top-bar search *is* that global palette. Adding a settings-scoped ⌘K would
  collide, so the settings search is nav-scoped with no shortcut.
- i18n keys added: `SIDEBAR.SETTINGS_NAV_SEARCH`, `SIDEBAR.SETTINGS_NAV_NO_RESULTS`.

## 8. Plan

1. **Phase 1 — Legacy conversion — DONE (2026-08-25):** all 10 files ported
   `woot-input` → `RelayLabel` + `RelayInput` (+ `text-destructive` error text,
   or a conditional `ring-destructive` where the original showed only an error
   border). `AccessToken` mask toggle rebuilt with `RelayInput` + lucide `Icon`.
   Store dispatches, props/emits, and validations preserved; no new i18n keys
   needed (reused existing). `pnpm eslint` clean (only pre-existing dynamic-key
   warnings in `SlaForm` remain). No `woot-input`/`woot-modal` left under `settings/`.
2. **Phase 2 — QA — DONE (2026-08-25):** verified live against the running app
   (account 2, "Acme Org", with an email inbox for IMAP/SMTP). Confirmed:
   `ChangePassword`, `UserBasicDetails`, `AccessToken` (incl. mask-toggle),
   `SlaForm`/`SlaTimeInput` (incl. `v-model` binding), `ImapSettings` (incl.
   `ring-destructive` validation on blur), `Settings.vue` inbox-name field,
   and `ConfigurationPage` all render as Relay cards matching the reference.
   `CollaboratorsPage`'s legacy max-assignment field wasn't reachable in this
   account (it uses the newer assignment-policy v2 UI) but shares the exact
   same proven pattern. Console clean of component errors — only a
   pre-existing unrelated `GeistVariable.woff2` 404 remains. Also hit a known
   Vite HMR blank-app issue mid-session; fixed per the porting-map note via
   `overmind restart vite` (not a code change).

## 9. Acceptance criteria

- No `woot-*` / `WootModal` / scoped CSS under `settings/`.
- Files 1–10 render as recipe-5a/5b/5c cards on the dark theme, matching the reference.
- All existing functionality (form submit, validation, delete confirms, copy) preserved.
- No hardcoded hex, no `n-*` classes; all strings i18n'd (`en.json`).
- `pnpm eslint` clean on touched files.

## 10. Risks / notes

- Enterprise overlay lives under `enterprise/` — check for mirrored files when
  touching shared logic before editing an OSS settings file.
- Vite HMR circular-import (`BackButton` ↔ `routes/index`) can blank the app
  after many hot edits → **restart dev server**, not a code fix.
- `sla/SlaForm.vue` recipe (5a vs 5c) depends on whether SLA create/edit is a
  modal or an inline page — confirm at implementation time.

## 11. Open questions

- ~~`sla/SlaForm` — modal or inline page?~~ **Resolved during QA:** it's a
  `RelayModal` ("Add SLA" dialog), confirmed 2026-08-25.
- Any pages intentionally excluded (Captain / Enterprise-only)? Still open —
  no Captain/Enterprise settings pages were touched or found under
  `settings/` in this pass; flag if any exist elsewhere and need the same treatment.
