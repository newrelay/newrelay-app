# == Schema Information
#
# Table name: commission_rules
#
#  id                 :bigint           not null, primary key
#  commission_percent :decimal(5, 2)    default(30.0), not null
#  effective_from     :datetime         not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#  created_by_user_id :bigint
#
# Indexes
#
#  index_commission_rules_on_account_id          (account_id)
#  index_commission_rules_on_created_by_user_id  (created_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (created_by_user_id => users.id)
#
class CommissionRule < ApplicationRecord
  belongs_to :account
  belongs_to :created_by_user, class_name: 'User', optional: true

  validates :commission_percent, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :effective_from, presence: true

  scope :active_at, ->(time) { where('effective_from <= ?', time).order(effective_from: :desc) }

  def self.current_percent_for(account)
    active_at(Time.current).find_by(account: account)&.commission_percent || 30.0
  end
end
