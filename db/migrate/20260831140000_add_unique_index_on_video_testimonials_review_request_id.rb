class AddUniqueIndexOnVideoTestimonialsReviewRequestId < ActiveRecord::Migration[7.1]
  def up
    # Keep the oldest row when two videos already share a request.
    execute <<~SQL.squish
      DELETE FROM reputation_video_testimonials a
      USING reputation_video_testimonials b
      WHERE a.review_request_id IS NOT NULL
        AND a.review_request_id = b.review_request_id
        AND a.id > b.id
    SQL

    add_index :reputation_video_testimonials, :review_request_id,
              unique: true,
              where: 'review_request_id IS NOT NULL',
              name: 'index_reputation_video_testimonials_on_review_request_id'
  end

  def down
    remove_index :reputation_video_testimonials,
                 name: 'index_reputation_video_testimonials_on_review_request_id',
                 if_exists: true
  end
end
