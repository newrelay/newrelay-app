# Creates a Razorpay Payment Link for a one-time Captain AI credit purchase.
# Credits are granted when Razorpay sends payment_link.paid / payment.captured
# (see HandleRazorpayEventService). Amounts are INR packages for Indian billing.
class Enterprise::Billing::RazorpayTopupCheckoutService
  include BillingHelper

  class Error < StandardError; end

  # Approximate INR mirrors of the USD Stripe packages (same credit tiers).
  TOPUP_OPTIONS = [
    { credits: 1000, amount: 1699.0, currency: 'inr' },
    { credits: 2500, amount: 4199.0, currency: 'inr' },
    { credits: 6000, amount: 8299.0, currency: 'inr' },
    { credits: 12_000, amount: 16_499.0, currency: 'inr' }
  ].freeze

  pattr_initialize [:account!, :success_url!, :cancel_url!]

  def create_checkout_session(credits:)
    topup_option = validate_and_find_topup_option(credits)
    amount_paise = (topup_option[:amount] * 100).to_i

    payment_link = client.create_payment_link(
      amount: amount_paise,
      currency: topup_option[:currency].upcase,
      accept_partial: false,
      description: "Captain AI Credits - #{credits.to_i} credits",
      customer: {
        name: account.name,
        email: account.administrators.first&.email
      }.compact,
      notify: { sms: false, email: true },
      reminder_enable: false,
      callback_url: success_url,
      callback_method: 'get',
      notes: session_notes(credits, topup_option)
    )

    {
      checkout_url: payment_link['short_url'],
      provider: 'razorpay',
      razorpay_payment_link_id: payment_link['id']
    }
  end

  private

  def validate_and_find_topup_option(credits)
    raise Error, I18n.t('errors.topup.invalid_credits') unless credits.to_i.positive?
    raise Error, I18n.t('errors.topup.plan_not_eligible') if default_plan?(account) || free_plan?

    topup_option = TOPUP_OPTIONS.find { |opt| opt[:credits] == credits.to_i }
    raise Error, I18n.t('errors.topup.invalid_option') unless topup_option

    topup_option
  end

  def free_plan?
    %w[hobby hacker].include?(account.custom_attributes['plan_name']&.downcase)
  end

  def session_notes(credits, topup_option)
    {
      source: 'captain_topup',
      account_id: account.id.to_s,
      credits: credits.to_i.to_s,
      amount: topup_option[:amount].to_s,
      currency: topup_option[:currency]
    }
  end

  def client
    @client ||= Enterprise::Billing::RazorpayClient.new
  end
end
