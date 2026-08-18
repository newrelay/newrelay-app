# Branding & Design System Guidelines

## Core Principles
This boilerplate relies on a highly curated, premium aesthetic inspired by modern dashboard design (shadcn/ui style). The visual language relies on tight spacing, high-contrast borders, and carefully selected typography.

## Typography
- **Primary Font:** Geist (`@fontsource-variable/geist`)
- **Monospace Font:** Geist Mono (`@fontsource-variable/geist-mono`)
- **Usage:** Rely on Tailwind's default sans stack which has been overridden in `style.css` to use Geist. Do not introduce custom Google fonts.

## Color System & Variables
All colors are managed via CSS variables in `src/style.css` to allow seamless dark mode switching and theming.

**Never hardcode hex colors in Tailwind utility classes.**
- ❌ **Incorrect:** `bg-[#4f46e5] text-white`
- ✅ **Correct:** `bg-primary text-primary-foreground`

### Semantic Mapping:
- **Backgrounds:** `bg-background`, `bg-card`, `bg-popover`, `bg-muted`
- **Text:** `text-foreground`, `text-muted-foreground`
- **Accents:** `bg-primary`, `bg-secondary`, `bg-destructive`
- **Borders:** `border-border`, `ring-ring`

## Dark Mode Implementation
Dark mode is implemented via the `.dark` class applied to the root element.
- Do not use Tailwind's `dark:` modifier prefix for colors unless absolutely necessary for a one-off exception.
- Our CSS variables in `style.css` automatically adjust their hex values when the `.dark` class is present.

## Iconography
- **Libraries:** Strictly use `lucide-vue-next` and `@tabler/icons-vue`.
- **Styling:** Icons should inherit text color by default (`currentColor`) and use standardized sizing (e.g., `size-4`, `size-5`).
