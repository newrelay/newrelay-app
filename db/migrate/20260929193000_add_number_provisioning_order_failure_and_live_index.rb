class AddNumberProvisioningOrderFailureAndLiveIndex < ActiveRecord::Migration[7.1]
  LIVE_STATUS_SQL = <<~SQL.squish.freeze
    status IN (
      'order_placed', 'requirements_pending', 'requirements_under_review',
      'requirements_rejected', 'billing_failed', 'inbox_pending', 'active'
    ) AND phone_number IS NOT NULL
  SQL

  def change
    add_column :number_provisioning_orders, :failure_code, :string
    add_column :number_provisioning_orders, :currency, :string

    add_index :number_provisioning_orders, [:account_id, :phone_number],
              unique: true,
              where: LIVE_STATUS_SQL,
              name: 'index_np_orders_live_account_phone'
  end
end
