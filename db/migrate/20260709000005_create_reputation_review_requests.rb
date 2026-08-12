class CreateReputationReviewRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :reputation_review_requests do |t|
      t.references :account, null: false, index: true
      t.references :reputation_template, null: false, index: true
      t.references :contact, null: false, index: true
      t.string :channel, null: false          # 'sms' | 'email'
      t.string :status, default: 'sent'       # 'sent' | 'delivered' | 'clicked' | 'completed'
      t.string :token, null: false            # unique tracking token
      t.datetime :clicked_at
      t.datetime :completed_at
      t.timestamps
    end
    add_index :reputation_review_requests, :token, unique: true
    add_index :reputation_review_requests, [:account_id, :status]
  end
end
