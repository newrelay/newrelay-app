# == Schema Information
#
# Table name: subscriptions
#
#  id                       :bigint           not null, primary key
#  application_fee_amount   :decimal(10, 2)
#  cancel_at_period_end     :boolean          default(FALSE), not null
#  current_period_end       :datetime
#  current_period_start     :datetime
#  grace_period_ends_at     :datetime
#  payment_provider         :string           default("stripe"), not null
#  plan_name                :string
#  relationship_type        :string           not null
#  status                   :string           default("trialing")
#  subscribed_quantity      :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#  connected_account_id     :bigint
#  razorpay_customer_id     :string
#  razorpay_subscription_id :string
#  stripe_customer_id       :string
#  stripe_price_id          :string
#  stripe_product_id        :string
#  stripe_subscription_id   :string
#
# Indexes
#
#  index_subscriptions_on_account_id                (account_id) UNIQUE
#  index_subscriptions_on_connected_account_id      (connected_account_id)
#  index_subscriptions_on_razorpay_subscription_id  (razorpay_subscription_id) UNIQUE WHERE (razorpay_subscription_id IS NOT NULL)
#  index_subscriptions_on_stripe_subscription_id    (stripe_subscription_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (connected_account_id => connected_accounts.id)
#
class Subscription < ApplicationRecord
  belongs_to :account
  belongs_to :connected_account, optional: true

  validates :relationship_type, presence: true, inclusion: { in: %w[platform marketplace] }
  validates :status, presence: true
  validates :payment_provider, presence: true, inclusion: { in: %w[stripe razorpay] }

  scope :active, -> { where(status: %w[active trialing]) }
  scope :platform, -> { where(relationship_type: 'platform') }
  scope :marketplace, -> { where(relationship_type: 'marketplace') }
  scope :stripe, -> { where(payment_provider: 'stripe') }
  scope :razorpay, -> { where(payment_provider: 'razorpay') }

  def active?
    return true if %w[active trialing].include?(status)
    return true if %w[past_due unpaid].include?(status) && in_grace_period?

    false
  end

  # While a payment is failing, Stripe keeps retrying the card for a while before
  # finally cancelling the subscription. We give the customer a short grace period of
  # continued access (with a "update your card" banner) instead of locking them out
  # the instant the first retry fails.
  def in_grace_period?
    grace_period_ends_at.present? && grace_period_ends_at.future?
  end
end
