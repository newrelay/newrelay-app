#!/bin/bash
set -e

echo "Starting PostgreSQL 16 and Redis services..."
brew services start postgresql@16 || true
brew services start redis || true

echo "Waiting for database to start..."
sleep 5

echo "Initializing rbenv..."
eval "$(rbenv init -)"

echo "Setting up database..."
bundle exec rails db:chatwoot_prepare

echo "Seeding database..."
bundle exec rails db:seed

echo "Database successfully set up! You can now run 'make run' to start Chatwoot."
