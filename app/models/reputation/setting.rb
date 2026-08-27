# == Schema Information
#
# Table name: reputation_settings
#
#  id         :bigint           not null, primary key
#  config     :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_reputation_settings_on_account_id  (account_id) UNIQUE
#
class Reputation::Setting < ApplicationRecord
  self.table_name = 'reputation_settings'

  belongs_to :account

  validates :account_id, uniqueness: true
end
