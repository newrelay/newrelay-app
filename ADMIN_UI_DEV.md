# Super Admin UI Development

Restyle the Super Admin panel (`/super_admin`) with Docker + Cursor. No Ruby/Node/Postgres install needed locally.

The admin already uses **Tailwind + the Relay theme**, so "update the UI" = editing Tailwind classes in the existing files.

---

## Mac/Linux Setup

### 1. Prerequisite
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running.

### 2. First-time setup (once)
From the repo root:

```bash
docker compose build
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
```

`db:chatwoot_prepare` creates + migrates + seeds the database (this also creates the super admin login).

### 3. Start the app (every day)

```bash
docker compose up
```

This runs the full stack with **hot reload**: Rails (`:3000`), Vite, Sidekiq, Postgres, Redis, Mailhog.

Open: **http://localhost:3000/super_admin/sign_in**

Login:
- Email: `john@acme.inc`
- Password: `Password1!`

---

## Windows Setup

You install **Docker Desktop** once, then double-click a file.

### 1. One-time setup

1. Install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/).
   - If it asks to enable WSL 2 or restart, say **Yes**.
   - Open Docker Desktop and wait until it says **Running** (whale icon in the tray).
2. In Cursor: clone this repo and open the project folder.
3. In File Explorer, open that folder and **double-click `start-admin.bat`**.
   - First run takes **15–20 minutes**. Later runs are a few minutes.
   - **Keep the black window open** while you work.

### 2. Every day

1. Make sure Docker Desktop is **Running**.
2. Double-click **`start-admin.bat`**.
3. When ready, open: **http://localhost:3000/super_admin/sign_in**

Login:
- Email: `john@acme.inc`
- Password: `Password1!`

When done: close the black window, or double-click **`stop-admin.bat`**.

---

## What to Edit

| Change | File(s) |
|---|---|
| Colors / font / radius / spacing (global) | `app/javascript/dashboard/assets/scss/super_admin/index.scss`, `app/javascript/dashboard/assets/scss/_relay-theme.scss` |
| Page layout / Tailwind classes | `app/views/super_admin/**/*.html.erb` |

- Editing `.scss` → **hot reloads** in the browser.
- Editing `.html.erb` → **refresh the page** to see it.
- Use only Tailwind utility classes + Relay semantic tokens (`bg-primary`, `text-foreground`, `border-input`, etc.). No custom CSS.

---

## Ship Your Changes

You edit the real files, so just push and open a PR.

```bash
git checkout -b admin-ui
git add -A
git commit -m "style(admin): restyle <page>"
git push -u origin admin-ui
```

Then open a Pull Request. **Do not push to `main`.**

---

## Troubleshooting

| Problem | Solution |
|---|---|
| "Docker is not running" | Open Docker Desktop, wait for Running |
| Site won't load | Wait for black window to finish "Building…" / "Waiting for postgres" |
| Port already in use | Close other apps using 3000, or run `stop-admin.bat` |
| First start failed | Screenshot the black window error |

---

## Notes

- First `docker compose build` takes ~15–20 min (compiles frontend assets). After that, startup is fast.
- Stop: `Ctrl+C` or `docker compose down` (Mac/Linux) or close `start-admin.bat` window (Windows).
- Emails (verification, etc.) are caught locally — view at http://localhost:8025 (Mailhog).
