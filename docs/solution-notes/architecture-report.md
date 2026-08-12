# CRM Contacts Overhaul — Complete Code Architecture Specification

This document provides the blueprint of the front-to-back architecture implemented for the **Contacts Board & Smart Lists Overhaul**.

---

## 1. File-by-File Code Architecture Blueprint

The system is organized into decoupled layers, ensuring backend security and performance, and frontend flexibility and responsiveness.

```
[PostgreSQL Database]
       │
       ▼ (ActiveRecord Models & Migrations)
[Model Layer] ── (Pundit Policies) ──► [Security Auth]
       │
       ▼ (Controllers & Jbuilder Templates)
[REST API Endpoints]
       │
       ▼ (Axios API Clients)
[Frontend Clients]
       │
       ▼ (Router child sub-routes)
[Layout & Views Layer] (Vue 3 / Composition API)
```

### 1.1 Database & Migration Layer
- **`db/migrate/20260703103500_create_tasks.rb`**: Sets up the `tasks` table and the many-to-many join table `contact_tasks` with a unique composite index to link tasks and contact records.
- **`db/migrate/20260703103501_create_bulk_action_audits.rb`**: Sets up the audit tracking table `bulk_action_audits` to record background batch actions.

### 1.2 ActiveRecord Model Layer (Backend Business Logic)
- **`app/models/task.rb`**: Manages task records. Validates title presence, belongs to `Account` and optionally `Assignee` (`User`), and has many `contacts` through `contact_tasks`.
- **`app/models/contact_task.rb`**: Serves as the join model linking contacts and tasks.
- **`app/models/bulk_action_audit.rb`**: Stores statistical numbers, operation types, initiating users, and status values (pending, processing, completed, failed) for batch operations.
- **`enterprise/app/models/company.rb`**: Manages corporate registries and groups associated contacts under a single business entity.

### 1.3 REST Controller & Serialization Layer
- **`app/controllers/api/v1/accounts/tasks_controller.rb`**: Exposes endpoints for CRUD operations. It handles complex search and date filtering (Due Today, Overdue, Upcoming) using private query compilation helpers to ensure RuboCop compliance.
- **`app/controllers/api/v1/accounts/bulk_action_audits_controller.rb`**: Serves audit logs to the client.
- **`enterprise/app/controllers/api/v1/accounts/companies_controller.rb`**: Manages company entities.
- **`enterprise/app/views/api/v1/models/_company.json.jbuilder`**: Serializes company fields, including standard columns and dynamic address parameters stored inside the `additional_attributes` column.

### 1.4 Pundit Security Policies
- **`app/policies/task_policy.rb`**: Authorizes task actions. Ensures agents can only view/modify tasks belonging to their active Account.
- **`app/policies/bulk_action_audit_policy.rb`**: Restricts access to audit logs based on account scopes.

### 1.5 Frontend API Service Clients
- **`app/javascript/dashboard/api/tasks.js`**: Extends `ApiClient` to wrap CRUD calls to the backend task routes.
- **`app/javascript/dashboard/api/companies.js`**: Wraps backend company REST routes and handles custom search parameters.

### 1.6 Frontend Router & Layout Layer
- **`app/javascript/dashboard/routes/dashboard/contacts/routes.js`**: Replaced the main contacts route with `ContactsPageRouteView.vue` and configured child paths for `/contacts`, `/bulk-actions`, `/tasks`, and `/companies`.
- **`app/javascript/dashboard/routes/dashboard/contacts/pages/ContactsPageRouteView.vue`**: Renders the unified header sub-navigation bar to switch between CRM sub-views.

### 1.7 Frontend Views & Components (Vue 3 Composition API)
- **`app/javascript/dashboard/components-next/Contacts/Pages/ContactsTable.vue`**: Spreadsheet-style contact grid supporting checkboxes, action menus, and relative activity indicators.
- **`app/javascript/dashboard/components-next/Contacts/ColumnManager.vue`**: Popover that allows checking/unchecking visible columns and custom attribute fields.
- **`app/javascript/dashboard/components-next/Contacts/Drawers/AddContactDrawer.vue`**: Granular creation form with radio buttons for primary email/phone fields, searchable timezone listings, and checkboxes to disable specific communication channels (DND).
- **`app/javascript/dashboard/routes/dashboard/contacts/pages/TasksView.vue`**: Interactive task checklist showing total count badge, due-filter tabs, search, and slide-out dialogs for adding/editing tasks.
- **`app/javascript/dashboard/routes/dashboard/contacts/pages/CompaniesView.vue`**: Corporate registry displaying company details (name avatar, phone, email, website links, address, description) and featuring a slide-over drawer to create and update company records.

---

## 2. Advantages (Pros) of this Architecture

1. **High Modularization & Maintenance**:
   - Frontend and backend operations for Contacts, Tasks, Companies, and Audits are kept in separate components and API wrappers. This makes debugging isolated issues simple.
2. **Backwards Compatibility & Safe Scaling**:
   - Incorporating phone, email, state, and city fields inside `additional_attributes` (JSONB columns) for companies avoids executing expensive database migrations, which could lock massive production databases.
3. **Optimized Read Performance**:
   - Views like `TasksView` and `CompaniesView` run paginated list requests and load details dynamically. In addition, search inputs are debounced before invoking APIs to prevent request storms.
4. **State Persistence**:
   - Storing column visibility settings in the user's profile configuration using the `useUISettings` composable ensures visible columns persist across sessions.
5. **Favicon Automatic Retrieval**:
   - Extracting domain details from websites to trigger asynchronous favicon fetching keeps company logos automatically updated.

---

## 3. Disadvantages (Cons) of this Architecture

1. **JSONB Query Scanning**:
   - Queries filtering or sorting directly on nested properties (like state or city inside `additional_attributes`) require sequential scans by PostgreSQL. In large systems, this requires adding custom PostgreSQL GIN indexes to maintain speed.
2. **Schema Control at Application-Level**:
   - Since nested fields inside JSONB are unstructured, the database cannot enforce field formats or type constraints (e.g., verifying a string is a valid email). Type validation must be managed entirely in Rails.
3. **Enterprise Overlay Drift**:
   - Since company features reside under the `enterprise/` directory structure, developers must make sure that changes are aligned with the open-source code to avoid sync issues.
