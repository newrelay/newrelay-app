class AddParentIdToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_reference :accounts, :parent, foreign_key: { to_table: :accounts }, null: true
  end
end
