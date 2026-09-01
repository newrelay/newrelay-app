FactoryBot.define do
  factory :comment_automation_trigger, class: 'CommentAutomation::Trigger' do
    association :campaign, factory: :comment_automation_campaign
    account
    match_type { :contains }
    public_replies { ['Thanks for your comment!'] }
    dm_text_body { 'Here is the information you asked for.' }
  end
end
