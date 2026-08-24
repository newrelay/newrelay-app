class AddMessageAndDestinationsToReputationReviewRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :reputation_review_requests, :message, :text
    add_column :reputation_review_requests, :destinations, :jsonb, default: []
  end
end
