# == Schema Information
#
# Table name: billing_coupons
#
#  id                 :bigint           not null, primary key
#  active             :boolean          default(TRUE), not null
#  amount_off         :decimal(10, 2)
#  applies_to         :string           default("plan"), not null
#  code               :string           not null
#  currency           :string           default("usd")
#  discount_type      :string           default("percent"), not null
#  duration           :string           default("once"), not null
#  duration_in_months :integer
#  max_redemptions    :integer
#  metadata           :jsonb            not null
#  name               :string           not null
#  percent_off        :decimal(5, 2)
#  redeem_by          :datetime
#  times_redeemed     :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  razorpay_offer_id  :string
#  stripe_coupon_id   :string
#
# Indexes
#
#  index_billing_coupons_on_active            (active)
#  index_billing_coupons_on_code              (code) UNIQUE
#  index_billing_coupons_on_stripe_coupon_id  (stripe_coupon_id) UNIQUE WHERE (stripe_coupon_id IS NOT NULL)
#
class BillingCoupon < ApplicationRecord
  DISCOUNT_TYPES = %w[percent amount].freeze
  DISCOUNT_TYPE_OPTIONS = [
    ['Percent off', 'percent'],
    ['Amount off', 'amount']
  ].freeze
  DURATIONS = %w[once repeating forever].freeze
  APPLIES_TO = %w[plan topup all].freeze
  CODE_PREFIX = 'NR'.freeze

  before_validation :assign_code_if_blank
  before_validation :normalize_code
  before_validation :normalize_discount_fields

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :discount_type, inclusion: { in: DISCOUNT_TYPES }
  validates :duration, inclusion: { in: DURATIONS }
  validates :applies_to, inclusion: { in: APPLIES_TO }
  validates :percent_off, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, if: -> { discount_type == 'percent' }
  validates :amount_off, numericality: { greater_than: 0 }, if: -> { discount_type == 'amount' }
  validates :duration_in_months, numericality: { greater_than: 0 }, if: -> { duration == 'repeating' }

  scope :active, -> { where(active: true) }

  def self.generate_code
    loop do
      candidate = "#{CODE_PREFIX}#{SecureRandom.alphanumeric(8).upcase}"
      break candidate unless exists?(code: candidate)
    end
  end

  def redeemable?
    return false unless active?
    return false if redeem_by.present? && redeem_by.past?
    return false if max_redemptions.present? && times_redeemed >= max_redemptions

    true
  end

  def applies_to_plan?
    %w[plan all].include?(applies_to)
  end

  def applies_to_topup?
    %w[topup all].include?(applies_to)
  end

  def discount_label
    if discount_type == 'percent'
      "#{percent_off.to_i}% off"
    else
      "#{currency.to_s.upcase} #{format('%.2f', amount_off)} off"
    end
  end

  # Returns the payable amount after this coupon is applied to `base_amount`.
  def discounted_amount(base_amount)
    base = base_amount.to_f
    discounted = if discount_type == 'percent'
                   base * (1 - (percent_off.to_f / 100.0))
                 else
                   base - amount_off.to_f
                 end
    [discounted, 0].max.round(2)
  end

  def gateway_metadata
    {
      local_coupon_id: id.to_s,
      coupon_code: code,
      discount_type: discount_type,
      percent_off: percent_off&.to_s,
      amount_off: amount_off&.to_s,
      currency: currency,
      duration: duration,
      applies_to: applies_to
    }.compact
  end

  def record_redemption!
    increment!(:times_redeemed)
  end

  def gateway_sync
    parts = []
    parts << 'Stripe' if stripe_coupon_id.present?
    parts << 'Razorpay' if razorpay_offer_id.present?
    parts.presence&.join(' + ') || 'Not synced'
  end

  private

  def assign_code_if_blank
    self.code = self.class.generate_code if code.blank?
  end

  def normalize_code
    self.code = code.to_s.strip.upcase
  end

  def normalize_discount_fields
    if discount_type == 'percent'
      self.amount_off = nil
    elsif discount_type == 'amount'
      self.percent_off = nil
    end
  end
end
