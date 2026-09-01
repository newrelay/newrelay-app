FactoryBot.define do
  factory :comment_automation_message_log, class: 'CommentAutomation::MessageLog' do
    association :trigger, factory: :comment_automation_trigger
    account
    inbox
    sequence(:comment_id) { |n| "comment-#{n}" }
    sequence(:commenter_id) { |n| "commenter-#{n}" }
  end
end
