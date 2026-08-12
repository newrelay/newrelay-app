# == Schema Information
#
# Table name: connected_accounts
#
#  id                  :bigint           not null, primary key
#  charge_routing      :string           not null
#  charges_enabled     :boolean          default(FALSE)
#  country             :string           not null
#  onboarding_status   :string           default("onboarding_incomplete"), not null
#  payment_provider    :string           default("stripe"), not null
#  payouts_enabled     :boolean          default(FALSE)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  razorpay_account_id :string
#  stripe_account_id   :string
#
# Indexes
#
#  index_connected_accounts_on_account_id           (account_id) UNIQUE
#  index_connected_accounts_on_razorpay_account_id  (razorpay_account_id) UNIQUE WHERE (razorpay_account_id IS NOT NULL)
#  index_connected_accounts_on_stripe_account_id    (stripe_account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class ConnectedAccount < ApplicationRecord
  CHARGE_ROUTINGS = %w[destination separate_charge_transfer].freeze
  ONBOARDING_STATUSES = %w[onboarding_incomplete active disabled].freeze
  PAYMENT_PROVIDERS = %w[stripe razorpay].freeze

  belongs_to :account

  validates :payment_provider, inclusion: { in: PAYMENT_PROVIDERS }
  validates :stripe_account_id, uniqueness: true, allow_nil: true
  validates :razorpay_account_id, uniqueness: true, allow_nil: true
  validates :country, presence: true
  validates :charge_routing, inclusion: { in: CHARGE_ROUTINGS }
  validates :onboarding_status, inclusion: { in: ONBOARDING_STATUSES }
  validate :provider_account_id_present

  private

  def provider_account_id_present
    if payment_provider == 'razorpay'
      errors.add(:razorpay_account_id, "can't be blank") if razorpay_account_id.blank?
    elsif stripe_account_id.blank?
      errors.add(:stripe_account_id, "can't be blank")
    end
  end
end
