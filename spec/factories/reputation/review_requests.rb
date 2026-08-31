# frozen_string_literal: true

FactoryBot.define do
  factory :reputation_review_request, class: 'Reputation::ReviewRequest' do
    account
    contact { association :contact, :with_email, account: account }
    reputation_template { association :reputation_template, account: account }
    channel { 'email' }
    status { 'sent' }
  end
end
