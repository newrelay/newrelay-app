# frozen_string_literal: true

# =============================================================================
# Local/dev only — seed ≥10 conversations for All / Mine / Unassigned /
# Mentions / Teams tabs
# =============================================================================
#
# Usage (local):
#   eval "$(rbenv init -)"
#   bundle exec rails runner bin/seed_conversation_tabs.rb
#
# Usage (Docker):
#   docker compose exec rails bundle exec rails runner bin/seed_conversation_tabs.rb
#
# Optional overrides:
#   ACCOUNT_ID=2 USER_EMAIL=admin@example.com docker compose exec -e ACCOUNT_ID -e USER_EMAIL \
#     rails bundle exec rails runner bin/seed_conversation_tabs.rb
#
# DO NOT run against production.
# =============================================================================

raise 'Refusing to run in production' if Rails.env.production?

ACCOUNT_ID = Integer(ENV.fetch('ACCOUNT_ID', 2))
USER_EMAIL = ENV['USER_EMAIL'].presence

account = Account.find(ACCOUNT_ID)
user = USER_EMAIL ? User.from_email(USER_EMAIL) : nil

puts "Seeding conversation tabs for Account ##{account.id} (#{account.name})..."
Seeders::ConversationTabsSeeder.new(account: account, user: user).perform!
puts 'Done.'
