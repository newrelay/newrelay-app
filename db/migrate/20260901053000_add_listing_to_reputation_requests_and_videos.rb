class AddListingToReputationRequestsAndVideos < ActiveRecord::Migration[7.1]
  def up
    add_column :reputation_review_requests, :reputation_listing_id, :bigint
    add_index :reputation_review_requests, :reputation_listing_id
    add_column :reputation_video_testimonials, :reputation_listing_id, :bigint
    add_index :reputation_video_testimonials, :reputation_listing_id

    execute <<~SQL.squish
      UPDATE reputation_review_requests rr
      SET reputation_listing_id = (
        SELECT rl.id FROM reputation_listings rl
        WHERE rl.account_id = rr.account_id
        ORDER BY rl.primary DESC, rl.created_at ASC
        LIMIT 1
      )
      WHERE rr.reputation_listing_id IS NULL
    SQL

    execute <<~SQL.squish
      UPDATE reputation_video_testimonials vt
      SET reputation_listing_id = COALESCE(
        (
          SELECT rr.reputation_listing_id FROM reputation_review_requests rr
          WHERE rr.id = vt.review_request_id
        ),
        (
          SELECT rl.id FROM reputation_listings rl
          WHERE rl.account_id = vt.account_id
          ORDER BY rl.primary DESC, rl.created_at ASC
          LIMIT 1
        )
      )
      WHERE vt.reputation_listing_id IS NULL
    SQL
  end

  def down
    remove_index :reputation_video_testimonials, :reputation_listing_id
    remove_column :reputation_video_testimonials, :reputation_listing_id
    remove_index :reputation_review_requests, :reputation_listing_id
    remove_column :reputation_review_requests, :reputation_listing_id
  end
end
