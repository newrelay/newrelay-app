class CreateEnterpriseContracts < ActiveRecord::Migration[7.0]
  def change
    create_table :enterprise_contracts do |t|
      t.references :account, null: false, foreign_key: true
      t.decimal :negotiated_price, null: false, precision: 10, scale: 2
      t.string :currency, null: false
      t.string :billing_interval, null: false        # 'monthly', 'annual'
      t.string :collection_method, null: false, default: 'send_invoice'  # vs 'charge_automatically'
      t.integer :payment_terms_days, default: 30
      t.date :contract_start_date, null: false
      t.date :contract_end_date, null: false
      t.boolean :auto_renew, default: false
      t.jsonb :negotiated_limit_overrides, default: {}  # e.g., { "agents": 50, "contacts": 100000 }
      t.references :negotiated_by_user, foreign_key: { to_table: :users }, null: true
      t.text :notes
      t.timestamps
    end
  end
end
