# Admin UI Dev Guide

Restyle the Super Admin panel (`/super_admin`) with only Docker + Cursor. No Ruby/Node/Postgres install.

The admin already uses **Tailwind + the Relay theme**, so "update the UI" = editing Tailwind classes in the existing files. No rewrite, no Vue.

## 1. Prerequisite

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running.

## 2. First-time setup (once)

From the repo root:

```bash
docker compose build
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
```

`db:chatwoot_prepare` creates + migrates + seeds the database (this also creates the super admin login below).

## 3. Start the app (every day)

```bash
docker compose up
```

This runs the full stack with **hot reload**: Rails (`:3000`), Vite, Sidekiq, Postgres, Redis, Mailhog.

Open: **http://localhost:3000/super_admin/sign_in**

Login:
- Email: `john@acme.inc`
- Password: `Password1!`

## 4. What to edit

| Change | File(s) |
|---|---|
| Colors / font / radius / spacing (global) | `app/javascript/dashboard/assets/scss/super_admin/index.scss`, `app/javascript/dashboard/assets/scss/_relay-theme.scss` |
| Per-page look (Tailwind classes on markup) | `app/views/super_admin/**/*.html.erb` |

- Editing `.scss` → **hot reloads** in the browser.
- Editing `.html.erb` → **refresh the page** to see it.
- Use only Tailwind utility classes + the Relay semantic tokens (`bg-primary`, `text-foreground`, `border-input`, etc.). No custom CSS, no inline styles.

## 5. Ship your changes

You edit the real files, so there is nothing to "port" — just push a branch and open a PR.

```bash
git checkout -b admin-ui
git add -A
git commit -m "style(admin): restyle <page>"
git push -u origin admin-ui
```

Then open a Pull Request on GitHub. **Do not push to `main`.**
After it's reviewed and merged, it auto-deploys to the test server.

## Notes

- First `docker compose build` takes ~15–20 min (it compiles all frontend assets). After that, startup is fast.
- Stop everything: `Ctrl+C`, or `docker compose down`.
- Emails (verification, etc.) are caught locally — view them at http://localhost:8025 (Mailhog).
