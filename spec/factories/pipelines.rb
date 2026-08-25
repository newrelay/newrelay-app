# frozen_string_literal: true

FactoryBot.define do
  factory :pipeline do
    account
    sequence(:name) { |n| "Pipeline #{n}" }
    position { 0 }

    trait :with_stages do
      after(:create) do |pipeline|
        Pipelines::EnsureDefaultService::DEFAULT_STAGES.each do |attrs|
          pipeline.pipeline_stages.create!(attrs.merge(account: pipeline.account))
        end
      end
    end
  end

  factory :pipeline_stage do
    account
    pipeline
    sequence(:name) { |n| "Stage #{n}" }
    position { 0 }
    color { 'primary' }
  end
end
