class AddDetailFieldsToReputationListings < ActiveRecord::Migration[7.1]
  def change
    add_column :reputation_listings, :description, :text
    add_column :reputation_listings, :additional_categories, :string
    add_column :reputation_listings, :service_area, :string
    add_column :reputation_listings, :hours, :jsonb, default: {}, null: false
    add_column :reputation_listings, :holiday_hours, :jsonb, default: [], null: false
    add_column :reputation_listings, :amenities, :jsonb, default: {}, null: false
    add_column :reputation_listings, :social_links, :jsonb, default: {}, null: false
  end
end
