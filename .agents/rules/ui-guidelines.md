---
description: Strict UI Design Metrics for Relay AI (Typography, Colors, Spacing, and Components)
---

# UI Design Metrics & Guidelines

Follow these strict guidelines when creating or modifying UI components.

## 1. Typography (Fonts & Sizes)
- **Primary Font**: `Geist` (overriding Tailwind's default sans stack).
- **Monospace Font**: `Geist Mono`.
- **Section / Page Headings**: `text-base` (16px), `font-medium` (500 weight).
- **Empty State Headings**: Strict use of `text-[20px]`, `font-[600]` (no generic classes like `text-xl`).
- **Modal Form Labels**: `text-[13.5px]`, `font-medium`, `text-foreground`.
- **Modal Form Inputs/Textareas**: `text-[14px]`.

## 2. Color System (Strict Semantic Variables)
No hex codes or Tailwind static colors (e.g., `bg-blue-500`) are allowed. Everything relies on semantic CSS variables mapped for light and dark modes.

- **Backgrounds**: `bg-background`
- **Foregrounds / Text**: `text-foreground`
- **Cards & Popovers**: `bg-card`, `bg-popover`
- **Primary Action**: `bg-primary` with `text-primary-foreground`
- **Secondary**: `bg-secondary`
- **Muted (Subtle elements)**: `bg-muted` with `text-muted-foreground`
- **Accents (Hover states)**: `bg-accent`
- **Destructive (Errors)**: `bg-destructive`
- **Borders & Inputs**: `border-border`, `bg-input`
- **Focus Rings**: `ring-ring`

**Status & Priority Colors**:
- Success: `#00884b` (L), `#2ec18c` (D)
- Warning: `#dca600` (L), `#e9b928` (D)
- Priority 1 (High): `#e11d48` (L), `#ff6568` (D)
- Priority 2: `#f27000` (L), `#ff8b41` (D)
- Priority 3: `#dca600` (L), `#e9b928` (D)
- Priority 4 (Low): `#737373` (L), `#a1a1a1` (D)

## 3. Borders & Radius
- **Base Border Radius**: `0.75rem` (12px).
- **Radius Scale**:
  - `radius-sm`: 8px
  - `radius-md`: 10px
  - `radius-lg`: 12px
  - `radius-xl`: 16px
- **Ghost/Transparent Buttons**: Must have a defined subtle boundary (`border border-border` or `border-input` or `border-muted`), and the border is removed on hover (`hover:border-transparent`).

## 4. Layouts, Spacing, & Forms
- **Modal Forms**:
  - Spacing between label & input: `flex flex-col gap-1.5`.
  - Checkbox Wrappers: `flex items-center gap-3` (strictly no manual top margins like `mt-0.5`).
  - Inputs must have `shadow-sm rounded-md border-border/80 bg-background`.
  - Form Width limits: Maximum 600px width and horizontally centered.
- **Form Validation (Popups)**: Primary action buttons (Save/Create) must be disabled until required fields are met.

## 5. UI Elements & Components
- **Icons**:
  - Exclusively use `lucide-vue-next` and `@tabler/icons-vue`.
  - Icons inherit parent text color (`currentColor`) and use standardized sizing (`size-4` or `size-5`).
- **Focus States (Accessibility)**: Must always be visible on interactive elements (`focus-visible:ring-1 focus-visible:ring-primary/30`).
- **Scrollbars**: Custom 6px width scrollbars with `var(--border)` for the thumb (fully rounded corners), turning to `var(--muted-foreground)` on hover.

## 6. Animations & Effects
- **Popovers/Dropdowns**: Zoom-in/out scale animations originating from the trigger (`anim-pop-in` and `anim-pop-out`, scales 96% to 100%).
- **Dialogs/Modals**: Fade and translate upward animations (`anim-dialog-in` from -48% to -50% Y-axis).
- **Overlays**: Simple `anim-fade-in` and `anim-fade-out` for backdrops.

## 7. Core Experience & Developer Rules
- **No unstyled native HTML elements**: Any dropdown, date picker, or complex UI must be designed custom using Reka UI to match the design system — no browser-default popups.
- **Empty States**: Must have a temporary developer button at the very bottom to easily toggle mock data back and forth.
- **Dark Mode**: Relies purely on the `.dark` class added to `<html>`. No `@media (prefers-color-scheme)` media queries.
- **Copywriting**: The AI must consistently be referred to as "Relay AI" (never Captain AI or just Captain).
