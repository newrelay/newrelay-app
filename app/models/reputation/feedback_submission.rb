# == Schema Information
#
# Table name: reputation_feedback_submissions
#
#  id                           :bigint           not null, primary key
#  body                         :text
#  rating                       :integer          not null
#  reviewer_name                :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  account_id                   :bigint           not null
#  reputation_review_request_id :bigint           not null
#
# Indexes
#
#  idx_on_reputation_review_request_id_f7ad17c20e       (reputation_review_request_id)
#  index_reputation_feedback_submissions_on_account_id  (account_id)
#
class Reputation::FeedbackSubmission < ApplicationRecord
  self.table_name = 'reputation_feedback_submissions'

  belongs_to :account
  belongs_to :reputation_review_request, class_name: 'Reputation::ReviewRequest'

  validates :rating, presence: true, inclusion: { in: 1..3 }
end
