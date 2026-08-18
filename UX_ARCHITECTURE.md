# Enterprise UX & Information Architecture Redesign

**Project:** NewRelay  
**Objective:** Transform NewRelay into the easiest-to-learn, navigate, and operate Omni-Channel platform. We are targeting the premium, high-efficiency feel of HubSpot, Linear, Notion, and Stripe, rather than traditional CRM clunkiness.

---

## 1. Complete Information Architecture (IA)

We are structuring the IA around **Jobs-to-be-Done (JTBD)** rather than backend modules. This prevents the "everything everywhere" problem that plagues GoHighLevel.

### 🏠 1. Workspace (Daily Work)
- **Home:** Personalized Dashboard (Role-based metrics).
- **Inbox:** Unified Omni-Channel Inbox (Email, SMS, WhatsApp, Live Chat).
- **Tasks:** Actionable to-do list and upcoming appointments.

### 👥 2. CRM & Sales
- **Contacts & Companies:** Unified directory with smart segmentation.
- **Pipeline:** Visual drag-and-drop Kanban for deals.
- **Calendar:** Unified scheduling and appointments.

### 📢 3. Marketing & Engagement
- **Campaigns:** Multi-channel outbound (Email, SMS, Social).
- **Funnels & Pages:** Landing page builder and lead capture forms.
- **Reputation:** Review monitoring (Google, Yelp, Facebook).

### 🤖 4. AI & Automation (Daksh AI - First Class Citizen)
- **Captain (AI Agent):** Conversational interface for insights and quick actions.
- **Workflows:** Visual automation builder (Triggers & Actions).
- **Knowledge Base:** Training data for Daksh AI and team members.

### 📊 5. Analytics & Reports
- **Revenue & Pipeline:** Sales velocity and conversion rates.
- **Engagement:** Campaign performance and inbox response times.

### ⚙ 6. Administration (Configuration)
- **Workspace Settings:** Users, Roles, Billing.
- **Integrations:** API, Webhooks, Marketplace.

---

## 2. Complete Sidebar Structure

The sidebar must answer: *Where am I? What can I do here? What's next?*
We will use **Progressive Disclosure**. The sidebar will be split into **Main Navigation** and a **Contextual Sub-Navigation** that appears only when deep inside a module (Linear/Notion style).

**Global Sidebar (Persistent, Icon + Label):**
1. **Search (Ctrl+K)** - Global quick jump.
2. **Inbox** - Notification badge for unread messages.
3. **Pipeline** - Active deals.
4. **Contacts** - Database.
5. **Campaigns** - Outbound.
6. **Automation** - Workflows & AI.
7. **Reports** - Analytics.
8. **Captain (Daksh AI)** - Always accessible floating/bottom action.
9. **Settings** - Pushed to the bottom.

*(This aligns with the 6-8 item rule. The user clicks "Automation" and the main canvas changes, with a secondary local nav if needed).*

---

## 3. User Journey Mapping (Example: Sales Rep)

- **Trigger:** Rep starts their day.
- **Action:** Opens NewRelay. Lands on **Home Dashboard**.
- **Experience:** They don't see Marketing or Admin tools. They see *My Tasks*, *Upcoming Calls*, and *Unread Inbox Messages*.
- **Task:** Rep clicks a Task to "Follow up with John".
- **Flow:** A slide-out panel (Sheet) appears over the dashboard with John's CRM profile, previous conversation history, and an input box to send an SMS/Email instantly.
- **Resolution:** Task marked complete. Slide-out closes. Rep is back on the Dashboard without having navigated across 3 different pages.

---

## 4. Navigation Flow

- **Primary:** Sidebar (Vertical, Left).
- **Secondary (Within Module):** Horizontal Tabs or collapsible sub-menus.
- **Tertiary (Action):** Slide-out Sheets or Modals for creation (e.g., "New Contact") to prevent context loss.
- **Universal:** Command Palette (`Ctrl+K`) for jumping to any contact, page, or action.

---

## 5. Dashboard Layout Recommendations

- **Role-Based Views:**
  - *Owner:* Revenue graphs, overall team performance, system health.
  - *Sales:* Personal pipeline, tasks due today, recent lead activity.
  - *Support:* Unresolved tickets, average response time, inbox zero status.
- **Layout:** Masonry or Grid system. Cards should have a consistent header, data visualization, and a "View Report" secondary action.

---

## 6. Screen Hierarchy (Linear / Stripe Style)

1. **Page Header:** Big, bold title. Breadcrumbs if deeper than 2 levels.
2. **Page Actions:** Top right (e.g., Primary "Create" button, Secondary "Export/Filter" buttons).
3. **Content Area:** 
   - If Table: Sticky header, search bar on the left, filters on the right.
   - If Form: Max 600px width, centered, step-based if complex.

