# App NewRelay server runbook

How we run **https://app.newrelay.com** on `srv1777969` (`/var/www/NewRelay`). Written from the Line/Slack/mail setup so the next person does not rediscover it.

This host uses **`docker-compose.yaml` (development compose)**, not `docker-compose.production.yaml`. Ports on the host are remapped: Rails **3001**, Postgres **5433**, Vite **3037**, Redis **6380**, Mailhog **1026/8026**.

---

## Never do this

- Do **not** re-run the old `sed` history that remaps `3000→3001`, `5432→5433`, etc. Those already ran; a second pass breaks ports.
- Do **not** `docker compose up -d` with **no** service names. That starts a useless `newrelay-base-1` (`irb`) container.
- Do **not** `sed` `bundle:/usr/local/bundle` to `bundle:/gems`. That hides image gems and you get `command not found: rails` / `sidekiq`.
- Do **not** `sed -i "/redis:6379/d"` (that deletes `REDIS_URL`).
- Slack **App Configuration Tokens** (12-hour Access/Refresh Token) are the **wrong** credentials. Use **Client ID** + **Client Secret** from Basic Information.

Safe restart after `.env` changes:

```bash
cd /var/www/NewRelay
docker compose -f /var/www/NewRelay/docker-compose.yaml up -d --force-recreate rails sidekiq
```

Wait until Rails has finished `bundle install` (first `rails runner` may fail with `rack-mini-profiler`). Then check Sidekiq is **Up**.

---

## Slack (account owners Connect; Super Admin keys once)

Slack is **not** an inbox. It lives under **Settings → Integrations → Apps**, not:

- Settings → Integrations → **Integration** (reputation / Google reviews)
- Settings → Inboxes → Add Inbox (that is LINE, WhatsApp, etc.)

### Layer 1 — one Slack app for the whole server (Super Admin)

