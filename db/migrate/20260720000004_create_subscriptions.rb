class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.string :status, default: 'trialing'
      t.string :relationship_type, null: false
      t.references :connected_account, foreign_key: true, null: true
      t.decimal :application_fee_amount, precision: 10, scale: 2
      t.string :stripe_price_id
      t.string :stripe_product_id
      t.string :plan_name
      t.integer :subscribed_quantity
      t.datetime :current_period_start
      t.datetime :current_period_end

      t.timestamps
    end

    add_index :subscriptions, :stripe_subscription_id, unique: true
  end
end
