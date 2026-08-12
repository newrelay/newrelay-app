class CreateReputationTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :reputation_templates do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false
      t.string :channel, null: false   # 'sms' | 'email'
      t.text :body, null: false        # supports {{contact.name}}, {{review_link}}
      t.string :subject                # email only
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :reputation_templates, [:account_id, :channel]
  end
end
