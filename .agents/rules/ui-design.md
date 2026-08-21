---
trigger: always_on
---

# UI Design Quality & System Specification (NewRelay)

## Authoritative Reference
All UI design and implementation must follow **[new-ui/DESIGN.md](file:///Users/deependrasankhala/Documents/chandresh/chatwoot/new-ui/DESIGN.md)** compiled from `/Users/deependrasankhala/Downloads/desgin-system-nr`.

## Mindset & Visual Language
- Target the high-efficiency, enterprise-grade feel of **Linear**, **Notion**, **Stripe**, and **HubSpot**.
- Design around the page's **One Job** (Jobs-to-be-Done).
- Use tight spacing, high-contrast borders (`border-border`), and a 12px base radius (`--radius-lg`).

## Strict Engineering & Styling Rules
1. **Tailwind Utilities Only:** Use `<script setup>` + Tailwind utilities. Never write inline styles (`style={{}}`), scoped CSS, or hardcoded hex colors (`bg-[#4f46e5]`).
2. **Semantic Tokens Only:** Use predefined custom properties (`bg-background`, `text-foreground`, `bg-card`, `bg-primary`, `border-input`, `text-muted-foreground`, `bg-sidebar`).
3. **Class-Based Dark Mode:** Dark mode is driven by the root `.dark` class. Do not use `@media (prefers-color-scheme)` or invent dark overrides.
4. **Relay Primitives:** Use `RelayButton`, `RelayInput`, `RelayLabel`, `RelayCheckbox`, `RelaySwitch`, `RelayBadge`, `RelayTabs*` from `dashboard/components-next/relay`.
5. **No Glassmorphism:** Solid backgrounds only (`bg-card`, `bg-popover`). Do not use `backdrop-blur`.

## Standard Metrics & Layouts
- **Buttons (`RelayButton`):** Default `h-9 px-4 text-sm shadow-xs rounded-md`. Small `h-8 px-3 text-xs`. Ghost buttons requiring borders: `border border-input hover:border-transparent`.
- **Inputs (`RelayInput`):** Default `h-9 px-3 text-sm rounded-md border-input bg-background shadow-xs`. Focus ring: `focus-visible:ring-1 focus-visible:ring-ring`.
- **Typography:** `Geist` for display/body, `Geist Mono` for code/metrics. Headings `text-base` or `text-xl font-semibold`. Form labels `text-[13.5px] font-medium text-foreground`.
- **Page Layout Shell:** `mx-auto flex h-full w-full max-w-7xl flex-col p-6 lg:px-10`. Inner page headers have **no** bottom border (`border-b`).