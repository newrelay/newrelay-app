class CreatePipelinesAndDeals < ActiveRecord::Migration[7.1]
  def change
    create_table :pipelines do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :pipelines, [:account_id, :name], unique: true

    create_table :pipeline_stages do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :pipeline, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.string :color, null: false, default: 'primary'
      t.boolean :is_won, null: false, default: false
      t.boolean :is_lost, null: false, default: false
      t.timestamps
    end
    add_index :pipeline_stages, [:pipeline_id, :name], unique: true
    add_index :pipeline_stages, [:pipeline_id, :position]

    create_table :deals do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :pipeline, null: false, foreign_key: true, index: true
      t.references :pipeline_stage, null: false, foreign_key: true, index: true
      t.references :contact, foreign_key: true, index: true
      t.bigint :company_id
      t.bigint :owner_id
      t.string :name, null: false
      t.bigint :amount_cents, null: false, default: 0
      t.string :currency, null: false, default: 'USD'
      t.date :close_on
      t.integer :priority, null: false, default: 1
      t.integer :probability, null: false, default: 0
      t.timestamps
    end
    add_index :deals, :company_id
    add_index :deals, :owner_id
    add_index :deals, [:account_id, :name]
    add_foreign_key :deals, :users, column: :owner_id
  end
end
