class Enterprise::Api::V1::MarketplaceCheckoutController < Api::BaseController
  include Enterprise::BillingActivityLogging

  before_action :fetch_account
  before_action :ensure_marketplace_client

  def create
    currency = params[:currency] || 'usd'
    success_url = params[:success_url].presence || default_return_url
    cancel_url = params[:cancel_url].presence || default_return_url

    service = Enterprise::Billing::Tier3CheckoutService.new(
      account: @account,
      currency: currency,
      success_url: success_url,
      cancel_url: cancel_url
    )

    result = service.perform
    provider = @account.parent&.connected_account&.payment_provider
    log_billing_success(
      'marketplace_checkout',
      "Marketplace checkout session created (#{currency.upcase})",
      payment_provider: provider,
      metadata: { currency: currency, checkout_id: result[:id] || result[:checkout_url] }
    )
    render json: result
  rescue StandardError => e
    provider = @account.parent&.connected_account&.payment_provider
    render_payment_failure(
      'marketplace_checkout',
      e.message,
      error_class: e.class.name,
      payment_provider: provider
    )
  end

  private

  def fetch_account
    @account = current_user.accounts.find(params[:account_id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
    raise Pundit::NotAuthorizedError unless @current_account_user&.administrator?
  end

  def ensure_marketplace_client
    return if @account.parent_id.present?

    render_payment_failure('marketplace_checkout', 'Account must have a reseller parent to subscribe')
  end

  def default_return_url
    "#{ENV.fetch('FRONTEND_URL', request.base_url)}/app/accounts/#{@account.id}/settings/billing"
  end
end
