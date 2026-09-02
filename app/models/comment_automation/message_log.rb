# == Schema Information
#
# Table name: comment_automation_message_logs
#
#  id           :bigint           not null, primary key
#  sent_at      :datetime
#  status       :integer          default("pending"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#  comment_id   :string           not null
#  commenter_id :string           not null
#  contact_id   :bigint
#  inbox_id     :bigint           not null
#  trigger_id   :bigint           not null
#
# Indexes
#
#  index_ca_msg_logs_on_inbox_comment                   (inbox_id,comment_id) UNIQUE
#  index_comment_automation_message_logs_on_account_id  (account_id)
#  index_comment_automation_message_logs_on_contact_id  (contact_id)
#  index_comment_automation_message_logs_on_inbox_id    (inbox_id)
#  index_comment_automation_message_logs_on_trigger_id  (trigger_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#  fk_rails_...  (trigger_id => comment_automation_triggers.id)
#
class CommentAutomation::MessageLog < ApplicationRecord
  belongs_to :trigger, class_name: 'CommentAutomation::Trigger'
  belongs_to :account
  belongs_to :inbox
  belongs_to :contact, optional: true

  enum status: { pending: 0, public_replied: 1, dm_sent: 2, dm_failed: 3, engaged: 4 }

  validates :comment_id, presence: true
  validates :commenter_id, presence: true
end
