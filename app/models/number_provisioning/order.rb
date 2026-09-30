# == Schema Information
#
# Table name: number_provisioning_orders
#
#  id                       :bigint           not null, primary key
#  billing_reference        :string
#  country_code             :string           not null
#  currency                 :string
#  failure_code             :string
#  margin_cents             :integer
#  phone_number             :string
#  provider_cost_cents      :integer
#  provider_type            :string           not null
#  provisioning_error       :string
#  regulatory_requirements  :jsonb            not null
#  requirements_deadline_at :datetime
#  status                   :string           default("search_pending"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#  inbox_id                 :bigint
#  provider_order_id        :string
#
# Indexes
#
#  idx_on_provider_type_provider_order_id_988b2da93d  (provider_type,provider_order_id) UNIQUE WHERE (provider_order_id IS NOT NULL)
#  index_np_orders_live_account_phone                 (account_id,phone_number) UNIQUE WHERE (((status)::text = ANY ((ARRAY['order_placed'::character varying, 'requirements_pending'::character varying, 'requirements_under_review'::character varying, 'requirements_rejected'::character varying, 'billing_failed'::character varying, 'inbox_pending'::character varying, 'active'::character varying])::text[])) AND (phone_number IS NOT NULL))
#  index_number_provisioning_orders_on_account_id     (account_id)
#  index_number_provisioning_orders_on_inbox_id       (inbox_id)
#  index_number_provisioning_orders_on_status         (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class NumberProvisioning::Order < ApplicationRecord
  has_one_attached :requirement_document

  STATUSES = %w[search_pending order_placed requirements_pending requirements_under_review
                requirements_rejected active failed cancelled billing_failed inbox_pending].freeze
  # billing_failed stops the poll. inbox_pending does not: the inbox is retried.
  FINISHED_STATUSES = %w[active failed cancelled billing_failed].freeze
  REQUIREMENT_STATUSES = %w[requirements_pending requirements_under_review requirements_rejected].freeze

  FAILURE_MESSAGES = {
    'insufficient_balance' => 'The phone number provider does not have enough balance to buy this number.',
    'provider_disabled' => 'This provider is not available yet.',
    'timeout' => 'The phone number provider did not respond in time. Please try again.',
    'cost_unknown' => 'The price for this number is no longer available. Search again before buying.',
    'currency_mismatch' => 'This number cannot be billed because the subscription uses a different currency.',
    'not_billable' => 'This number cannot be billed because the subscription is not active.',
    'charge_unavailable' => 'This number cannot be added to the current subscription.',
    'inbox_conflict' => 'This number is paid for, but it is already in use so the inbox is not ready.',
    'unknown' => 'The phone number provider returned an error. Please try again or contact support.'
  }.freeze

  belongs_to :account
  belongs_to :inbox, optional: true

  validates :provider_type, :country_code, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :phone_number, presence: true,
                           format: { with: /\A\+[1-9]\d{6,14}\z/ }

  def finished?
    FINISHED_STATUSES.include?(status)
  end

  def failure_message
    self.class.failure_message_for(failure_code)
  end

  def self.failure_message_for(code)
    FAILURE_MESSAGES[code]
  end
end
