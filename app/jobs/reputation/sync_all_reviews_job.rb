# Fans out a review sync for every active integration. Scheduled hourly so reviews
# posted after connect-time still get pulled in. ReviewSyncJob does the per-provider work.
class Reputation::SyncAllReviewsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Reputation::Integration.active.find_each do |integration|
      Reputation::ReviewSyncJob.perform_later(integration.id)
    end
  end
end