---

## 7. Feature Prioritization

- **Must Have:** Omni-Channel Inbox, Contact CRM, Command Palette (Ctrl+K), Daksh AI core integration, Role-based dashboards.
- **Nice to Have:** Custom reporting builder, visual workflow builder templates, bulk social media posting.
- **Advanced (Progressive Disclosure):** API Key generation, custom webhook mapping, advanced RBAC (Role-Based Access Control) matrix.

---

## 8. UX Improvements (vs. GoHighLevel)

| Feature | GoHighLevel Pain Point | NewRelay Solution |
| :--- | :--- | :--- |
| **Navigation** | Overwhelming, 20+ sidebar items, nested menus that get lost. | Flat, 7-item sidebar. Use Command Palette for edge cases. |
| **Inbox** | Clunky switching between SMS, Email, Social. | Unified threaded view (like Intercom/Slack). |
| **Automation** | Complex, developer-centric workflow builder. | Natural language AI workflow generation (Daksh AI). |
| **Settings** | A massive dump of unrelated toggles. | Categorized, searchable settings page (Stripe style). |

---

## 9. Accessibility Improvements

- **Color Contrast:** Strict WCAG AA compliance (4.5:1 ratio) for all text.
- **Keyboard Navigation:** Everything focusable (`tabindex`), visible focus rings (`focus-visible:ring-primary`).
- **Screen Readers:** `aria-labels` on all icon-only buttons (like the `SlidersHorizontal` filter button we built).
- **Motion:** Respect `prefers-reduced-motion` for transitions.

---

## 10 & 11. Mobile & Desktop Navigation Strategy

- **Desktop:** Fixed left sidebar (expandable/collapsible). Command Palette is the primary power-user tool.
- **Mobile:** Bottom tab bar for top 4 core jobs (Inbox, Tasks, Pipeline, Contacts). Hamburger menu for the rest. Actions moved to floating action buttons (FAB).

---

## 12. Future Scalability Strategy

- **Plugin/App Architecture:** As modules grow, they shouldn't clutter the core UI. Create an "App Marketplace" (like HubSpot) where users can enable/disable features (e.g., "Surveys"). Disabled features disappear from their UI completely.
- **Design Tokens:** Strict adherence to Tailwind CSS variables (`var(--primary)`, `var(--radius)`). No hardcoded pixel values.

---

## 13. Suggested Wireframes

### Unified Inbox (Concept)
```text
+----------------+---------------------------+-----------------------------------+
| [SB]           | Inbox (Filters)          | Chat: John Doe (Company X)        |
|                | +-----------------------+|                                   |
| Inbox          | | John Doe        [2m]  || John: Are you available?          |
|                | | Sure, I can do that.  ||                                   |
| Pipeline       | +-----------------------+| Me: Yes, let's chat tomorrow.     |
|                | | Sarah Smith     [1h]  ||                                   |
| Contacts       | | Sent an image.        || [Input Box: Type message...] [^]  |
|                | +-----------------------+|                                   |
| Daksh AI (bot) | | ...                   || Context Panel (Right Slide-out)   |
+----------------+---------------------------+-----------------------------------+
```
*Rationale:* Follows Slack/Intercom layout. Immediate context on the right prevents opening new tabs.

---

## 14. Component Hierarchy

1. **Atoms:** Button, Input, Avatar, Badge, Icon.
2. **Molecules:** SearchBar, DropdownMenu, FormField (Label + Input + Error), TableRow.
3. **Organisms:** DataGrid (Table + Pagination + Filters), TopNavigation, AppSidebar.
4. **Templates:** `DashboardLayout`, `SplitViewLayout` (e.g., Inbox), `SettingsLayout`.
5. **Pages:** The actual routed views.

---

## 15. UX Rationale for Key Recommendations

- **Why Command Palette (Ctrl+K)?**
  - *Problem:* Complex enterprise apps force users to click 5 times to find a specific setting or contact.
  - *Solution:* Command palettes eliminate navigation friction. It solves the GoHighLevel problem of "Where is X feature hidden?"
- **Why Slide-out Context Panels?**
  - *Problem:* Navigating to a Contact detail page forces a full page load, losing the user's place in the list.
  - *Solution:* Slide-outs keep the user anchored to their workflow, reducing cognitive load and saving time.
- **Why treat Daksh AI as a core feature?**
  - *Problem:* AI is often treated as a gimmick hidden behind a "sparkles" icon in a text editor.
  - *Solution:* By making Daksh a top-level feature (Captain), users can delegate workflows ("Summarize John's tickets", "Draft a campaign for inactive leads") rather than manually operating the UI.

---
*Prepared as part of the Enterprise UX Architecture Planning Phase.*
