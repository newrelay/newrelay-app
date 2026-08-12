class CreateReputationWidgets < ActiveRecord::Migration[7.1]
  def change
    create_table :reputation_widgets do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false
      t.string :style, default: 'carousel'   # 'carousel' | 'grid' | 'badge'
      t.integer :min_rating, default: 4      # only show reviews >= this rating
      t.boolean :active, default: true
      t.string :token, null: false           # embed token
      t.timestamps
    end
    add_index :reputation_widgets, :token, unique: true
  end
end
