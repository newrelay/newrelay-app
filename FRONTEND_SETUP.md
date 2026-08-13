# Frontend-Only & Standalone UI Setup Guide

This guide explains how UI developers can set up, run, and develop the DakshAI / Chatwoot Vue frontend **without installing Ruby, Rails, PostgreSQL, or Redis**.

---

## Quick Start (Frontend UI Developers)

### 1. Prerequisites
- **Node.js**: v18.x, v20.x, or v24.x
- **pnpm**: v10.x (`npm install -g pnpm`)

### 2. Installation
Clone the repository and install npm packages:
```bash
git clone https://github.com/auzadev/DakshAI.git
cd DakshAI
git checkout feature/ui-changes
pnpm install
```

### 3. Start Frontend UI Development Server
Run the Node-only standalone Vite dev server:
```bash
pnpm dev:ui
```
Open **[http://localhost:5173](http://localhost:5173)** in your browser.

---

## Connecting Frontend to a Backend Server

By default, API requests (`/api`, `/auth`, `/cable`, `/rails`) are proxied to `http://localhost:3000`.

If your backend app server is running on a different port or remote URL (e.g., staging server `https://api.yourdomain.com`), start Vite with the `BACKEND_URL` environment variable:

```bash
BACKEND_URL=https://api.yourdomain.com pnpm dev:ui
```

---

## Available Commands

| Command | Description |
| :--- | :--- |
| `pnpm dev:ui` | Starts **frontend UI only** (Vite on port `5173` with Node.js) |
| `pnpm dev:backend` | Starts **backend Rails server only** (Rails on port `3000`) |
| `pnpm dev` | Starts **both** frontend and backend together (via Overmind) |
| `pnpm eslint` | Runs ESLint code quality checks on JavaScript & Vue files |
| `pnpm eslint:fix` | Automatically fixes ESLint styling issues |

---

## Architecture Overview

```
               ┌──────────────────────────────────────────┐
               │    Vite Frontend Dev Server (Node.js)    │
               │         http://localhost:5173            │
               └────────────────────┬─────────────────────┘
                                    │
                       API Proxy (/api, /auth, /cable)
                                    │
                                    ▼
               ┌──────────────────────────────────────────┐
               │          Rails Backend App Server        │
               │   (Local http://localhost:3000 or Remote) │
               └──────────────────────────────────────────┘
```

1. **`index.html`**: Entrypoint for Vite standalone development, bootstrapping `window.chatwootConfig` and `dashboard.js`.
2. **`vite.config.mts`**: Configured with proxy rules for `/api`, `/auth`, `/cable`, and `/rails` pointing to `BACKEND_URL`.
3. **CORS (`config/initializers/cors.rb`)**: Configured on the Rails backend to allow cross-origin requests and credentials from `http://localhost:5173` (or any custom `FRONTEND_URL`).

---

## Troubleshooting

- **CORS Errors when logging in or making API requests**:
  Ensure the backend Rails server has `FRONTEND_URL=http://localhost:5173` or `CW_API_ONLY_SERVER=true` in its `.env` file.
- **Port Conflict**:
  If port `5173` is occupied, Vite will automatically select the next available port (e.g. `5174`).
