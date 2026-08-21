# Daily snapshot of review totals / score per account so Overview can show
# honest month-over-month deltas after 30 days of history.
class Reputation::CaptureSnapshotsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.joins(:reputation_reviews).distinct.find_each do |account|
      recorder = Reputation::SnapshotRecorder.new(account)
      if account.reputation_snapshots.exists?
        recorder.capture!
      else
        recorder.backfill!
      end
    end
  end
end
