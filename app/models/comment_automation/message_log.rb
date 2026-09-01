class CommentAutomation::MessageLog < ApplicationRecord
  belongs_to :trigger, class_name: 'CommentAutomation::Trigger'
  belongs_to :account
  belongs_to :inbox
  belongs_to :contact, optional: true

  enum status: { pending: 0, public_replied: 1, dm_sent: 2, dm_failed: 3, engaged: 4 }

  validates :comment_id, presence: true
  validates :commenter_id, presence: true
end
