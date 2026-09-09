# frozen_string_literal: true

FactoryBot.define do
  factory :reputation_integration, class: 'Reputation::Integration' do
    account
    provider { 'google' }
    location_id { SecureRandom.hex(6) }
  end
end
