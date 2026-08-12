# == Schema Information
#
# Table name: reputation_review_replies
#
#  id                   :bigint           not null, primary key
#  body                 :text             not null
#  published_at         :datetime
#  status               :string           default("draft")
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  reputation_review_id :bigint           not null
#
# Indexes
#
#  index_reputation_review_replies_on_account_id            (account_id)
#  index_reputation_review_replies_on_reputation_review_id  (reputation_review_id)
#
class Reputation::ReviewReply < ApplicationRecord
  self.table_name = 'reputation_review_replies'

  belongs_to :reputation_review, class_name: 'Reputation::Review'
  belongs_to :account

  enum :status, { draft: 'draft', published: 'published' }

  validates :body, presence: true
end
