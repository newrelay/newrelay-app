# NewRelay UI & Design System Specification

This document is the single authoritative specification and implementation guide for the **NewRelay UI Design System**, compiled from `/Users/deependrasankhala/Downloads/desgin-system-nr`.

---

## 1. Vision & Core Philosophy

**Objective:** Transform NewRelay into a clean, high-efficiency, intuitive Omni-Channel platform. The visual and UX language targets the sleek, enterprise-grade feel of **HubSpot**, **Linear**, **Notion**, and **Stripe**.

### Key Design Pillars:
* **Jobs-to-be-Done (JTBD) Information Architecture:** Organize features around what users need to accomplish, avoiding cluttered backend module dumping.
* **Strict Semantic Theming:** Color, typography, and spacing are driven entirely by dynamic CSS tokens to ensure 100% light/dark mode parity without hardcoded hex values.
* **Progressive Disclosure:** Keep top-level navigation lean (7-8 primary items) and expose contextual sub-navigation or slide-out sheets as users drill into specific tasks.
* **Linear-Grade Polish:** High-contrast borders, 12px base radius, custom scrollbars, and tight typographic scale (`Geist` font family).

---

## 2. Engineering & Component Rules

### 1. Strict Dependency & Architecture Rules
* **No Ad-Hoc CSS / No Hardcoded Hex:** Never write inline styles (`style={{}}`) or hardcoded Tailwind values like `bg-[#4f46e5]`. Use predefined semantic tokens (`bg-primary`, `text-muted-foreground`, `border-border`).
* **Component Parity:** All reusable UI elements must mirror the architecture of standard `shadcn/ui` ports (`reka-ui` + Vue 3 `<script setup>`). Use `clsx` and `tailwind-merge` (`cn()` helper) for prop merging.
* **Class-Based Dark Mode:** Dark mode relies strictly on the `.dark` class applied to the root element. Do not use `@media (prefers-color-scheme)` directly in component CSS.

### 2. Error Handling & State Rules
* **Layout Error Boundary:** Use Vue's `onErrorCaptured` hook in global/layout wrappers to gracefully handle component exceptions without littering individual try-catches.
* **Strict Form Validation:** Primary CTA buttons ("Create", "Save", "Submit") must remain disabled (`disabled` state + reduced opacity) until all required inputs pass validation.
* **Developer Mock Toggles:** Empty states must feature a discreet developer button at the bottom to inject sample data for live preview and testing.

---

## 3. Information Architecture (IA) & Navigation

```
+-----------------------------------------------------------------------------------+
| GLOBAL SIDEBAR (Icon + Label)     | CONTEXTUAL NAV / CANVAS                       |
+-----------------------------------+-----------------------------------------------+
| 🔍 Search (Ctrl + K)              | Page Header (H1 text-base/xl, actions top-R) |
| 📥 Inbox                          | Split-view / Masonry Grid / Data Table        |
| 📈 Pipeline                       | Contextual Sub-Tabs (text-[13px])             |
| 👥 Contacts                       | Slide-out Sheet for detail inspection        |
| 📢 Campaigns                      |                                               |
| ⚡ Automation                     |                                               |
| 📊 Reports                        |                                               |
| 🤖 Captain (Daksh AI)             |                                               |
| ⚙️ Settings (Bottom Pin)           |                                               |
+-----------------------------------+-----------------------------------------------+
```

### Main Navigation Modules
1. **Workspace:** Home (Role-based metrics), Inbox (Unified Omni-Channel), Tasks.
2. **CRM & Sales:** Contacts & Companies, Visual Drag-and-Drop Pipeline, Calendar.
3. **Marketing:** Campaigns (Email, SMS, Social), Funnels & Landing Pages, Reputation.
4. **AI & Automation:** Daksh AI (Captain), Workflows Builder, Knowledge Base.
5. **Analytics & Reports:** Revenue Velocity, Campaign Performance, Inbox SLAs.
6. **Administration:** Workspace Settings, Users/Roles, Billing, Webhooks & Integrations.

---

## 4. Design System Tokens & Color Palette

All colors map to CSS Custom Properties defined in `src/style.css`.

### Core Semantic Variables

| Token Key | Light Theme (`:root`) | Dark Theme (`.dark`) | Applied Purpose |
| :--- | :--- | :--- | :--- |
| `--background` | `#ffffff` | `#10141d` | Main workspace background |
| `--foreground` | `#141822` | `#fafafa` | Primary text |
| `--card` | `#ffffff` | `#181d27` | Surface cards & containers |
| `--card-foreground` | `#141822` | `#fafafa` | Card body text |
| `--popover` | `#ffffff` | `#181d27` | Dropdowns, menus, tooltips |
| `--popover-foreground` | `#141822` | `#fafafa` | Dropdown text |
| `--primary` | `#4f46e5` | `#6f71fb` | Primary brand accent & active state |
| `--primary-foreground` | `#fafafa` | `#fafafa` | Text on primary elements |
| `--secondary` | `#f2f4f9` | `#242933` | Sub-surfaces & soft buttons |
| `--secondary-foreground`| `#222938` | `#fafafa` | Text on secondary elements |
| `--muted` | `#f2f4f9` | `#242933` | Subtle backgrounds |
| `--muted-foreground` | `#6c727e` | `#9ba2ae` | Secondary/hint text |
| `--accent` | `#edf0ff` | `#2c304c` | Hover highlights & selection |
| `--accent-foreground` | `#30327a` | `#e2e7fc` | Accent hover text |
| `--destructive` | `#e11d48` | `#ff6568` | Errors, warnings, deletions |
| `--destructive-foreground`| `#f8fafc` | `#f8fafc` | Text on destructive elements |
| `--border` | `#e4e7ee` | `#ffffff1a` | High-contrast divider borders |
| `--input` | `#e4e7ee` | `#ffffff26` | Form input borders |
| `--ring` | `#4f46e5` | `#6f71fb` | Focus outline ring |

