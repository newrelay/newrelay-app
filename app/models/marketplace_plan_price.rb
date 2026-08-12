# == Schema Information
#
# Table name: marketplace_plan_prices
#
#  id                  :bigint           not null, primary key
#  active              :boolean          default(TRUE)
#  agency_price        :decimal(10, 2)   not null
#  commission_percent  :decimal(5, 2)    not null
#  currency            :string           default("usd"), not null
#  platform_fee_amount :decimal(10, 2)   not null
#  total_amount        :decimal(10, 2)   not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  razorpay_plan_id    :string
#  stripe_price_id     :string
#  stripe_product_id   :string
#
# Indexes
#
#  index_marketplace_plan_prices_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class MarketplacePlanPrice < ApplicationRecord
  belongs_to :account

  validates :currency, presence: true
  validates :agency_price, presence: true, numericality: { greater_than: 0 }
  validates :commission_percent, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :platform_fee_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_amount, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }

  def payment_gateway
    return 'Razorpay' if razorpay_plan_id.present? || currency.to_s.downcase == 'inr'
    return 'Stripe' if stripe_price_id.present?

    currency.to_s.downcase == 'inr' ? 'Razorpay' : 'Stripe'
  end

  before_validation :calculate_fees, on: :create
  before_create :deactivate_old_prices
  before_create :create_provider_price

  private

  def calculate_fees
    return if agency_price.blank?

    self.commission_percent ||= CommissionRule.current_percent_for(account)
    self.platform_fee_amount = (agency_price * (commission_percent / 100.0)).round(2)
    self.total_amount = agency_price + platform_fee_amount
  end

  def deactivate_old_prices
    account.marketplace_plan_prices.where(active: true, currency: currency.downcase).update_all(active: false)
  end

  def create_provider_price
    if account.connected_account&.payment_provider == 'razorpay' || currency.to_s.downcase == 'inr'
      create_razorpay_plan
    else
      create_stripe_price
    end
  end

  def create_razorpay_plan
    return if razorpay_plan_id.present?

    plan = Enterprise::Billing::RazorpayClient.new.create_plan(
      period: 'monthly',
      interval: 1,
      item: {
        name: "Workspace Subscription (#{account.brand_name.presence || account.name})",
        amount: (total_amount * 100).to_i,
        currency: currency.to_s.upcase,
        description: 'Marketplace workspace subscription'
      },
      notes: {
        reseller_account_id: account.id.to_s,
        agency_price: agency_price.to_s,
        platform_fee_amount: platform_fee_amount.to_s
      }
    )
    self.razorpay_plan_id = plan['id']
  rescue Enterprise::Billing::RazorpayClient::Error => e
    errors.add(:base, "Razorpay API error: #{e.message}")
    throw(:abort)
  end

  def create_stripe_price
    return if stripe_price_id.present?

    product_name = "Workspace Subscription (#{account.brand_name.presence || account.name})"
    product = Stripe::Product.create({
                                      name: product_name,
                                      metadata: {
                                        reseller_account_id: account.id.to_s
                                      }
                                    })

    price = Stripe::Price.create({
                                   product: product.id,
                                   unit_amount: (total_amount * 100).to_i,
                                   currency: currency.downcase,
                                   recurring: { interval: 'month' },
                                   metadata: {
                                     reseller_account_id: account.id.to_s,
                                     agency_price: agency_price.to_s,
                                     platform_fee_amount: platform_fee_amount.to_s
                                   }
                                 })

    self.stripe_product_id = product.id
    self.stripe_price_id = price.id
  rescue Stripe::StripeError => e
    errors.add(:base, "Stripe API error: #{e.message}")
    throw(:abort)
  end
end
