# Creates a Stripe Checkout session for a one-time Captain AI credit purchase.
# Credits are granted when Stripe sends checkout.session.completed (see
# HandleStripeEventService) - same pattern as plan checkout, so users without a
# saved card can still pay via Stripe's hosted page (required for RBI/India too).
class Enterprise::Billing::TopupCheckoutService
  include BillingHelper

  class Error < StandardError; end

  TOPUP_OPTIONS = [
    { credits: 1000, amount: 20.0, currency: 'usd' },
    { credits: 2500, amount: 50.0, currency: 'usd' },
    { credits: 6000, amount: 100.0, currency: 'usd' },
    { credits: 12_000, amount: 200.0, currency: 'usd' }
  ].freeze

  pattr_initialize [:account!, :success_url!, :cancel_url!]

  def create_checkout_session(credits:)
    topup_option = validate_and_find_topup_option(credits)

    session = Stripe::Checkout::Session.create(
      mode: 'payment',
      customer: find_or_create_customer,
      customer_update: { name: 'auto', address: 'auto' },
      billing_address_collection: 'required',
      # One-time Checkout does not create a Stripe Invoice unless this is on -
      # without it there is no hosted invoice/PDF for Captain credit purchases.
      invoice_creation: {
        enabled: true,
        invoice_data: {
          description: "Captain AI Credits - #{credits.to_i} credits",
          metadata: session_metadata(credits, topup_option)
        }
      },
      line_items: [{
        price_data: {
          currency: topup_option[:currency],
          product_data: { name: "Captain AI Credits - #{credits.to_i} credits" },
          unit_amount: (topup_option[:amount] * 100).to_i
        },
        quantity: 1
      }],
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: session_metadata(credits, topup_option),
      payment_intent_data: { metadata: session_metadata(credits, topup_option) }
    )

    { checkout_url: session.url }
  end

  private

  def validate_and_find_topup_option(credits)
    raise Error, I18n.t('errors.topup.invalid_credits') unless credits.to_i.positive?
    raise Error, I18n.t('errors.topup.plan_not_eligible') if default_plan?(account) || free_plan?

    topup_option = TOPUP_OPTIONS.find { |opt| opt[:credits] == credits.to_i }
    raise Error, I18n.t('errors.topup.invalid_option') unless topup_option

    topup_option
  end

  # Hobby (and legacy Hacker) are free tiers - top-ups require a paid plan.
  def free_plan?
    %w[hobby hacker].include?(account.custom_attributes['plan_name']&.downcase)
  end

  def session_metadata(credits, topup_option)
    {
      source: 'captain_topup',
      account_id: account.id.to_s,
      credits: credits.to_i.to_s,
      amount: topup_option[:amount].to_s,
      currency: topup_option[:currency]
    }
  end

  def find_or_create_customer
    customer_id = account.custom_attributes['stripe_customer_id']
    return customer_id if customer_id.present?

    customer = Stripe::Customer.create(
      name: account.name,
      email: account.administrators.first&.email,
      metadata: { account_id: account.id.to_s }
    )
    account.update!(
      custom_attributes: (account.custom_attributes || {}).merge('stripe_customer_id' => customer.id)
    )
    customer.id
  end
end
