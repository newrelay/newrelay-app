# == Schema Information
#
# Table name: reputation_listing_members
#
#  id                    :bigint           not null, primary key
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#  reputation_listing_id :bigint           not null
#  user_id               :bigint           not null
#
# Indexes
#
#  idx_reputation_listing_members_unique                      (reputation_listing_id,user_id) UNIQUE
#  index_reputation_listing_members_on_account_id             (account_id)
#  index_reputation_listing_members_on_reputation_listing_id  (reputation_listing_id)
#
class Reputation::ListingMember < ApplicationRecord
  self.table_name = 'reputation_listing_members'

  belongs_to :account
  belongs_to :listing, class_name: 'Reputation::Listing', foreign_key: :reputation_listing_id,
                       inverse_of: :listing_members
  belongs_to :user

  validates :user_id, uniqueness: { scope: :reputation_listing_id }
  validate :user_on_account

  private

  def user_on_account
    return if account&.account_users&.exists?(user_id: user_id)

    errors.add(:user_id, :invalid)
  end
end
