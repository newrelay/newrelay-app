#!/bin/bash
set -e

echo "=== 🚀 DakshAI Docker Starter ==="

# 1. Create .env from template if it doesn't exist
if [ ! -f .env ]; then
  echo "📄 Creating .env file from .env.example..."
  cp .env.example .env
  
  # Inject standard Docker-compatible configs
  sed -i.bak 's/POSTGRES_HOST=localhost/POSTGRES_HOST=postgres/g' .env
  sed -i.bak 's/POSTGRES_USERNAME=postgres/POSTGRES_USERNAME=postgres/g' .env
  sed -i.bak 's/REDIS_URL=redis:\/\/localhost:6379/REDIS_URL=redis:\/\/redis:6379/g' .env
  rm -f .env.bak
  echo "✅ .env file created and pre-configured for Docker."
else
  echo "✅ Existing .env file found."
fi

# 2. Check if Docker is running
if ! docker info >/dev/null 2>&1; then
  echo "❌ Error: Docker is not running. Please start Docker Desktop/Daemon and try again."
  exit 1
fi

# 3. Build Docker Compose services
echo "🔨 Building Docker images (this may take a few minutes on the first run)..."
docker compose build

# 4. Prepare and seed the database inside containers
echo "🗄️ Setting up database tables and migrations..."
docker compose run --rm rails bundle exec rails db:chatwoot_prepare

echo "🌱 Seeding initial mock data..."
docker compose run --rm rails bundle exec rails db:seed || true

# 5. Start all services
echo "✨ Starting DakshAI stack..."
echo "👉 The app will be available at http://localhost:3000"
echo "👉 Mailhog (email testing inbox) will be available at http://localhost:8025"
echo "--------------------------------------------------------"
docker compose up
