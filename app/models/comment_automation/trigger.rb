class CommentAutomation::Trigger < ApplicationRecord
  belongs_to :campaign, class_name: 'CommentAutomation::Campaign'
  belongs_to :account
  has_many :message_logs, class_name: 'CommentAutomation::MessageLog', foreign_key: :trigger_id, dependent: :destroy, inverse_of: :trigger

  enum match_type: { exact: 0, contains: 1 }

  validates :dm_text_body, presence: true
  validates :public_replies, presence: true
end
