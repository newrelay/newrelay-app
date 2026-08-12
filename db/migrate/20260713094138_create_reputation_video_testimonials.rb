class CreateReputationVideoTestimonials < ActiveRecord::Migration[7.1]
  def change
    create_table :reputation_video_testimonials do |t|
      t.references :account, null: false, foreign_key: true
      t.string :title
      t.string :email
      t.string :status, default: 'pending'
      t.string :token, null: false

      t.index :token, unique: true

      t.timestamps
    end
  end
end
