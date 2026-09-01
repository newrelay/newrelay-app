# == Schema Information
#
# Table name: reputation_listings
#
#  id                    :bigint           not null, primary key
#  additional_categories :string
#  address               :string
#  amenities             :jsonb            not null
#  category              :string
#  country               :string
#  description           :text
#  email                 :string
#  holiday_hours         :jsonb            not null
#  hours                 :jsonb            not null
#  image                 :string
#  name                  :string           not null
#  phone                 :string
#  platforms             :jsonb            not null
#  primary               :boolean          default(FALSE), not null
#  service_area          :string
#  social_links          :jsonb            not null
#  synced_at             :datetime
#  website               :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#
# Indexes
#
#  index_reputation_listings_on_account_id  (account_id)
#
class Reputation::Listing < ApplicationRecord
  include Rails.application.routes.url_helpers

  self.table_name = 'reputation_listings'

  belongs_to :account
  has_many_attached :photos
  has_many :reputation_integrations, class_name: 'Reputation::Integration', foreign_key: :reputation_listing_id,
                                     dependent: :nullify, inverse_of: :listing
  has_many :reputation_reviews, through: :reputation_integrations
  has_many :listing_members, class_name: 'Reputation::ListingMember', foreign_key: :reputation_listing_id,
                             dependent: :destroy, inverse_of: :listing
  has_many :members, through: :listing_members, source: :user

  validates :name, presence: true

  def photo_urls
    photos.map { |photo| { id: photo.id, url: url_for(photo) } }
  end
end

Reputation::Listing.include_mod_with('Audit::Listing')
