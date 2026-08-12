class AddCustomDomainToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :custom_domain, :string
  end
end
