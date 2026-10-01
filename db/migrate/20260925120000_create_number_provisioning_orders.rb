class CreateNumberProvisioningOrders < ActiveRecord::Migration[7.1]
  def change
    create_number_provisioning_orders_table
    add_number_provisioning_orders_indexes
  end

  private

  # status: search_pending | order_placed | requirements_pending | requirements_under_review
  # | requirements_rejected | active | failed | cancelled
  def create_number_provisioning_orders_table
    create_table :number_provisioning_orders do |t|
      t.bigint :account_id, null: false
      t.bigint :inbox_id # set once status becomes 'active'; inboxes already carry channel_id/channel_type
      t.string :provider_type, null: false # 'telnyx' | 'exotel'
      t.string :provider_order_id
      t.string :phone_number
      t.string :country_code, null: false
      t.string :status, null: false, default: 'search_pending'
      t.jsonb :regulatory_requirements, null: false, default: {}
      t.datetime :requirements_deadline_at
      t.integer :provider_cost_cents
      t.integer :margin_cents
      t.string :billing_reference
      t.string :provisioning_error

      t.timestamps
    end
  end

  def add_number_provisioning_orders_indexes
    add_index :number_provisioning_orders, :account_id
    add_index :number_provisioning_orders, :status
    add_index :number_provisioning_orders, :inbox_id
    add_index :number_provisioning_orders, [:provider_type, :provider_order_id],
              unique: true, where: 'provider_order_id IS NOT NULL'

    add_foreign_key :number_provisioning_orders, :accounts
  end
end
