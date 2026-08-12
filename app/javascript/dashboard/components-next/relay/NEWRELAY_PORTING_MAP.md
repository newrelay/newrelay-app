# NewRelay-UI → Chatwoot porting map

Single source of truth for applying the **NewRelay-UI** design to this codebase.
Read this instead of re-reading every component. Pairs with [TOKENS.md](./TOKENS.md)
(token table) and [DESIGN.md](./DESIGN.md) (layout rules).

Reference project: `/Users/deependrasankhala/Documents/chandresh/NewRelay-UI`
(dev server: `http://localhost:5174`). Its tokens live in `src/style.css`; ours are a
**direct 1:1 port** in `app/javascript/dashboard/assets/scss/_relay-theme.scss`.

Last synced with NewRelay-UI `main`: **2026-08-11** (commit `c704807`). §2 UI components
to unchanged; since `ba1cbcf`: **settings subpages** restyled with the shared settings shell
(§3.1), **InboxReplyComposer** ported for inbox reply UX, inbox settings flow mapping (§3.1
inboxes row), conversations **onboarding empty state** and a restyled **sidebar network
toaster** (§4). Companies / Contacts / Inbox list views got styling refinements only —
existing mappings still hold.

---

## 0. The golden rule — tokens are identical

NewRelay and Chatwoot Relay use the **same shadcn semantic tokens with the same hex values**.
When porting a NewRelay component, **keep its Tailwind classes as-is** (`bg-card`,
`text-foreground`, `text-muted-foreground`, `bg-primary`, `border-border`, `bg-muted`,
`bg-accent`, `text-primary`, `rounded-xl`, `shadow-sm`…). Do **not** translate them to
`n-*` legacy classes. Never hardcode hex.

| Thing | Value (light / dark) |
| --- | --- |
| Primary / brand | `#4f46e5` / `#4F46E5` (indigo) — class `bg-primary` / `text-primary` |
| Font (sans) | **Geist** — `font-sans` (already the default body font) |
| Font (mono) | **Geist Mono** — `font-mono` |
| Base radius | `0.75rem` → `rounded-lg`; cards use `rounded-xl` |
| Success / warning | `#00884b` / `#dca600` → `text-success` / `text-warning` |

---

## 1. Whole-project changes (font, background, brand color, radius)

Everything is token-driven, so a global restyle is **one file**:
`app/javascript/dashboard/assets/scss/_relay-theme.scss` (mirror of NewRelay `src/style.css`).

- **Change brand color everywhere** → edit `--primary` (and `--ring`, `--sidebar-primary`) in the `:root` and `.dark` blocks.
- **Change page background** → `--background`; card surface → `--card`; sidebar → `--sidebar`.
- **Change font** → `--font-sans` / `--font-mono` (fonts are declared in `fonts.css` equivalents).
- **Change corner roundness globally** → `--radius`.

Edit both the light (`:root`) and dark (`.dark`) values. No component edits needed —
every `bg-primary` / `text-foreground` / `rounded-lg` updates automatically.

---

## 2. Component equivalence (NewRelay `src/components/ui/*` → Chatwoot Relay)

Import Chatwoot components from `dashboard/components-next/relay`.

