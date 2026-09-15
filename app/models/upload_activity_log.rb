# == Schema Information
#
# Table name: upload_activity_logs
#
#  id          :bigint           not null, primary key
#  action      :string           not null
#  error_class :string
#  message     :text             not null
#  metadata    :jsonb            not null
#  notified_at :datetime
#  status      :string           default("failed"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  user_id     :bigint
#
# Indexes
#
#  index_upload_activity_logs_on_account_id   (account_id)
#  index_upload_activity_logs_on_action       (action)
#  index_upload_activity_logs_on_created_at   (created_at)
#  index_upload_activity_logs_on_notified_at  (notified_at)
#  index_upload_activity_logs_on_status       (status)
#  index_upload_activity_logs_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class UploadActivityLog < ApplicationRecord
  STATUSES = %w[success failed].freeze

  belongs_to :account
  belongs_to :user, optional: true

  validates :action, :message, :status, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent_first, -> { order(created_at: :desc) }
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