### Sidebar Palette
* **Background (`--sidebar`):** Light `#f9fafd` | Dark `#181d27`
* **Text (`--sidebar-foreground`):** Light `#141822` | Dark `#fafafa`
* **Active Highlight (`--sidebar-primary`):** Light `#4f46e5` | Dark `#6f71fb`
* **Hover Accent (`--sidebar-accent`):** Light `#edf0ff` | Dark `#2c304c`
* **Border (`--sidebar-border`):** Light `#e4e7ee` | Dark `#ffffff1a`

---

## 5. UI Metrics, Typography & Component Standards

### Typography Scale
* **Primary Body & Display:** `Geist` (`@fontsource-variable/geist`)
* **Monospace Code & Metrics:** `Geist Mono` (`@fontsource-variable/geist-mono`)

#### Text Hierarchy
* **Page Headings (H1):** `text-xl` (20px) or `text-base` (16px), `font-semibold`, `text-foreground`
* **Section Titles:** `text-base` (16px), `font-medium`
* **Modal / Card Labels:** `text-[13.5px] font-medium text-foreground`
* **Form Inputs:** `text-sm` (14px)
* **Sub-navigation Links:** `text-[13px] font-medium`
* **Badges / Count Pills:** `text-[11px] font-medium`

---

### Radii Scale (`var(--radius)` = `0.75rem` / `12px`)

* `--radius-sm`: `8px` (`calc(var(--radius) - 4px)`)
* `--radius-md`: `10px` (`calc(var(--radius) - 2px)`)
* `--radius-lg`: `12px` (`var(--radius)`)
* `--radius-xl`: `16px` (`calc(var(--radius) + 4px)`)

---

### Component Metric Matrix

#### Buttons (`Button.vue` / `RelayButton`)
* **Default (`md`):** `h-9` (36px height), `px-4 py-2`, `text-sm`, `shadow-xs`, `rounded-md`
* **Small (`sm`):** `h-8` (32px height), `px-3`, `text-xs`, `rounded-md`
* **Large (`lg`):** `h-10` (40px height), `px-6`, `rounded-md`
* **Icon-Only:** `size-9` (36px x 36px)
* **Ghost Buttons:** Must include a subtle border (`border border-border`) that disappears on hover (`hover:border-transparent`).

#### Form Inputs (`Input.vue` / `RelayInput`)
* **Dimensions:** `h-9` (36px height), `px-3 py-1`, `w-full`, `text-sm`
* **Styling:** `rounded-md border border-input bg-background shadow-xs transition-colors`
* **Focus Behavior:** `focus-visible:ring-1 focus-visible:ring-ring focus-visible:outline-hidden`
* **Modal Forms Layout:** Field container `flex flex-col gap-1.5`, Checkbox wrapper `flex items-center gap-3`.

#### Badges & Pills
* **Dimensions:** `h-5` (20px height), `min-w-[20px]`, `px-1.5`, `rounded-full`
* **Typography:** `text-[11px] font-medium`

#### Icons (`lucide-vue-next` & `@tabler/icons-vue`)
* **Primary Nav Icons:** `size-4` (16px), `stroke-[1.5]`
* **Sub-menu / Detail Icons:** `size-3.5` (14px)
* **Action Header Icons:** `size-4` or `size-5`

#### Scrollbars
* **Width/Height:** `6px`
* **Thumb:** `bg-border rounded-full` -> `bg-muted-foreground` on hover
* **Track:** `transparent`

---

## 6. Available Source Layouts & Views

Reference template views in `/Users/deependrasankhala/Downloads/desgin-system-nr/src/views/`:

1. **Dashboard & Analytics:** `dashboard/DashboardView.vue`, `analytics/DashboardsView.vue`
2. **Support & Inbox:** `support/SupportView.vue`, `conversations/ConversationsView.vue`
3. **CRM & Deals:** `companies/CompaniesView.vue`, `deals/DealsView.vue`, `pipelines/PipelinesView.vue`
4. **AI (Daksh AI):** `ai/InboxesView.vue`, `ai/PlaygroundView.vue`, `ai/ScenariosView.vue`, `ai/ToolsView.vue`
5. **Campaigns & Marketing:** `campaigns/CampaignsView.vue`, `surveys/SurveysView.vue`, `reviews/ReviewsView.vue`
6. **Task & Project Management:** `todo/Todo.vue`, `project-management/ProjectManagementDashboard3.vue`
7. **Admin & Developer Portal:** `admin/BillingView.vue`, `admin/SettingsView.vue`, `developers/DevelopersOverview.vue`

---

*File generated from `/Users/deependrasankhala/Downloads/desgin-system-nr` design system specifications.*
