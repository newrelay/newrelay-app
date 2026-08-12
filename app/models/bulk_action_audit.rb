# == Schema Information
#
# Table name: bulk_action_audits
#
#  id             :bigint           not null, primary key
#  action_label   :string           not null
#  completed_at   :datetime
#  operation_type :string           not null
#  statistics     :jsonb
#  status         :integer          default("pending"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_bulk_action_audits_on_account_id  (account_id)
#  index_bulk_action_audits_on_user_id     (user_id)
#
class BulkActionAudit < ApplicationRecord
  belongs_to :account
  belongs_to :user

  enum status: { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :action_label, presence: true
  validates :operation_type, presence: true
  validates :account_id, presence: true
  validates :user_id, presence: true
end
