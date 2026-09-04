# Engineering Rules

## 1. Strict Dependency Management
**Rule:** Do not introduce any new external libraries or dependencies.
**Context:** This project is a template boilerplate. Adding dependencies bloats the template and forces downstream consumers to adopt opinions they may not want. Stick to the provided Vue 3, Reka UI, and Tailwind v4 stack.

## 2. Layout-Level Error Handling
**Rule:** Use Vue's `onErrorCaptured` hook within global or layout components (e.g., in `src/layouts/`) to handle unexpected component failures.
**Context:** As a boilerplate, we want to catch errors gracefully without forcing developers to wrap every individual component in custom ErrorBoundary components. This keeps the component code clean and unopinionated.

## 3. Reusable Component Consistency
**Rule:** When building new UI elements, duplicate the architecture and styling patterns of existing components in `src/components/ui/`.
**Context:** The UI is heavily based on a `shadcn/ui` style port using `reka-ui`. Maintain the exact same props structure, Tailwind class merging (using `clsx` and `tailwind-merge`), and slot usage.

## 4. Class-Based Dark Mode
**Rule:** Rely on the `.dark` class applied to the HTML root for dark mode toggling, utilizing the mapped Tailwind CSS variables in `src/style.css`.
**Context:** Do not use media queries (`@media (prefers-color-scheme: dark)`) for component styles directly, as it breaks the manual toggle capability built into the theme store.

## 5. Overlay Backdrop Blur
**Rule:** Whenever designing overlays (modals, dialogs, drawers, full-screen panels), always use `backdrop-blur-[8px]` on the backdrop.
**Context:** Tailwind's `backdrop-blur-sm` is only 4px — do not use it for overlay backdrops. Prefer the shared Relay constant `RELAY_DIALOG_OVERLAY_CLASS` from `dashboard/components-next/relay/modal/constants.js` (includes `bg-background/80 backdrop-blur-[8px]`) so all overlays stay visually consistent. Put `data-relay-overlay` on the backdrop only — **never** `data-relay` on the backdrop (that applies an opaque shell background and hides the blur). Put `data-relay` on the modal panel instead.

## 6. Modal & Popup Form Fields
**Rule:** When designing forms inside pop-ups or modals, strictly use this field pattern:
- **Field wrapper:** `flex flex-col gap-1.5` between label and control.
- **Label:** `text-[13.5px] font-medium leading-normal text-foreground` (`RELAY_FORM_LABEL_CLASS`). Use `leading-normal` to override global `leading-7` on `<label>` — not `leading-none` (too tight).
- **Input / textarea:** `text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30`.
- **Checkbox row:** `flex items-center gap-3` on the label wrapper; never add manual top margins (e.g. `mt-0.5`).

**Context:** Use `RelayInput`, `RelayTextarea`, `RelayLabel`, and constants in `dashboard/components-next/relay/form/constants.js` (`RELAY_FORM_FIELD_CLASS`, `RELAY_FORM_LABEL_CLASS`, `RELAY_FORM_INPUT_CLASS`, `RELAY_FORM_CHECKBOX_ROW_CLASS`). See `relay/DESIGN.md` § Modals / forms.

## 7. Modal Header Layout
**Rule:** Every modal / dialog / drawer must use this header pattern before the form body:
- **Title:** `text-base font-medium tracking-tight text-foreground` (`RELAY_MODAL_TITLE_CLASS`).
- **Description:** `text-[14px] font-normal text-muted-foreground` directly under the title (`RELAY_MODAL_DESCRIPTION_CLASS`).
- **Divider:** Header wrapper ends with `border-b border-border/80` (`RELAY_MODAL_HEADER_CLASS`). Form fields start in the content area **below** this divider — never inside the header block.

**Context:** Constants live in `dashboard/components-next/relay/modal/constants.js`. Pair with `RELAY_DIALOG_OVERLAY_CLASS` for the backdrop (§5).
