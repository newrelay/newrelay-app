# housekeeping
# fans out Internal::PurgeExpiredConversationsJob to every account that has a
# plan-based data retention limit set (account.limits['data_retention_months']).
# Accounts without that key (e.g. Enterprise/unlimited) are skipped entirely.

class Internal::PurgeExpiredConversationsSchedulerJob < ApplicationJob
  queue_as :housekeeping

  def perform
    Account.where("(limits->>'data_retention_months') IS NOT NULL").find_each(batch_size: 100) do |account|
      # Spread the actual deletes over the day so the purgable queue isn't flooded at once.
      Internal::PurgeExpiredConversationsJob.set(wait: rand(0..50).minutes).perform_later(account)
    end
  end
end
