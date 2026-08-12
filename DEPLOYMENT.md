# Deployment Guide: DakshAI Self-Hosted

This guide outlines the recommended deployment strategy for **DakshAI** on your own server. We recommend using **Docker Compose** on a Linux Virtual Machine (such as Ubuntu on AWS EC2, DigitalOcean, or Linode) because it containerizes all dependencies (PostgreSQL, Redis, Rails backend, Vue.js assets, Sidekiq workers) and simplifies upgrades.

---

## 1. Prerequisites
- A virtual machine with at least **2 vCPUs** and **4 GB RAM** (recommended minimum for production workloads running sidekiq and rails).
- Docker and Docker Compose installed.
- A domain name (e.g., `chat.dakshai.com`) pointing to your server's public IP address.
- Port `80` (HTTP) and `443` (HTTPS) open.

---

## 2. Environment Configuration (`.env`)

Create a `.env` file in your application root directory on the server. Below is the production environment template pre-configured for **DakshAI**:

```env
# --- Server Config ---
NODE_ENV=production
RAILS_ENV=production
PORT=3000
FRONTEND_URL=https://chat.dakshai.com

# --- Branding (DakshAI) ---
INSTALLATION_NAME=DakshAI
BRAND_NAME=DakshAI
BRAND_URL=https://dakshai.com
WIDGET_BRAND_URL=https://dakshai.com
TERMS_URL=https://dakshai.com/terms
PRIVACY_URL=https://dakshai.com/privacy

# --- Database Config ---
POSTGRES_HOST=postgres
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=your_secure_postgres_password_here
POSTGRES_DATABASE=dakshai_production

# --- Redis Config ---
REDIS_URL=redis://redis:6379/0

# --- Security Config ---
# Generate these values using: openssl rand -hex 64
SECRET_KEY_BASE=your_generated_secret_key_base
ACTIVE_STORAGE_SERVICE_NAME=local

# --- Email/SMTP Config (Required for signup/notifications) ---
# Replace these with your actual SMTP provider settings (e.g. SendGrid, Mailgun, AWS SES)
MAILER_SENDER_EMAIL=support@dakshai.com
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your_smtp_password
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true

# --- Features Enabled ---
ENABLE_ACCOUNT_SIGNUP=true
```

---

## 3. Docker Compose Setup (`docker-compose.yml`)

Create a `docker-compose.yml` file in the same directory as your `.env` file:

```yaml
version: '3'

services:
  postgres:
    image: postgres:12-alpine
    restart: always
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: your_secure_postgres_password_here
      POSTGRES_DB: dakshai_production

  redis:
    image: redis:6.2-alpine
    restart: always
    volumes:
      - redis_data:/data

  rails:
    image: chatwoot/chatwoot:latest # Or build your own image from your release/dev branch
    restart: always
    command: bundle exec rails s -p 3000 -b '0.0.0.0'
    depends_on:
      - postgres
      - redis
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=production
    env_file: .env
    volumes:
      - uploads:/app/storage

  sidekiq:
    image: chatwoot/chatwoot:latest
    restart: always
    command: bundle exec sidekiq -C config/sidekiq.yml
    depends_on:
      - postgres
      - redis
    env_file: .env
    volumes:
      - uploads:/app/storage

volumes:
  postgres_data:
  redis_data:
  uploads:
```

> [!TIP]
> To build your own Docker Image from your `release/dev` branch, run:
> `docker build -t your-registry/dakshai:latest .` and use it in place of `chatwoot/chatwoot:latest` in the `docker-compose.yml` file.

---

## 4. Run the Initial Setup

Before launching the app, run the database migrations and seed standard data:

1. **Create the Database and Run Migrations**:
   ```bash
   docker-compose run --rm rails bundle exec rails db:chatwoot_prepare
   ```
2. **Launch Services**:
   ```bash
   docker-compose up -d
   ```
3. **Verify running containers**:
   ```bash
   docker-compose ps
   ```

---

## 5. SSL & Nginx Reverse Proxy

To serve DakshAI securely over HTTPS on port 443, configure Nginx as a reverse proxy on the host machine.

### Installation of Nginx & Let's Encrypt
```bash
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx
```

### Nginx Server Block Configuration (`/etc/nginx/sites-available/dakshai`)
Create a configuration file:
```nginx
server {
    server_name chat.dakshai.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Ssl on;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```
Enable the site and obtain SSL Certificate:
```bash
sudo ln -s /etc/nginx/sites-available/dakshai /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemerver restart nginx
sudo certbot --nginx -d chat.dakshai.com
```
Your instance will now be live, secure, and branded under **`DakshAI`**.
