# == Schema Information
#
# Table name: reputation_reports
#
#  id         :bigint           not null, primary key
#  config     :jsonb            not null
#  token      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_reputation_reports_on_account_id  (account_id)
#  index_reputation_reports_on_token       (token) UNIQUE
#
class Reputation::Report < ApplicationRecord
  self.table_name = 'reputation_reports'

  belongs_to :account

  before_validation :assign_token, on: :create

  validates :token, presence: true, uniqueness: true

  private

  def assign_token
    self.token ||= SecureRandom.urlsafe_base64(12)
  end
end
