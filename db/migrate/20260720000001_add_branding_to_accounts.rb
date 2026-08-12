class AddBrandingToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :brand_name, :string
    add_column :accounts, :brand_logo_url, :string
    add_column :accounts, :brand_primary_color, :string
    add_column :accounts, :brand_secondary_color, :string
  end
end
