# frozen_string_literal: true

FactoryBot.define do
  factory :reputation_review, class: 'Reputation::Review' do
    account
    reputation_integration { association :reputation_integration, account: account }
    provider { 'google' }
    external_id { SecureRandom.hex(6) }
    rating { 5 }
  end
end
