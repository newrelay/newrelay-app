# Customer Engagement UI — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Inbox and Conversations match Downloads NewRelay-UI-main visually, without changing Chatwoot data, routes, or permissions.

**Architecture:** Port markup and Tailwind classes from the mock views onto the Chatwoot files that actually render. Keep Vuex, i18n, and feature flags. Do not paste the mock’s dummy data, demo toggles, or hardcoded hex.

**Tech Stack:** Vue 3 `<script setup>`, Relay primitives, Tailwind semantic tokens, Geist.

**Spec:** This file. Design source of truth: `/Users/deependrasankhala/Downloads/NewRelay-UI-main` (`src/views/inbox/InboxView.vue`, `src/views/conversations/ConversationsView.vue`). Not `Documents/chandresh/NewRelay-UI`.

## Global Constraints

- Design folder: `/Users/deependrasankhala/Downloads/NewRelay-UI-main` only.
- Copy classes, keep Chatwoot logic. No bare strings — EN i18n only (`en.json`).
- Semantic tokens only (`bg-primary`, `text-muted-foreground`). Never hex, never `bg-red-100` / `bg-[#EEF2FF]`.
- Tabs on `<button>`: use an absolute `h-0.5 bg-primary` bar. `border-b-2` is overridden by global `button { border: 0 }` and will not show.
- Do not add mock “Explore Demo Workspace” / “Toggle empty states” developer buttons.
- Do not restyle Settings, CRM, Workspace, or Relay AI in this pass.
- Keep Chatwoot Folders under Conversations (product extra, not in the mock).

---

## Why previous AI ports looked unfinished

1. **Wrong design folder.** Porting map points at `Documents/chandresh/NewRelay-UI`. You are matching Downloads.
2. **Wrong card file.** The live Conversations list uses `app/javascript/dashboard/components/widgets/conversation/ConversationCard.vue`. The next-gen card at `components-next/Conversation/ConversationCard/ConversationCard.vue` is used by Companies history, not the side-menu Conversations page. Editing next-gen does nothing here.
3. **Inbox ≠ Conversations.** Inbox is a 260px Views/Channels rail + email-style list. Conversations is a 320px Mine/Unassigned/All list + thread. Copying one chrome onto the other looks “half ported”.
4. **Tabs on buttons.** Mine/Unassigned/All in `ChatList.vue` still use `border-b-2` on `RelayTabsTrigger` (a button). Active underline never paints.
5. **Active row token.** Live card uses `bg-conversation-list-highlight` (`#f6f5fd`). Mock uses `bg-primary/5`.

## File map (touch only these)

| Surface | Mock | Live Chatwoot file |
|---|---|---|
| Inbox shell | `InboxView.vue` left `w-[260px]` | `routes/dashboard/inbox/InboxList.vue` |
| Inbox header | h-14 title + Display + gear | `inbox/components/InboxListHeader.vue` |
| Inbox views/channels | VIEWS / CHANNELS lists | `inbox/components/InboxSidebarNav.vue` |
| Inbox row | email-style row | `components-next/Inbox/InboxCard.vue` |
| Inbox empty | “Your Inbox is Ready” / channel empty | `inbox/InboxEmptyState.vue` |
| Inbox thread | conversation pane | `inbox/InboxView.vue` (wraps `ConversationBox`) |
| Conversations list shell | `w-[300px] lg:w-[320px]` | `components/ChatList.vue` |
| Conversations rows | `p-3 rounded-lg` cards | `components/widgets/conversation/ConversationCard.vue` via `ConversationItem.vue` |
| Conversations empty | onboarding / no messages / all set | `components/widgets/conversation/OnboardingView.vue` |
| Thread + composer | mock column 2 | `ConversationBox.vue` + composer widgets — **out of this plan unless a header-only pass is added** |

Do **not** edit for this pass: `components-next/Conversation/ConversationCard/ConversationCard.vue` (wrong surface).

---

### Task 1: Pin the design source so the next agent cannot miss

**Files:**
- Modify: `app/javascript/dashboard/components-next/relay/NEWRELAY_PORTING_MAP.md` (reference project line + conversations/inbox row)

**Interfaces:**
- Consumes: Downloads path above
- Produces: Porting map that names Downloads as SoT for Customer Engagement

- [ ] **Step 1:** Change the reference project line to `/Users/deependrasankhala/Downloads/NewRelay-UI-main`.
- [ ] **Step 2:** In §3, add a warning: live Conversations cards = `widgets/conversation/ConversationCard.vue`, not `components-next/.../ConversationCard.vue`.
- [ ] **Step 3:** Commit: `docs(relay): pin Downloads NewRelay-UI as Customer Engagement source`

