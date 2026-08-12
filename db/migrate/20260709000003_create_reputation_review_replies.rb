class CreateReputationReviewReplies < ActiveRecord::Migration[7.1]
  def change
    create_table :reputation_review_replies do |t|
      t.references :reputation_review, null: false, index: true
      t.references :account, null: false, index: true
      t.text :body, null: false
      t.string :status, default: 'draft'   # 'draft' | 'published'
      t.datetime :published_at
      t.timestamps
    end
  end
end
