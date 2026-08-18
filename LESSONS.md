# Project Lessons & Historical Context

This document captures key learnings, decisions, and context for why certain approaches were taken in this boilerplate repository.

## 1. Error Handling Strategy (Layout-Level vs Component-Level)
**Lesson:** In Vue 3, we opted for Layout-Level error handling using `onErrorCaptured` inside of layout wrappers rather than granular `<ErrorBoundary>` components.
**Why:** Vue 3 lacks a native React-style ErrorBoundary component. Building one requires heavy use of slots and forces consumers of this template to manually wrap their components. By placing `onErrorCaptured` in layout shells, we keep the template unopinionated and reduce friction for engineers building on top of this repository.

## 2. UI Primitives vs Framework-Coupled Libraries
**Lesson:** We use `reka-ui` for unstyled accessibility primitives instead of a heavy, pre-styled component library like Vuetify.
**Why:** This repository is intended to be an adaptable Design System boilerplate. `reka-ui` handles complex accessibility, focus management, and keyboard navigation, while allowing us to completely control the visual output via Tailwind CSS variables in `style.css`. 

## 3. Strict Dependency Control
**Lesson:** We enforce a strict "no new libraries" rule.
**Why:** Boilerplates quickly become deprecated or disliked if they force too many opinions. The current stack (Vue, Vite, Tailwind, Pinia, Playwright) is standard. Any additional state fetching (Vue Query) or Auth (Clerk) is intentionally left up to the end-user unless officially supported by the core team.
