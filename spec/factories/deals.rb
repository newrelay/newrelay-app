# frozen_string_literal: true

FactoryBot.define do
  factory :deal do
    account
    pipeline { association :pipeline, :with_stages, account: account }
    pipeline_stage { pipeline.pipeline_stages.first }
    sequence(:name) { |n| "Deal #{n}" }
    amount_cents { 10_000 }
    currency { 'USD' }
    priority { :medium }
    probability { 50 }
  end
end
