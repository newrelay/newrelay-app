class CreateReputationFeedbackSubmissions < ActiveRecord::Migration[7.1]
  def change
    create_table :reputation_feedback_submissions do |t|
      t.references :account, null: false, index: true
      t.references :reputation_review_request, null: false, index: true
      t.integer :rating, null: false   # 1-3 (intercepted low ratings)
      t.text :body
      t.string :reviewer_name
      t.timestamps
    end
  end
end
