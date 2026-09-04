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

  before_validation :normalize_post_id

  def self.normalize_post_id(value)
    raw = value.to_s.strip
    match = raw.match(%r{instagram\.com/(?:p|reel|tv)/([^/?#]+)}i)
    (match && match[1]) || raw
  end

  def self.active_for_post(inbox:, post_id:)
    media_id = normalize_post_id(post_id)
    return none if inbox.blank? || media_id.blank?

    where(account_id: inbox.account_id, inbox_id: inbox.id, is_active: true)
      .includes(:triggers)
      .order(created_at: :desc)
      .select { |campaign| normalize_post_id(campaign.post_id) == media_id }
  end

  private

  def normalize_post_id
    self.post_id = self.class.normalize_post_id(post_id)
  end
end
