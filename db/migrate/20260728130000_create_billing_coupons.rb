class CreateBillingCoupons < ActiveRecord::Migration[7.1]
  def change
    create_table :billing_coupons do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :discount_type, null: false, default: 'percent'
      t.decimal :percent_off, precision: 5, scale: 2
      t.decimal :amount_off, precision: 10, scale: 2
      t.string :currency, default: 'usd'
      t.string :duration, null: false, default: 'once'
      t.integer :duration_in_months
      t.integer :max_redemptions
      t.integer :times_redeemed, null: false, default: 0
      t.datetime :redeem_by
      t.boolean :active, null: false, default: true
      t.string :applies_to, null: false, default: 'plan'
      t.string :stripe_coupon_id
      t.string :razorpay_offer_id
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :billing_coupons, :code, unique: true
    add_index :billing_coupons, :stripe_coupon_id, unique: true, where: 'stripe_coupon_id IS NOT NULL'
    add_index :billing_coupons, :active
  end
end