---

### Task 2: Conversations tabs — visible active underline

**Files:**
- Modify: `app/javascript/dashboard/components/ChatList.vue` (Mine / Unassigned / All `RelayTabsTrigger` block ~966–987)

**Canonical markup** (same pattern as Inbox status tabs and `relay-underline-tabs.mdc`):

```vue
<RelayTabsTrigger
  :value="tab.key"
  class="relative -mb-px px-0 py-2 text-sm font-medium rounded-none bg-transparent shadow-none text-muted-foreground hover:text-foreground aria-selected:text-foreground aria-selected:shadow-none"
>
  {{ tab.name }}
  <span
    v-if="activeAssigneeTab === tab.key"
    class="absolute inset-x-0 bottom-0 h-0.5 bg-primary"
    aria-hidden="true"
  />
</RelayTabsTrigger>
```

- [ ] **Step 1:** Replace `border-b-2` / `aria-selected:border-primary` on these triggers with the absolute bar.
- [ ] **Step 2:** Browser: open Conversations, click Mine → Unassigned → All. Active tab must show a 2px primary bar. Inactive text `text-muted-foreground`.
- [ ] **Step 3:** Commit: `fix(conversations): show Mine/Unassigned/All underline on buttons`

---

### Task 3: Conversations list row — match mock hover/active

**Files:**
- Modify: `app/javascript/dashboard/components/widgets/conversation/ConversationCard.vue`

Mock classes to match:

```
flex gap-3 p-3 rounded-lg text-left
active → bg-primary/5
idle hover → hover:bg-accent/50
avatar → size-10 rounded-full border border-border/50
name → text-sm font-semibold truncate text-foreground
time → text-[11px] font-medium text-muted-foreground
snippet → text-[13px] text-muted-foreground truncate leading-snug
channel → text-[12px] text-muted-foreground/70 truncate
unread/status → size-2 rounded-full
```

Live card already has size/typography. Remaining gap is highlight classes.

- [ ] **Step 1:** Change active from `bg-conversation-list-highlight` to `bg-primary/5`. Change hover from `hover:bg-conversation-list-highlight` to `hover:bg-accent/50`. Keep `rounded-lg p-3`.
- [ ] **Step 2:** Browser: select a row — background is indigo wash, not grey-violet `#f6f5fd`. Hover on unselected rows is `accent/50`.
- [ ] **Step 3:** Commit: `fix(conversations): match list card active/hover to NewRelay`

---

### Task 4: Conversations list header — title + in-list search

**Files:**
- Modify: `app/javascript/dashboard/components/ChatList.vue` header (~904–965)

Mock:

```
h-14 px-4 border-b border-border
title: text-base font-medium
filter suffix: text-[14px] font-medium text-muted-foreground  →  "Conversations / All conversation"
search icon button; expanded field:
  h-8 pl-8 pr-8 text-[13px] bg-muted/30 border border-border/80 rounded-md
  focus-visible:ring-1 focus-visible:ring-primary/30
```

Chatwoot header is already close (`h-16` vs mock `h-14` is the remaining chrome gap). Prefer `h-14` to match Inbox header height.

- [ ] **Step 1:** Align header to `h-14 px-4`. Keep Chatwoot `pageTitle` + filter suffix. Keep existing search open/close behaviour.
- [ ] **Step 2:** Browser: title reads `Conversations / {filter}` at 16px/14px. Search expands in the header, not a new page.
- [ ] **Step 3:** Commit: `fix(conversations): match list header height and search field`

---

### Task 5: Inbox header — Display menu + overflow actions

**Files:**
- Modify: `routes/dashboard/inbox/components/InboxListHeader.vue`
- Modify: `routes/dashboard/inbox/components/InboxDisplayMenu.vue` (or inline)

Mock header actions:

- Title `text-[16px] font-[500]` (not `font-semibold`)
- Outline **Display** `h-8 px-3`: Sort Newest/Oldest submenu + checkboxes Snoozed, Read
- Icon **gear** `size-8`: Mark all as read, Delete all, Delete all read — wire only to existing Chatwoot notification/conversation actions; hide or disable delete-all if no API

- [ ] **Step 1:** Title class → `text-[16px] font-[500]`.
- [ ] **Step 2:** Display menu: sort + snoozed/read checkboxes. Bind to existing `inbox_filter_by` UI settings / current sort dispatch. Do not invent new backend filters.
- [ ] **Step 3:** Add overflow icon menu. Mark-all-as-read must call the existing store action. Skip delete-all if there is no endpoint.
- [ ] **Step 4:** Browser: Inbox left header matches mock density; Display actually changes sort.
- [ ] **Step 5:** Commit: `fix(inbox): match list header Display menu to NewRelay`

