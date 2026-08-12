# == Schema Information
#
# Table name: reputation_reviews
#
#  id                        :bigint           not null, primary key
#  body                      :text
#  provider                  :string           not null
#  rating                    :integer
#  reviewed_at               :datetime
#  reviewer_name             :string
#  status                    :string           default("pending")
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  account_id                :bigint           not null
#  external_id               :string           not null
#  reputation_integration_id :bigint           not null
#
# Indexes
#
#  idx_reputation_reviews_unique                          (account_id,external_id,provider) UNIQUE
#  index_reputation_reviews_on_account_id                 (account_id)
#  index_reputation_reviews_on_account_id_and_status      (account_id,status)
#  index_reputation_reviews_on_reputation_integration_id  (reputation_integration_id)
#
class Reputation::Review < ApplicationRecord
  self.table_name = 'reputation_reviews'

  belongs_to :account
  belongs_to :reputation_integration, class_name: 'Reputation::Integration'
  has_one :reputation_review_reply,
          class_name: 'Reputation::ReviewReply',
          foreign_key: :reputation_review_id,
          dependent: :destroy,
          inverse_of: :reputation_review

  enum :provider, {
    google: 'google',
    facebook: 'facebook',
    agoda: 'agoda',
    airbnb: 'airbnb',
    aliexpress: 'aliexpress',
    amazon: 'amazon',
    angi: 'angi',
    apple_app_store: 'apple_app_store',
    avvo: 'avvo',
    custom: 'custom'
  }
  enum :status, { pending: 'pending', replied: 'replied', ignored: 'ignored' }

  validates :external_id, :provider, :rating, presence: true
  validates :rating, inclusion: { in: 1..5 }
  validates :external_id, uniqueness: { scope: [:account_id, :provider] }
end
