# Cron: picks up review requests whose scheduled_at has arrived and sends them.
# Flips status to :sent as it enqueues so the next tick won't re-select the same row.
class Reputation::DispatchScheduledRequestsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Reputation::ReviewRequest.scheduled
                             .where(scheduled_at: ..Time.current)
                             .find_each do |request|
      request.update!(status: :sent)
      Reputation::SendReviewRequestJob.perform_later(request.id)
    end
  end
end