---

### Task 6: Inbox empty states — copy and density, not new products

**Files:**
- Modify: `routes/dashboard/inbox/InboxEmptyState.vue`
- i18n: `app/javascript/dashboard/i18n/locale/en.json` (INBOX keys only)

Mock no-channel empty:

- Icon: `size-16 rounded-full bg-primary/10 ring-8 ring-primary/5` + inbox icon `size-8 text-primary`
- Heading: keep `text-[20px] font-[600]` (already used)
- CTA primary “Connect a Channel” → existing settings inbox route
- Ghost “Learn how Inbox works”
- Supported-channel row: `size-12 rounded-xl border border-border bg-card` icons. Use Lucide / existing brand icons, **no Wikipedia SVG URLs, no hex icon colors**

Mock channel-selected empty (optional if time): heading `No {channel} conversations yet` + three cards (test / invite / settings) linking to real Chatwoot routes.

- [ ] **Step 1:** Align no-channel empty icon/CTA row with mock spacing. Keep Chatwoot i18n.
- [ ] **Step 2:** If a channel view is selected and the list is empty, show the channel empty heading, not the generic “Inbox is Ready”.
- [ ] **Step 3:** Browser: no-channel vs has-channel vs has-channel-but-empty-list are three different screens.
- [ ] **Step 4:** Commit: `fix(inbox): match empty states to NewRelay`

---

### Task 7: Inbox list row polish (only leftovers)

**Files:**
- Modify: `components-next/Inbox/InboxCard.vue`

Mock loaded inbox is an **email table row** (star, 32px avatar, name column, subject + snippet, time). Chatwoot already uses that layout.

Leftovers:

- Replace `text-[#b6872d]` star hover with `text-warning` (or `text-primary`) so dark mode works
- Replace `bg-red-100 text-red-600` PDF pills with `bg-destructive/10 text-destructive`
- Active row already `bg-primary/5` — keep it

- [ ] **Step 1:** Remove hardcoded hex / `red-100` from InboxCard.
- [ ] **Step 2:** Browser: starred + PDF attachment + unread + selected row in light and dark.
- [ ] **Step 3:** Commit: `fix(inbox): tokenise InboxCard colours`

---

### Task 8: Conversations empty / onboarding (verify, then patch)

**Files:**
- Modify: `components/widgets/conversation/OnboardingView.vue` only if a class string differs

Mock states (when list is empty):

1. No channels → stepper “Step N of 4” + integration cards (WhatsApp featured emerald, others outline)
2. Channels connected, no chats → “You're all set!” `text-[20px] font-[600]`
3. Filter with no results → “No messages found” `text-[20px] font-[600]`

Chatwoot already has OnboardingView. Do not add Load Demo Workspace.

- [ ] **Step 1:** Diff OnboardingView classes against mock stepper + channel cards. Patch only mismatched class strings.
- [ ] **Step 2:** Confirm empty-list-with-channels uses the “all set” heading, not the connect-channel stepper.
- [ ] **Step 3:** Browser: account with no inboxes; account with inboxes and zero conversations; Mentions filter with zero hits.
- [ ] **Step 4:** Commit only if classes changed: `fix(conversations): match onboarding empty to NewRelay`

---

## Out of this plan (do not start)

- Pixel-perfect message bubbles / composer inside `ConversationBox` (legacy widget tree; own spec).
- Contact right sidebar redesign.
- Voice call overlay (already mapped to `FloatingCallWidget`).
- Deleting Folders from the Conversations tree.
- Copying mock hardcoded `#EEF2FF` empty icons (use `bg-primary/10`).

## Browser check (required before calling it done)

1. Sidebar → Inbox: 260px rail, VIEWS + CHANNELS, Display, empty vs list vs open thread.
2. Sidebar → Conversations → All: `Conversations / All conversation`, Mine/Unassigned/All underline visible, row active `bg-primary/5`.
3. Mentions / Participating / Unattended / a Team / a Channel / a Label: title suffix updates; same list chrome.
4. Dark mode on both pages: no leftover hex, no `red-50` stars.
5. Folders still appear under Conversations.

## Execution

After this plan is approved: run Task 1 → 2 → 3 first (highest visual payoff, smallest files). Then Inbox header/empty. Thread/composer is a follow-up spec.