| NewRelay `ui/` | Chatwoot Relay | Notes |
| --- | --- | --- |
| `Button` | `RelayButton` | variants: `default`/`outline`/`ghost`; `size="icon"` |
| `Badge` | `RelayBadge` | |
| `Input` | `RelayInput` | prop `class-name` for input classes |
| `Label` | `RelayLabel` | |
| `Switch` | `RelaySwitch` | |
| `Checkbox` | `RelayCheckbox` | |
| `Tabs`/`TabsList`/`TabsTrigger`/`TabsContent` | `RelayTabs`/`RelayTabsList`/`RelayTabsTrigger`/`RelayTabsContent` | active state uses `aria-selected:` (not reka's `data-[state=active]:`) |
| Modal shell | `RelayModal` | settings add/edit forms |
| Confirm/delete | `RelayConfirmModal` | delete confirmations |
| `DropdownMenu*` (reka-ui) | `dashboard/components-next/dropdown-menu/DropdownMenu.vue` | different API: `:menu-items="[{label,value,action,icon}]"` + `@action` |
| `GlobalToast` | `useAlert` composable (`dashboard/composables`) | Chatwoot has no toast component — call `useAlert(msg)` |
| `KpiCard` | *no component* — use the **stat-card recipe** (§4) | |
| `DateRangePicker` | existing report date pickers (`HeatmapDateRangeSelector`, `OverviewReportFilters`) | |

Legacy `woot-*` / `WootButton` / `WootModal` are being phased out — never add new usages.

---

## 3. Page index (NewRelay view → Chatwoot location)

Look at the NewRelay view file for the exact markup, then edit the matching Chatwoot file.

NewRelay-UI grows fast — this table lists the stable, built-out mappings.
For anything not listed, run `find …/NewRelay-UI/src/views -name '*.vue'` and open
the matching view; the section recipes (§4) still apply.

| NewRelay `src/views/…` | Chatwoot location |
| --- | --- |
| `reports/ReportsView.vue` | `routes/dashboard/settings/reports/` — Overview=`LiveReports.vue`, wrapper=`components/ReportsWrapper.vue`, tables=`components/SummaryReports.vue`, cards=`components/overview/MetricCard.vue` + `components/overview/{Agent,Team}Table.vue`, heatmap=`components/heatmaps/BaseHeatmap.vue`, CSAT=`CsatResponses.vue`+`components/Csat*` |
| `conversations/ConversationsView.vue` | `routes/dashboard/conversation/`; list header + Mine/Unassigned/All tabs = `components/ChatList.vue`; rows = `components-next/Conversation/ConversationCard/` |
| `inbox/InboxView.vue` | `routes/dashboard/inbox/`; inbox rows = `components-next/Inbox/InboxCard.vue`; thread reply composer = `components/widgets/conversation/InboxReplyComposer.vue` (used from conversation/inbox message views) |
| `companies/CompaniesView.vue` / `contacts/ContactsView.vue` | `routes/dashboard/companies/` / `routes/dashboard/contacts/` |
| `campaigns/{LiveChat,SMS,WhatsApp}CampaignsView.vue` | `routes/dashboard/campaigns/` |
| `settings/SettingsView.vue` + all settings subpages / modals / flows | **§3.1** — `routes/dashboard/settings/` |
| `auth/{Login,Register,ForgotPassword,SsoLogin,Onboarding2View}.vue` | Chatwoot auth = `app/javascript/v3/views/auth/` (signup, password, reset, confirmation, verify-email); login/SSO screens live there too |
| `support/SupportView.vue` + `support/components/*` (Articles, ArticlesList, Categories, Locales, ArticleEditor, Settings, KeyboardShortcuts) | Help Center = `routes/dashboard/helpcenter/` |
| `captain/CaptainAiView.vue`, `copilot/CopilotView.vue` | Captain = `routes/dashboard/captain/` (enterprise); Copilot = conversation-side panel |
| `analytics/DashboardsView`, `RevenueAnalyticsView`, `CampaignAnalyticsView`; `tasks/`, `calendar/`, `ecommerce/*`; `reputation/`, `reviews/`, `deals/`, `funnels/`, `pipelines/`, `opportunities/`, `project-management/`, `surveys/`, `forms/`, `listings/` | **not built in Chatwoot** — sidebar shows the analytics ones disabled "Coming soon"; the rest have no Chatwoot equivalent |
| sidebar/layout | `components-next/sidebar/Sidebar.vue` (leaf styling = `SidebarGroupLeaf.vue`). NewRelay `AppSidebar.vue` now carries an **online-status pill** (agent presence) and a **Relay AI floating button**; `AppHeader.vue` holds the top-bar search/profile |

### 3.1 Settings

**Status:** updated design (Relay tokens + shared settings shell). NewRelay still uses one mega
`SettingsView.vue` with `activeItem` ids; Chatwoot uses **real routes** per subpage inside
`SettingsWrapper`.

**Shared layout (use these — do not rebuild side nav or list chrome by hand)**

| Piece | Chatwoot path | Role |
| --- | --- | --- |
| `SettingsWrapper` | `routes/dashboard/settings/SettingsWrapper.vue` | Outer shell: side menu + `<router-view>` |
| `SettingsSideMenu` | `routes/dashboard/settings/components/SettingsSideMenu.vue` | Secondary nav (sections + items) |
| `settings.navigation.js` | `routes/dashboard/settings/settings.navigation.js` | Nav sections / route names / `activeOn` / feature flags |
| `BaseSettingsHeader` | `routes/dashboard/settings/components/BaseSettingsHeader.vue` | Form/list page title, description, help link, search, actions slots |
| `SettingsSubPageHeader` | `routes/dashboard/settings/SettingsSubPageHeader.vue` | In-flow section title + muted description (inbox tabs, nested steps) |
| `SettingsLayout` | `routes/dashboard/settings/SettingsLayout.vue` | List subpage wrapper: loading / empty / `#body` slot |
| `SettingsListCard` / `SettingsListRow` | `routes/dashboard/settings/components/SettingsListCard.vue`, `SettingsListRow.vue` | Searchable list tables (agents, labels, macros, …) |

**Subpage index** (NewRelay `SettingsView` item id or component → Chatwoot)

| NewRelay | Chatwoot `routes/dashboard/settings/` |
| --- | --- |
| `workspace` (Account Setting) | `account/Index.vue` (+ `account/components/SectionLayout.vue` for form sections) |
| `branding` | `branding/Index.vue` |
| `custom_domain` | `customDomain/Index.vue` |
| `billing` | `billing/Index.vue` |
| `users` (Agents) | `agents/Index.vue`, `AddAgent.vue`, `EditAgent.vue` |
| `teams` + `CreateTeamFlow.vue`, `ViewTeamPanel.vue`, `DeleteTeamModal.vue` | `teams/` |
| `roles` + `AddCustomRoleModal.vue` | `customRoles/Index.vue`, `component/CustomRoleModal.vue` |
| `agent_assignment` + `AgentAssignment.vue` | `assignmentPolicy/` |
| `inboxes` + `InboxSettingsFlow.vue` / `AddInboxFlow.vue` | `inbox/Index.vue`, channel wizard under `inbox/channels/`, per-inbox `Settings.vue`, `settingsPage/*`, `PreChatForm/` |
| `labels` | `labels/Index.vue`, `component/LabelModal.vue` |
| `notifications` | `notifications/Index.vue` |
| `workflows` + `Workflows.vue` | `conversationWorkflow/index.vue` |
| `bots` + `Bots.vue` | `agentBots/Index.vue` |
| `macros` + `Macros.vue` | `macros/` |
| `canned_responses` + `CannedResponses.vue` | `canned/Index.vue`, `AddCanned.vue`, `EditCanned.vue` |
| `sla` + `Sla.vue` | `sla/Index.vue` |
| `custom_attributes` + `CustomAttributes.vue` | `attributes/Index.vue`, `AttributeRow.vue` |
| `apps` (Integrations) | `integrations/Index.vue`, `ShowIntegration.vue`, provider pages (`Slack.vue`, `Notion.vue`, …) |
| `api_keys` | `integrations/ApiKeys/Index.vue` |
| `webhooks` | `integrations/IntegrationHooks.vue` / webhook routes in `integrations/` |
| `security` | `security/Index.vue` (+ SAML components under `security/components/`) |
| `audit_logs` | `auditlogs/Index.vue` |
| *(Chatwoot-only)* Automation rules | `automation/Index.vue` — not a NewRelay settings nav item; route `/settings/automation` |
| `ProfileSettingsView.vue` + `ProfileSettings.vue` | `profile/Index.vue` |
| `ProfileMfaView.vue` + `ProfileMfa.vue` | `profile/MfaSettings.vue` |
| Reports (linked from settings) | `reports/` — see reports row in §3 table |

**Adding a new settings page:** register the route in the relevant `*.routes.js` under
`settings/`, add a nav item to `SETTINGS_NAV_SECTIONS` in `settings.navigation.js` (include
`activeOn` for child routes), render inside `SettingsWrapper`, and use the **list** or **form**
recipes in §4. Keep permissions / feature flags on route `meta` — `SettingsSideMenu` reads them
via `usePolicy`.



**Sidebar is now data-driven** in NewRelay: menu items live in `src/config/navigation.ts`
(consumed by `components/layout/AppSidebar.vue`). To mirror menu structure/labels, read
`navigation.ts` — don't scrape the markup.

---

## 4. Section recipes (exact class strings, verified against the reference)

Copy these; they are the NewRelay canonical markup.

### Page shell (report/settings-style page)
```html
<div class="px-8 pt-6">
  <h1 class="text-xl font-semibold tracking-tight text-foreground mb-1">Title</h1>
  <p class="text-sm text-muted-foreground mb-4">Subtitle.</p>
  <!-- tab bar -->
  <div class="flex items-center gap-6 text-[14px] border-b border-border/60 overflow-x-auto">
    <a class="pb-3 font-medium whitespace-nowrap border-b-2 -mb-px border-primary text-primary">Active</a>
    <a class="pb-3 font-medium whitespace-nowrap border-b-2 -mb-px border-transparent text-muted-foreground hover:text-foreground">Other</a>
  </div>
</div>
<div class="px-8 pt-6 pb-12 flex flex-col gap-6"><!-- sections --></div>
```

### Settings shell (list subpage)

Prefer **`SettingsLayout` + `SettingsListCard`** (see `agents/Index.vue`). Page chrome lives
inside the card toolbar; rows use **`SettingsListRow`**.

```html
<!-- SettingsLayout #body -->
<div class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs">
  <div class="flex flex-col justify-between gap-4 border-b border-border/40 p-4 sm:p-6 md:flex-row md:items-center">
    <div>
      <h3 class="text-base font-medium text-foreground">Section title</h3>
      <p class="mt-1 text-sm text-muted-foreground">Description.</p>
    </div>
    <div class="flex w-full flex-col items-center gap-3 sm:flex-row md:w-auto">
      <div class="relative w-full sm:w-64">
        <!-- i-lucide-search + RelayInput h-9 pl-9 -->
      </div>
      <!-- RelayButton primary action -->
    </div>
  </div>
  <div class="divide-y divide-border/40">
    <!-- SettingsListRow: group hover:bg-muted/10, actions opacity-0 group-hover:opacity-100 -->
  </div>
</div>
```

For pages that already use **`BaseSettingsHeader`** with search in the header (macros, canned,
automation), keep that component and still wrap the list body in `SettingsListCard`.

### Settings form subpage

Prefer **`BaseSettingsHeader`** + stacked **`SectionLayout`** cards (`as-card`) inside a
`max-w-3xl` column (see `account/Index.vue`). Use **`RelayInput` / `RelayLabel` / `RelaySwitch` /
`RelayButton`** in form footers.

```html
<div class="flex w-full max-w-3xl flex-col gap-8 ltr:mr-auto rtl:ml-auto">
  <!-- BaseSettingsHeader :title :description -->
  <form class="flex min-w-0 flex-col gap-8" @submit.prevent="save">
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
  </form>
</div>
```

Use **`SettingsSubPageHeader`** when a sub-route needs a smaller heading block inside a
multi-tab flow (e.g. inbox `settingsPage/*`) without replacing the whole `BaseSettingsHeader`.

### Settings modal (add/edit form)

Never use `woot-modal` / `woot-modal-header` for new settings modals.

```html
<RelayModal :show="show" :title="..." :description="..." @close="close">
  <form @submit.prevent="submit">
    <div class="space-y-5 px-7 pb-2"><!-- RelayLabel + RelayInput fields --></div>
    <div class="flex justify-end gap-3 border-t border-border/40 px-7 py-6">
      <RelayButton variant="outline" class="h-9 border-border bg-muted px-5 text-[13px] font-medium text-foreground shadow-sm hover:bg-muted/80">Cancel</RelayButton>
      <RelayButton type="submit" class="h-9 px-5 text-[13px] font-medium shadow-sm">Submit</RelayButton>
    </div>
  </form>
</RelayModal>
```


### Live badge (emerald pill)
```html
<div class="flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-emerald-500/10 text-emerald-600 text-[12px] font-medium border border-emerald-500/20">
  <span class="size-1.5 rounded-full bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]"></span> Live
</div>
```

### Stat / KPI card (icon-left)
```html
<div class="group flex flex-col justify-between bg-card border border-border/60 rounded-xl shadow-sm p-5 transition-colors hover:border-primary/20">
  <div>
    <div class="flex items-center gap-2 mb-4">
      <span class="size-6 rounded-md bg-primary/10 text-primary grid place-content-center shrink-0">
        <span class="i-lucide-message-circle size-3.5"></span>
      </span>
      <h3 class="text-[13px] font-medium text-muted-foreground group-hover:text-foreground">Open</h3>
    </div>
    <div class="mb-1"><span class="text-[28px] leading-none font-semibold text-foreground tracking-tight">95</span></div>
    <div class="flex items-center gap-1.5 text-[12px]">
      <span class="font-medium text-emerald-500">14.3%</span>
      <span class="text-muted-foreground">vs last 7 days</span>
    </div>
  </div>
</div>
```

### Section card (heatmap / chart wrapper)
```html
<div class="p-6 rounded-xl border border-border bg-card shadow-sm flex flex-col gap-4">
  <div class="flex items-center justify-between">
    <div class="flex items-center gap-3"><h3 class="text-base font-medium text-foreground tracking-tight">Title</h3><!--Live--></div>
    <div class="flex items-center gap-2"><!-- dropdown buttons + download --></div>
  </div>
  <!-- body -->
</div>
```

### Dropdown / filter button (bordered)
```html
<button class="inline-flex items-center gap-2 h-8 px-3 text-[14px] rounded-md bg-card hover:bg-muted font-medium border border-border/80 shadow-sm text-foreground">
  <span class="i-lucide-calendar size-3.5 opacity-70"></span> Last 7 days
  <span class="i-lucide-chevron-down size-3.5 opacity-50"></span>
</button>
```

### Table card
```html
<div class="rounded-xl border border-border bg-card shadow-sm overflow-hidden flex flex-col">
  <div class="p-6 pb-4 flex items-center gap-3"><h3 class="text-base font-medium text-foreground tracking-tight">Title</h3><!--Live--></div>
  <div class="w-full overflow-x-auto">
    <table class="w-full text-left text-[14px]">
      <thead class="text-muted-foreground font-medium bg-muted/20">
        <tr><th class="px-6 py-4 font-medium">Agent</th><th class="px-6 py-4 font-medium">Open</th></tr>
      </thead>
      <tbody class="divide-y divide-border">
        <tr><td class="px-6 py-4 text-foreground">…</td></tr>
      </tbody>
    </table>
  </div>
</div>
```

### Onboarding empty state (conversations — "connect a channel")
Shown when no channels are connected. Centered column: `size-16 rounded-full bg-primary/10 …
ring-8 ring-primary/5` icon → `text-base font-medium` heading → muted subtitle → a
**getting-started stepper card** (`bg-card/50 border border-border/50 rounded-xl p-5`, "Step N
of 4" pill = `text-[10px] text-primary bg-primary/10 px-2 py-0.5 rounded-full uppercase`;
steps use `size-[22px] rounded-full` dots — done = `bg-primary` + `Check`, active = `border-2
border-primary` + pulsing dot, connecting line `absolute left-[11px] w-px bg-border`) →
**integration cards** grid `grid-cols-1 sm:grid-cols-2 gap-3` (connected = `border-2
border-emerald-500 bg-emerald-50/50 dark:bg-emerald-500/10`). Wire to Chatwoot's real
"no inboxes" onboarding state; don't fabricate step progress.

### Network toaster (sidebar, restyled)
Centered bottom pill (was top-left card): `fixed bottom-[50px] left-1/2 -translate-x-1/2
z-[100]`, inner `flex items-center gap-3 px-4 py-2.5 rounded-full shadow-2xl border
backdrop-blur-md`. State classes: offline `bg-destructive/10 text-destructive
border-destructive/30`, reconnecting `bg-muted/80 text-foreground border-border/50`, online
`bg-success/10 text-success border-success/30`. Enter/leave `Transition` slides from
`translate-y-[60px] scale-95`.

### Heatmap cell intensity (via class binding)
Empty `bg-muted/50 dark:bg-muted/30`; ramp `bg-primary/20 → /35 → /50 → /65 → /80 → bg-primary`
(green variant swaps `primary` for `emerald-500`). Cell box: `h-8 rounded-[8px]` (or `w-[36px] h-[22px]`).

---

## 5. Porting workflow (follow every time)

1. Open the matching **NewRelay view** (§3) and/or read its rendered DOM at `localhost:5174`.
2. For each section, copy the canonical classes (§4 or the view file). Tokens are identical — keep them.
3. Swap NewRelay `ui/*` components for the **Relay equivalent** (§2).
4. Keep all Chatwoot **data logic / store dispatches / i18n**; only change markup + classes.
5. No bare strings — add i18n keys (frontend → `i18n/locale/en/*.json`).
6. Where Chatwoot has no data for a NewRelay element (e.g. trend %), mark it `NiN` (`REPORT.DATA_PENDING`) so it's visibly pending, don't fabricate.
7. Verify against `localhost:5174` after the dev server is healthy — never claim "matches" unrendered.
