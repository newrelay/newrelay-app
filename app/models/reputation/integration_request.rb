# == Schema Information
#
# Table name: reputation_integration_requests
#
#  id         :bigint           not null, primary key
#  email      :string
#  notes      :text
#  platform   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_reputation_integration_requests_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Reputation::IntegrationRequest < ApplicationRecord
  self.table_name = 'reputation_integration_requests'

  belongs_to :account

  validates :platform, presence: true
end
