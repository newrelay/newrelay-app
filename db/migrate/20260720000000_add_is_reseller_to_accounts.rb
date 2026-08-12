class AddIsResellerToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :is_reseller, :boolean, null: false, default: false

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE accounts
          SET is_reseller = TRUE
          WHERE id IN (
            SELECT DISTINCT parent_id
            FROM accounts
            WHERE parent_id IS NOT NULL
          )
        SQL
      end
    end
  end
end
