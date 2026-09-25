# == Schema Information
#
# Table name: number_provisioning_orders
#
#  id                          :bigint           not null, primary key
#  billing_reference           :string
#  country_code                :string           not null
#  margin_cents                :integer
#  phone_number                :string
#  provider_cost_cents         :integer
#  provider_order_id           :string
#  provider_type               :string           not null
#  provisioning_error          :string
#  regulatory_requirements     :jsonb            not null
#  requirements_deadline_at    :datetime
#  status                      :string           default("search_pending"), not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  account_id                  :bigint           not null
#  inbox_id                    :bigint
#
# Indexes
#
#  index_number_provisioning_orders_on_account_id           (account_id)
#  index_number_provisioning_orders_on_inbox_id              (inbox_id)
#  index_number_provisioning_orders_on_status                (status)
#  idx_on_provider_type_provider_order_id_988b2da93d          (provider_type,provider_order_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class NumberProvisioning::Order < ApplicationRecord
  STATUSES = %w[search_pending order_placed requirements_pending requirements_under_review
                requirements_rejected active failed cancelled].freeze

  belongs_to :account
  belongs_to :inbox, optional: true

  validates :provider_type, :country_code, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
end
