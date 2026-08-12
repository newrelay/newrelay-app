class AddRazorpayFieldsToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :payment_provider, :string, default: 'stripe', null: false
    add_column :subscriptions, :razorpay_subscription_id, :string
    add_column :subscriptions, :razorpay_customer_id, :string

    add_index :subscriptions, :razorpay_subscription_id, unique: true,
                                                         where: 'razorpay_subscription_id IS NOT NULL',
                                                         name: 'index_subscriptions_on_razorpay_subscription_id'
  end
end
