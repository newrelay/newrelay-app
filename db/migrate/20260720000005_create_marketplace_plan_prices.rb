class CreateMarketplacePlanPrices < ActiveRecord::Migration[7.1]
  def change
    create_table :marketplace_plan_prices do |t|
      t.references :account, null: false, foreign_key: true
      t.string :currency, null: false, default: 'usd'
      t.decimal :agency_price, precision: 10, scale: 2, null: false
      t.decimal :commission_percent, precision: 5, scale: 2, null: false
      t.decimal :platform_fee_amount, precision: 10, scale: 2, null: false
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.string :stripe_price_id
      t.string :stripe_product_id
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
