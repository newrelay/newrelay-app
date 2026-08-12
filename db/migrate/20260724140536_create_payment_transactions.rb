class CreatePaymentTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :payment_transactions do |t|
      t.references :account, null: false, foreign_key: true
      t.string :stripe_customer_id
      t.string :stripe_invoice_id
      t.string :stripe_charge_id
      t.decimal :amount, precision: 10, scale: 2
      t.string :currency
      t.string :status, null: false
      t.string :description
      t.string :billing_reason
      t.string :hosted_invoice_url
      t.string :invoice_pdf
      t.datetime :paid_at

      t.timestamps
    end

    add_index :payment_transactions, :stripe_invoice_id, unique: true
  end
end
