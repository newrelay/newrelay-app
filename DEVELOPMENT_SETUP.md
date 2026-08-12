# Local Development Setup Guide: DakshAI

This guide details how to set up and run the **DakshAI** development environment locally on your macOS machine.

---

## 1. Prerequisites

Before installing dependencies, ensure you have the following system dependencies running:

### A. Homebrew
If you don't have Homebrew installed, run:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### B. PostgreSQL & Redis
Install and start database and caching services using Homebrew:
```bash
# Install PostgreSQL and Redis
brew install postgresql@14 redis

# Start services
brew services start postgresql@14
brew services start redis
```

### C. Ruby (via rbenv)
This project uses Ruby version `3.4.4` (configured in `.ruby-version`).
```bash
# Install rbenv and ruby-build
brew install rbenv ruby-build

# Initialize rbenv in your shell (add this to ~/.zshrc or ~/.bash_profile as well)
eval "$(rbenv init -)"

# Install and select the correct Ruby version
rbenv install 3.4.4
rbenv global 3.4.4
```

### D. Node.js & Pnpm
This project requires Node.js (version 24.x is recommended for building frontend assets):
```bash
# Install Node.js
brew install node@24

# Link Node
brew link --overwrite node@24

# Install pnpm globally
npm install -g pnpm
```

---

## 2. Installation Steps

### Step 1: Install Dependencies
Navigate to your project directory and run the Bundler and Pnpm install commands:

1. **Install Ruby Bundles**:
   Ensure you run `rbenv init` before using bundler.
   ```bash
   eval "$(rbenv init -)"
   
   # Verify correct ruby version is active (should be 3.4.4)
   ruby -v

   # Install the correct bundler version if missing
   gem install bundler -v 2.5.16
   
   # Install backend gems
   bundle install
   ```

2. **Install Frontend packages**:
   ```bash
   pnpm install
   ```

---

### Step 2: Configure Environment Variables
Copy the template `.env.example` file to `.env`:
```bash
cp .env.example .env
```
Open `.env` in your editor and configure your database parameters (PostgreSQL username/password and Redis URL). E.g.:
```env
POSTGRES_HOST=localhost
POSTGRES_USERNAME=your_mac_username # usually the output of: whoami
POSTGRES_PASSWORD=
REDIS_URL=redis://localhost:6379/0
```

---

### Step 3: Setup the Database
Create database tables, run migrations, and prep your database schema:
```bash
bundle exec rails db:chatwoot_prepare
```

---

### Step 4: Seed Test Data (Optional)
To quickly populate minimal data for verification:
```bash
bundle exec rails db:seed
```

---

## 3. Running Locally

### Option A: Using Overmind (Recommended)
Overmind orchestrates multiple processes (Rails API server, Vite frontend server, Sidekiq background jobs) inside a tmux session.

1. **Install Overmind**:
   ```bash
   brew install tmux overmind
   ```
2. **Start Development Server**:
   ```bash
   pnpm dev
   ```
   *Alternatively, run: `overmind start -f ./Procfile.dev`*

---

### Option B: Running Processes Separately
If you don't want to use Overmind/tmux, open three separate terminal tabs and run:

1. **Terminal 1: Rails API Server**
   ```bash
   eval "$(rbenv init -)"
   bundle exec rails server -p 3000
   ```
2. **Terminal 2: Frontend Asset Compilation**
   ```bash
   pnpm dev:vite
   ```
3. **Terminal 3: Background Worker**
   ```bash
   eval "$(rbenv init -)"
   bundle exec sidekiq -C config/sidekiq.yml
   ```

---

## 4. Troubleshooting Common Errors

### 🔴 `overmind: it looks like Overmind is already running`
If you killed the server forcefully, a lock socket might remain. Delete the socket file and try again:
```bash
rm -f .overmind.sock
```

### 🔴 `Could not find 'bundler' (2.5.16) required by your Gemfile.lock`
Ensure you have initialized `rbenv` in the current terminal window:
```bash
eval "$(rbenv init -)"
gem install bundler:2.5.16
```

### 🔴 `Unsupported engine wanted: {"node":"24.x"}`
If you get Node warnings, make sure you are running Node 24.x using `node -v`. You can install a node manager like `fnm` or `nvm` to switch node versions easily:
```bash
# Using fnm
fnm install 24
fnm use 24
```
