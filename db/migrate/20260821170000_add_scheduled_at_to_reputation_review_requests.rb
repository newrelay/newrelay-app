class AddScheduledAtToReputationReviewRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :reputation_review_requests, :scheduled_at, :datetime
    add_index :reputation_review_requests, [:status, :scheduled_at]
  end
end
