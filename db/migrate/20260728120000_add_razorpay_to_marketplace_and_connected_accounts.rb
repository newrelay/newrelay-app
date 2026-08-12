class AddRazorpayToMarketplaceAndConnectedAccounts < ActiveRecord::Migration[7.1]
  def change
    change_column_null :connected_accounts, :stripe_account_id, true

    add_column :connected_accounts, :payment_provider, :string, default: 'stripe', null: false
    add_column :connected_accounts, :razorpay_account_id, :string
    add_index :connected_accounts, :razorpay_account_id, unique: true,
                                                         where: 'razorpay_account_id IS NOT NULL',
                                                         name: 'index_connected_accounts_on_razorpay_account_id'

    add_column :marketplace_plan_prices, :razorpay_plan_id, :string
  end
end
