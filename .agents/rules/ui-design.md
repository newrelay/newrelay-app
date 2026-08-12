---
trigger: always_on
---

---
trigger: always_on
---

# UI Design Quality (Tailwind)

## Mindset
Act like a design lead who gives every project a distinctive look — not a
templated default. Before building any new screen/page, pin down: who uses
this, and what's the ONE job this screen does. Design around that, not
around a generic dashboard/landing-page template.

## Avoid AI-generic defaults
Don't default to: cream background + orange/terracotta accent, or
near-black + single neon accent, or generic dashboard with 4 stat-cards +
icon + sidebar. These are templated, not chosen. Pick colors/layout that fit
THIS product's actual purpose and users.

## Process for new UI
1. Name the page's one job in one line.
2. Pick a small token set BEFORE coding: 4-6 colors (via tailwind.config.js
   theme), 2 font roles (display + body), spacing scale (Tailwind default).
3. Ask: does this look like what I'd build for any other similar page? If
   yes, change one thing to make it specific to this product/brand.
4. Build. Then self-check: mobile responsive, visible focus states, no
   redundant decoration.

## Structure & consistency
- Reuse existing components/patterns in the codebase first — check before
  creating new ones.
- One consistent style for buttons/forms/tables/modals across the app.
- Structural devices (numbered steps, badges, dividers) only when they
  encode real information (an actual sequence/status) — not decoration.
- Mobile-first: build small screen first, then md:/lg: breakpoints.

## Motion & polish
- Motion only where it serves the user: loading state, feedback on action,
  a deliberate reveal — not scattered hover effects everywhere.
- Spend visual boldness in ONE place (a signature element); keep the rest
  quiet and disciplined. Remove one decoration before calling it done.

## Copy in the UI
- Write from the user's side: name things by what they control, not by
  backend/system terms ("Save changes" not "Submit").
- Same word for the same action throughout a flow (button says "Publish" →
  confirmation says "Published").
- Errors state what went wrong and how to fix it — no vague messages, no
  apologizing tone.

## Tailwind specifics
- Only default spacing/sizing scale, no arbitrary values (`p-[13px]`) unless
  truly necessary.
- Colors via tailwind.config.js theme, never hardcoded hex in className.
- No inline style={{}}.
- No backdrop-blur/glassmorphism unless explicitly asked.

## What to avoid
- New npm packages for things Tailwind + a few utility classes already
  solve.
- Copy-pasting a component style from one page to another without checking
  if it fits this page's actual content/purpose.