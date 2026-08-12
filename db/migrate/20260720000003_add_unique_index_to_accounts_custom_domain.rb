class AddUniqueIndexToAccountsCustomDomain < ActiveRecord::Migration[7.1]
  def change
    add_index :accounts,
              'LOWER(custom_domain)',
              unique: true,
              where: "custom_domain IS NOT NULL AND custom_domain <> ''",
              name: 'index_accounts_on_lower_custom_domain'
  end
end