1. [api.slack.com/apps](https://api.slack.com/apps) → **Create an App** → **Blank app** (not AI agent, not config tokens).
2. **Basic Information → App Credentials** → Client ID + Client Secret.
3. **OAuth & Permissions**
   - Redirect URL must be the **full path** NewRelay sends, per account:
     ```
     https://app.newrelay.com/app/accounts/{ACCOUNT_ID}/settings/integrations/slack
     ```
     Example for Acme Org (id **2**):
     ```
     https://app.newrelay.com/app/accounts/2/settings/integrations/slack
     ```
     Base URL only (`https://app.newrelay.com`) will error: `redirect_uri did not match`.
   - Bot scopes (from `config/integration/apps.yml`):  
     `commands`, `chat:write`, `chat:write.customize`, `channels:read`, `channels:manage`, `channels:join`, `channels:history`, `groups:read`, `groups:write`, `groups:history`, `im:write`, `im:history`, `mpim:write`, `mpim:history`, `users:read`, `users:read.email`, `files:read`, `files:write`
4. **Event Subscriptions**
   - Request URL: `https://app.newrelay.com/api/v1/integrations/webhooks` (must show Verified)
   - Bot events: `link_shared`, `message.channels`, `message.groups`, `message.im`, `message.mpim`
5. **Manage Distribution → Activate Public Distribution** if other Slack workspaces will Connect.  
   Otherwise: `invalid_team_for_non_distributed_app`.
6. Super Admin: `https://app.newrelay.com/super_admin/app_config?config=slack`  
   Save Client ID + Secret. Slack is **hidden** until `SLACK_CLIENT_SECRET` is present.

```bash
docker compose -f /var/www/NewRelay/docker-compose.yaml exec rails \
  bundle exec rails runner 'GlobalConfig.clear_cache; puts "secret_ok=#{GlobalConfigService.load("SLACK_CLIENT_SECRET", nil).present?}"'
```

Want `secret_ok=true`. Recreating Rails does **not** clear Redis by itself.

Account ids:

```bash
docker compose -f /var/www/NewRelay/docker-compose.yaml exec rails \
  bundle exec rails runner 'Account.find_each { |a| puts "#{a.id} #{a.name}" }'
```

### Layer 2 — each account owner (no Slack app, no Super Admin)

1. Administrator on that account.
2. `https://app.newrelay.com/app/accounts/{ID}/settings/integrations` (**Apps**).
3. Slack → Connect → pick a channel → Update.  
   Hook stays **disabled** until a channel is selected.

### Test Slack

- A **customer** message starts the Slack thread. An **agent-only** message does not.
- Reply **in that Slack thread**, not a new channel message.
- `note:` / `private:` → private note in NewRelay.
- Sidekiq must be **Up**.

```bash
docker compose -f /var/www/NewRelay/docker-compose.yaml exec rails \
  bundle exec rails runner 'h=Integrations::Hook.find_by(account_id: 2, app_id: "slack"); puts "present=#{h.present?}"; puts "status=#{h&.status}"; puts "channel=#{h&.settings&.dig("channel_name")}"; puts "ref=#{h&.reference_id.present?}"'
```

Want `status=enabled` and `ref=true`.

---

## LINE (inbox)

1. [LINE Developers Console](https://developers.line.biz/console) → Provider → **Messaging API** channel.
2. Copy Channel ID, Secret, Channel Access Token.
3. NewRelay: **Settings → Inboxes → Add Inbox → Line**.
4. Webhook:
   ```
   https://app.newrelay.com/webhooks/line/{LINE_CHANNEL_ID}
   ```
5. LINE Console → paste webhook → Verify → enable Use webhook. Turn auto-reply off.

`FRONTEND_URL` must be `https://app.newrelay.com`. LINE requires HTTPS.

---

## Mail (Gmail SMTP)

This compose forces `RAILS_ENV=development`. In development, mail uses **letter_opener** unless:

```
LETTER_OPENER=false
```

is in `/var/www/NewRelay/.env`. SMTP can be configured (`SMTP_ADDRESS=smtp.gmail.com`) and still **never send** while delivery is `letter_opener`.

Check:

```bash
docker compose -f /var/www/NewRelay/docker-compose.yaml exec rails printenv LETTER_OPENER
docker compose -f /var/www/NewRelay/docker-compose.yaml exec rails \
  bundle exec rails runner 'puts "rails_env=#{Rails.env}"; puts "delivery=#{ActionMailer::Base.delivery_method}"; puts "smtp=#{ActionMailer::Base.smtp_settings[:address]}"'
```

Want `LETTER_OPENER=false`, `delivery=smtp`. Gmail needs an [App Password](https://myaccount.google.com/apppasswords).

Test:

```bash
docker compose -f /var/www/NewRelay/docker-compose.yaml exec rails \
  bundle exec rails runner 'ActionMailer::Base.mail(from: ENV.fetch("MAILER_SENDER_EMAIL"), to: "YOU@YOURDOMAIN.com", subject: "NewRelay SMTP test", body: "ok").deliver_now; puts "sent"'
```

Also: login → Forgot password. Mailhog UI (`:8026`) is only for old/dev captures; live SMTP mail will not appear there.

---

## Docker / Sidekiq (why “other things” break)

| Service | Why it matters |
|---|---|
| `rails` | App. Entrypoint runs `bundle install`. |
| `sidekiq` | Mail jobs, Slack sync, LINE inbound jobs. **Must be Up.** |
| `vite` | Dev JS. Port **3037**. |
| `postgres` / `redis` | Data / cache. Do not recreate Redis just to “fix Slack”; use `GlobalConfig.clear_cache`. |

Sidekiq has **no** `bundle install` entrypoint unless you add:

```yaml
    entrypoint: docker/entrypoints/rails.sh
```

under `sidekiq:` (same as Rails). Without that, Sidekiq often exits with `rack-mini-profiler` / `command not found: sidekiq` if it starts before Rails finishes installing gems.

After recreate:

```bash
docker compose -f /var/www/NewRelay/docker-compose.yaml ps
docker compose -f /var/www/NewRelay/docker-compose.yaml logs --tail=40 sidekiq
```

`REDIS_PASSWORD is not set` in the compose logs means Redis is running with **no password**, reachable from the public
internet on the host's published port. This caused a real cryptominer (XMRig) infection on `srv1777969` on 2026-09-23
— do not leave it unset. Set `REDIS_PASSWORD` in `.env` and confirm the compose file publishes Postgres/Redis ports
bound to `127.0.0.1` only, not `0.0.0.0`.

---

## Quick health

```bash
docker compose -f /var/www/NewRelay/docker-compose.yaml ps
# rails + sidekiq + postgres + redis Up

docker compose -f /var/www/NewRelay/docker-compose.yaml exec rails \
  bundle exec rails runner 'a=Account.first; apps=Integrations::App.all.select{|x| x.active?(a)}; puts "slack=#{apps.any?{|x| x.id=="slack"}}"; puts "delivery=#{ActionMailer::Base.delivery_method}"'
```

Do not paste `.env`, Client Secret, or SMTP passwords into chat or this file.
