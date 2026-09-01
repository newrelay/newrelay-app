class CommentAutomation::Campaign < ApplicationRecord
  belongs_to :account
  belongs_to :inbox
  has_many :triggers, class_name: 'CommentAutomation::Trigger', foreign_key: :campaign_id, dependent: :destroy, inverse_of: :campaign

  validates :name, presence: true
  validates :post_id, presence: true
end
