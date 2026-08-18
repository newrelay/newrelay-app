# Super Admin UI — Windows (for UI developers)

You do **not** install Ruby, Rails, Postgres, or Redis.
You install **Docker Desktop** once, then double-click a file.

Use **Cursor** to edit. The running app is Docker — you never type Docker commands.

---

## One-time setup

1. Install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/).
   - If it asks to enable WSL 2 or restart, say **Yes**.
   - Open Docker Desktop and wait until it says **Running** (whale icon in the tray).
2. In Cursor: clone this repo and open the project folder.
3. In File Explorer, open that folder and **double-click `start-admin.bat`**.
   - First run takes **15–20 minutes**. Later runs are a few minutes.
   - **Keep the black window open** while you work.

---

## Every day

1. Make sure Docker Desktop is **Running**.
2. Double-click **`start-admin.bat`**.
3. When it is ready, open: **http://localhost:3000/super_admin/sign_in**

Login:

- Email: `john@acme.inc`
- Password: `Password1!`

When you finish: close the black window, or double-click **`stop-admin.bat`**.

---

## What to edit in Cursor

| What you want to change | File |
|---|---|
| Colors, font, radius, spacing | `app/javascript/dashboard/assets/scss/super_admin/index.scss` and `app/javascript/dashboard/assets/scss/_relay-theme.scss` |
| Page layout / Tailwind classes | `app/views/super_admin/**/*.html.erb` |

- Style files (`.scss`) update in the browser by themselves.
- Page files (`.html.erb`) need a **browser refresh** (Ctrl+R).
- Use Tailwind classes and Relay tokens (`bg-primary`, `text-foreground`, `border-input`). No custom CSS, no inline styles.

---

## Send your work

In Cursor: Source Control → type a message → **Commit** → **Push**.
Open a Pull Request. **Do not push to `main`.**

---

## If something is wrong

| Problem | What to do |
|---|---|
| "Docker is not running" | Open Docker Desktop, wait for Running, double-click `start-admin.bat` again |
| Site will not load | Wait until the black window stops printing "Building…" / "Waiting for postgres". Then try http://localhost:3000/super_admin/sign_in |
| Port already in use | Close other apps using port 3000, or run `stop-admin.bat` then start again |
| First start failed | Screenshot the black window and send it |

You never need to type `docker`, `rails`, or `bundle`. If a command is required, send the screenshot instead.
