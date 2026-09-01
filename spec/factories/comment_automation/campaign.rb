FactoryBot.define do
  factory :comment_automation_campaign, class: 'CommentAutomation::Campaign' do
    account
    inbox
    sequence(:name) { |n| "Campaign #{n}" }
    sequence(:post_id) { |n| "post-#{n}" }
  end
end
