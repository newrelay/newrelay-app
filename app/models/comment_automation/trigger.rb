# == Schema Information
#
# Table name: comment_automation_triggers
#
#  id             :bigint           not null, primary key
#  dm_text_body   :text             not null
#  keyword        :string
#  match_type     :integer          default("exact"), not null
#  public_replies :text             default([]), not null, is an Array
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#  campaign_id    :bigint           not null
#  template_id    :bigint
#
# Indexes
#
#  index_comment_automation_triggers_on_account_id   (account_id)
#  index_comment_automation_triggers_on_campaign_id  (campaign_id)
#  index_comment_automation_triggers_on_template_id  (template_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (campaign_id => comment_automation_campaigns.id)
#  fk_rails_...  (template_id => comment_automation_templates.id)
#
class CommentAutomation::Trigger < ApplicationRecord
  belongs_to :campaign, class_name: 'CommentAutomation::Campaign'
  belongs_to :account
  belongs_to :template, class_name: 'CommentAutomation::Template', optional: true
  has_many :message_logs, class_name: 'CommentAutomation::MessageLog', foreign_key: :trigger_id, dependent: :destroy, inverse_of: :trigger

  enum match_type: { exact: 0, contains: 1 }

  validates :dm_text_body, presence: true
  validates :public_replies, presence: true
end
