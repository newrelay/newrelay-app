class CreateReputationReports < ActiveRecord::Migration[7.1]
  def change
    create_table :reputation_reports do |t|
      t.references :account, null: false, index: true
      t.string :token, null: false
      t.jsonb :config, null: false, default: {}
      t.timestamps
    end

    add_index :reputation_reports, :token, unique: true
  end
end
