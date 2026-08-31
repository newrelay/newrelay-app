# frozen_string_literal: true

FactoryBot.define do
  factory :reputation_template, class: 'Reputation::Template' do
    account
    name { 'Review request' }
    channel { 'email' }
    subject { 'Please review us' }
    body { 'Hi {{ReviewLink}}' }
    template_type { 'standard' }
  end
end
