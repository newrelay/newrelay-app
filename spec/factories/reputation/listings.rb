# frozen_string_literal: true

FactoryBot.define do
  factory :reputation_listing, class: 'Reputation::Listing' do
    account
    name { 'Downtown Cafe' }
  end
end
