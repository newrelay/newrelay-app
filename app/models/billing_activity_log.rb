# == Schema Information
#
# Table name: billing_activity_logs
#
#  id               :bigint           not null, primary key
#  action           :string           not null
#  error_class      :string
#  message          :text             not null
#  metadata         :jsonb            not null
#  payment_provider :string
#  status           :string           default("failed"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  user_id          :bigint
#
# Indexes
#
#  index_billing_activity_logs_on_account_id  (account_id)
#  index_billing_activity_logs_on_action      (action)
#  index_billing_activity_logs_on_created_at  (created_at)
#  index_billing_activity_logs_on_status      (status)
#  index_billing_activity_logs_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class BillingActivityLog < ApplicationRecord
  STATUSES = %w[success failed].freeze

  belongs_to :account
  belongs_to :user, optional: true

  validates :action, :message, :status, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent_first, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: 'success') }
  scope :failed, -> { where(status: 'failed') }

  def success?
    status == 'success'
  end

  def metadata_preview
    JSON.pretty_generate(metadata.presence || {})
  rescue JSON::GeneratorError
    metadata.to_s
  end
end
