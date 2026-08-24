class AddPhase1FieldsToReputationVideoTestimonials < ActiveRecord::Migration[7.1]
  def change
    change_table :reputation_video_testimonials, bulk: true do |t|
      t.bigint :contact_id
      t.bigint :review_request_id
      t.string :customer_name
      t.string :company
      t.integer :rating
      t.integer :duration_seconds
      t.string :platform
      t.integer :views, default: 0, null: false
      t.datetime :consented_at
      t.datetime :approved_at
      t.datetime :published_at
      t.datetime :rejected_at
    end

    add_index :reputation_video_testimonials, :contact_id
    add_index :reputation_video_testimonials, %i[account_id status]
  end
end
