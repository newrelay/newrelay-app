class AddImageToReputationListings < ActiveRecord::Migration[7.1]
  def change
    add_column :reputation_listings, :image, :string
  end
end
