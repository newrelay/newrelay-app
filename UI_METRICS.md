# UI Metrics & Design System Tokens

This document serves as a comprehensive reference for all UI metrics, spacing, typography, and styling rules currently enforced in the Design System.

## 1. Core Variables (Colors)

Light and Dark theme colors are defined in `src/style.css` using CSS custom properties mapped to the Tailwind v4 theme.

| Token | Light Theme (`:root`) | Dark Theme (`.dark`) | Purpose |
|-------|-----------------------|----------------------|---------|
| `--background` | `#ffffff` | `#10141d` | Main page background |
| `--foreground` | `#141822` | `#fafafa` | Primary text color |
| `--card` | `#ffffff` | `#181d27` | Card backgrounds |
| `--card-foreground` | `#141822` | `#fafafa` | Text inside cards |
| `--popover` | `#ffffff` | `#181d27` | Popover/dropdown backgrounds |
| `--popover-foreground` | `#141822` | `#fafafa` | Popover text |
| `--primary` | `#4f46e5` | `#6f71fb` | Primary brand color (buttons, active states) |
| `--primary-foreground` | `#fafafa` | `#fafafa` | Text on primary backgrounds |
| `--secondary` | `#f2f4f9` | `#242933` | Secondary backgrounds |
| `--secondary-foreground` | `#222938` | `#fafafa` | Text on secondary backgrounds |
| `--muted` | `#f2f4f9` | `#242933` | Muted/subtle backgrounds |
| `--muted-foreground` | `#6c727e` | `#9ba2ae` | Muted/subtle text |
| `--accent` | `#edf0ff` | `#2c304c` | Accent backgrounds (hover states) |
| `--accent-foreground` | `#30327a` | `#e2e7fc` | Accent text |
| `--destructive` | `#e11d48` | `#ff6568` | Destructive/error backgrounds |
| `--destructive-foreground` | `#f8fafc` | `#f8fafc` | Text on destructive backgrounds |
| `--border` | `#e4e7ee` | `#ffffff1a` | Standard border color |
| `--input` | `#e4e7ee` | `#ffffff26` | Input borders |
| `--ring` | `#4f46e5` | `#6f71fb` | Focus ring color |

### Sidebar Specific Colors
| Token | Light Theme | Dark Theme |
|-------|-------------|------------|
| `--sidebar` | `#f9fafd` | `#181d27` |
| `--sidebar-foreground` | `#141822` | `#fafafa` |
| `--sidebar-primary` | `#4f46e5` | `#6f71fb` |
| `--sidebar-primary-foreground` | `#fafafa` | `#fafafa` |
| `--sidebar-accent` | `#edf0ff` | `#2c304c` |
| `--sidebar-accent-foreground` | `#30327a` | `#e2e7fc` |
| `--sidebar-border` | `#e4e7ee` | `#ffffff1a` |
| `--sidebar-ring` | `#4f46e5` | `#6f71fb` |

### Chart & Status Colors
| Token | Light Theme | Dark Theme |
|-------|-------------|------------|
| `--chart-1` | `#6d74f5` | `#7f8aff` |
| `--chart-2` | `#6c50e9` | `#7f68ff` |
| `--chart-3` | `#4f46e5` | `#819eff` |
| `--chart-4` | `#7290fa` | `#5e55ed` |
| `--chart-5` | `#4435bc` | `#5a47cf` |
| `--priority-1` | `#e11d48` | `#ff6568` |
| `--priority-2` | `#f27000` | `#ff8b41` |
| `--priority-3` | `#dca600` | `#e9b928` |
| `--priority-4` | `#737373` | `#a1a1a1` |
| `--success` | `#00884b` | `#2ec18c` |
| `--warning` | `#dca600` | `#e9b928` |

## 2. Typography

- **Sans-serif Font:** `'Geist', ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`
- **Monospace Font:** `'Geist Mono', 'SFMono-Regular', ui-monospace, Menlo, Monaco, Consolas, monospace`

### Established Font Sizes & Styling Rules
- **Section/Page Headings:** `text-base` (16px), `font-medium` (500)
- **Empty State Headings:** `text-[20px]`, `font-[600]`
- **Modal Form Labels:** `text-[13.5px] font-medium text-foreground`
- **Modal Form Inputs:** `text-[14px]`
- **Badges/Pills:** `text-[11px] font-medium` (e.g., sidebar notification counts)
- **Sub-navigation Links:** `text-[13px]`

## 3. Radii (Border Radius)

The base radius is `0.75rem` (`12px`).
- `--radius-sm`: `calc(var(--radius) - 4px)` = `8px`
- `--radius-md`: `calc(var(--radius) - 2px)` = `10px`
- `--radius-lg`: `var(--radius)` = `12px`
- `--radius-xl`: `calc(var(--radius) + 4px)` = `16px`

## 4. Standard Component Dimensions & Layouts

### Buttons (`Button.vue`)
- **Default:** `h-9` (36px height), `px-4 py-2`, `text-sm`, `shadow-xs`
- **Small (`sm`):** `h-8` (32px height), `px-3`, `text-xs`, `rounded-md`
- **Large (`lg`):** `h-10` (40px height), `px-6`, `rounded-md`
- **Icon:** `size-9` (36px width & height)

### Inputs (`Input.vue`)
- **Dimensions:** `h-9` (36px height), `px-3 py-1`, `w-full`
- **Styling:** `rounded-md border border-input bg-background shadow-xs text-sm transition-colors`
- **Focus State:** `focus-visible:ring-1 focus-visible:ring-ring focus-visible:outline-hidden`

### Modal Forms (Strict Rules)
- **Label-Input Spacing:** `flex flex-col gap-1.5`
- **Checkbox Wrappers:** `flex items-center gap-3` (strictly avoid manual top margins like `mt-0.5`)
- **Input Styling (Popup/Modal specific):** `shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30`

## 5. UI Behaviors & Constraints

- **Transparent (Ghost) Buttons:** Always add a subtle grey border (e.g., `border border-border`, `border border-input`, or `border border-muted`). Remove border on hover (`hover:border-transparent`).
- **Form Validation:** Primary action buttons ("Create", "Save", "Submit") must remain disabled unless all required fields are correctly filled.
- **Empty States:** Must include a temporary developer button at the very bottom to populate mock data or toggle to the working state.
- **Custom Components:** Never rely on unstyled native HTML elements for complex functionality (like dropdowns, date pickers) if they trigger browser-default popups. They must blend into the design system semantics.
- **Color Usage:** Never use random or hardcoded Tailwind colors (e.g. `bg-blue-100`). Always map to dynamic semantic variables to ensure light/dark mode compatibility.

## 6. Icons & Badges

- **Standard Sidebar Icons:** `size-4` (16px) with `stroke-[1.5]`
- **Sub-menu Sidebar Icons:** `size-3.5` (14px)
- **Badge/Pill:** `h-5` (20px height), `min-w-[20px]`, `px-1.5`, `rounded-full`, `text-[11px] font-medium`

## 7. Scrollbars

A sleek, minimal scrollbar is applied globally:
- **Dimensions:** `6px` width/height
- **Thumb:** `bg-border`, `rounded-full` (`9999px`), changes to `bg-muted-foreground` on hover.
- **Track:** `transparent`
