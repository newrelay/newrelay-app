# == Schema Information
#
# Table name: reputation_snapshots
#
#  id            :bigint           not null, primary key
#  avg_rating    :decimal(3, 2)    default(0.0), not null
#  captured_on   :date             not null
#  provider      :string           not null
#  response_rate :decimal(5, 2)    default(0.0), not null
#  reviews_count :integer          default(0), not null
#  score         :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#
# Indexes
#
#  idx_reputation_snapshots_unique               (account_id,provider,captured_on) UNIQUE
#  index_reputation_snapshots_on_account_id      (account_id)
#
class Reputation::Snapshot < ApplicationRecord
  self.table_name = 'reputation_snapshots'

  ROLLUP_PROVIDER = 'all'

  belongs_to :account

  validates :provider, :captured_on, presence: true
  validates :captured_on, uniqueness: { scope: [:account_id, :provider] }
  validates :score, inclusion: { in: 0..100 }
  validates :reviews_count, numericality: { greater_than_or_equal_to: 0 }
end
