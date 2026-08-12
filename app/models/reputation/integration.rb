# == Schema Information
#
# Table name: reputation_integrations
#
#  id               :bigint           not null, primary key
#  access_token     :text
#  location_name    :string
#  provider         :string           not null
#  refresh_token    :text
#  status           :string           default("active")
#  token_expires_at :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  location_id      :string           not null
#
# Indexes
#
#  idx_reputation_integrations_unique           (account_id,provider,location_id) UNIQUE
#  index_reputation_integrations_on_account_id  (account_id)
#
class Reputation::Integration < ApplicationRecord
  self.table_name = 'reputation_integrations'

  belongs_to :account
  has_many :reputation_reviews,
           class_name: 'Reputation::Review',
           foreign_key: :reputation_integration_id,
           dependent: :destroy,
           inverse_of: :reputation_integration

  encrypts :access_token, :refresh_token

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
  enum :status, { active: 'active', disconnected: 'disconnected' }

  validates :provider, :location_id, presence: true
  validates :location_id, uniqueness: { scope: [:account_id, :provider] }

  def refresh_token!
    return unless refresh_token_needed?

    response = perform_google_token_refresh
    if response.success?
      update_tokens!(response.parsed_response)
    else
      handle_refresh_failure(response)
    end
  end

  private

  def refresh_token_needed?
    provider == 'google' && refresh_token.present? &&
      (token_expires_at.blank? || token_expires_at <= 5.minutes.from_now)
  end

  def perform_google_token_refresh
    HTTParty.post('https://oauth2.googleapis.com/token', body: {
                    refresh_token: refresh_token,
                    client_id: ENV.fetch('REPUTATION_GOOGLE_CLIENT_ID', nil),
                    client_secret: ENV.fetch('REPUTATION_GOOGLE_CLIENT_SECRET', nil),
                    grant_type: 'refresh_token'
                  })
  end

  def update_tokens!(data)
    update!(
      access_token: data['access_token'],
      token_expires_at: Time.current + data['expires_in'].to_i.seconds
    )
  end

  def handle_refresh_failure(response)
    Rails.logger.error "Failed to refresh Google token for Reputation::Integration #{id}: #{response.body}"
    return unless response.code == 400 && response.parsed_response.present?

    disconnected! if response.parsed_response['error'] == 'invalid_grant'
  end
end
