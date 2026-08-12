# == Schema Information
#
# Table name: reputation_review_requests
#
#  id                     :bigint           not null, primary key
#  channel                :string           not null
#  clicked_at             :datetime
#  completed_at           :datetime
#  status                 :string           default("sent")
#  token                  :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint           not null
#  contact_id             :bigint           not null
#  reputation_template_id :bigint           not null
#
# Indexes
#
#  index_reputation_review_requests_on_account_id              (account_id)
#  index_reputation_review_requests_on_account_id_and_status   (account_id,status)
#  index_reputation_review_requests_on_contact_id              (contact_id)
#  index_reputation_review_requests_on_reputation_template_id  (reputation_template_id)
#  index_reputation_review_requests_on_token                   (token) UNIQUE
#
class Reputation::ReviewRequest < ApplicationRecord
  self.table_name = 'reputation_review_requests'

  belongs_to :account
  belongs_to :reputation_template, class_name: 'Reputation::Template'
  belongs_to :contact
  has_one :reputation_feedback_submission, class_name: 'Reputation::FeedbackSubmission',
                                           foreign_key: :reputation_review_request_id, dependent: :destroy

  enum :channel, { sms: 'sms', email: 'email' }
  enum :status, { sent: 'sent', delivered: 'delivered', clicked: 'clicked', completed: 'completed' }

  validates :token, :channel, presence: true
  validates :token, uniqueness: true

  before_validation :set_token, on: :create

  private

  def set_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end
end
