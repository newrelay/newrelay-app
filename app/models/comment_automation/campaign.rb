# == Schema Information
#
# Table name: comment_automation_campaigns
#
#  id         :bigint           not null, primary key
#  is_active  :boolean          default(TRUE), not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  inbox_id   :bigint           not null
#  post_id    :string           not null
#
# Indexes
#
#  index_comment_automation_campaigns_on_account_id              (account_id)
#  index_comment_automation_campaigns_on_account_id_and_post_id  (account_id,post_id)
#  index_comment_automation_campaigns_on_inbox_id                (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
class CommentAutomation::Campaign < ApplicationRecord
  belongs_to :account
  belongs_to :inbox
  has_many :triggers, class_name: 'CommentAutomation::Trigger', foreign_key: :campaign_id, dependent: :destroy, inverse_of: :campaign

  validates :name, presence: true
  validates :post_id, presence: true
end
