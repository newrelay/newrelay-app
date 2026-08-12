class Enterprise::Api::V1::ConnectedAccountsController < Api::BaseController
  before_action :fetch_account
  before_action :ensure_reseller_account

  def create
    result = onboarding_service.create_onboarding_link(
      country: params[:country],
      refresh_url: params[:refresh_url].presence || default_return_url,
      return_url: params[:return_url].presence || default_return_url
    )

    render json: connected_account_payload(result[:connected_account]).merge(onboarding_url: result[:onboarding_url])
  rescue Stripe::StripeError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def status
    connected_account = onboarding_service.sync_status
    return render json: { connected_account: nil } if connected_account.blank?

    render json: connected_account_payload(connected_account)
  rescue Stripe::StripeError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def fetch_account
    @account = current_user.accounts.find(params[:account_id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
    raise Pundit::NotAuthorizedError unless @current_account_user&.administrator?
  end

  def ensure_reseller_account
    render json: { error: 'Connected account onboarding is only available for reseller accounts' }, status: :forbidden unless @account.is_reseller?
  end

  def onboarding_service
    @onboarding_service ||= Enterprise::Billing::ConnectOnboardingService.new(account: @account)
  end

  def connected_account_payload(connected_account)
    {
      id: connected_account.id,
      account_id: connected_account.account_id,
      stripe_account_id: connected_account.stripe_account_id,
      country: connected_account.country,
      charge_routing: connected_account.charge_routing,
      onboarding_status: connected_account.onboarding_status,
      charges_enabled: connected_account.charges_enabled,
      payouts_enabled: connected_account.payouts_enabled
    }
  end

  def default_return_url
    "#{ENV.fetch('FRONTEND_URL', request.base_url)}/app/accounts/#{@account.id}/settings/billing"
  end
end
