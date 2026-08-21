# == Schema Information
#
# Table name: reputation_listings
#
#  id         :bigint           not null, primary key
#  address    :string
#  category   :string
#  country    :string
#  email      :string
#  name       :string           not null
#  phone      :string
#  platforms  :jsonb            not null
#  primary    :boolean          default(FALSE), not null
#  synced_at  :datetime
#  website    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_reputation_listings_on_account_id  (account_id)
#
class Reputation::Listing < ApplicationRecord
  self.table_name = 'reputation_listings'

  belongs_to :account

  validates :name, presence: true
end
