# Handles OAuth callback for both Google Business Profile and Facebook Pages.
# URL: GET /reputation/oauth/callback?provider=google&code=...&state=...
class Reputation::OauthCallbacksController < ApplicationController
  # rubocop:disable Rails/I18nLocaleTexts
  skip_before_action :verify_authenticity_token, raise: false

  def show
    if params[:provider] == 'google'
      handle_google_callback
    else
      handle_provider_callback
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    error_msg = URI.encode_www_form_component(e.message)
    redirect_to "#{settings_url}?google_oauth=error&message=#{error_msg}"
  end

  private

  def settings_url
    "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{current_account.id}/reputation/settings"
  end

  def handle_google_callback
    oauth_service = Reputation::OauthService.new(
      account: current_account,
      provider: 'google',
      code: params[:code]
    )
    token_data = oauth_service.exchange_google_code_for_tokens

    cache_key = "reputation_google_oauth_#{current_account.id}_#{SecureRandom.hex(10)}"
    $alfred.with { |redis| redis.set(cache_key, token_data.to_json, ex: 15.minutes.to_i) }

    redirect_to "#{settings_url}?google_oauth=success&oauth_session_id=#{cache_key}",
                notice: 'Google Account authenticated. Please select a business profile location to connect.'
  end

  def handle_provider_callback
    result = Reputation::OauthService.new(
      account: current_account,
      provider: params[:provider],
      code: params[:code]
    ).connect!

    if result
      redirect_to settings_url, notice: 'Connected successfully.'
    else
      redirect_to settings_url, alert: 'Connection failed.'
    end
  end

  def current_account
    @current_account ||= Account.find(params[:state] || params[:account_id])
  end
end
# rubocop:enable Rails/I18nLocaleTexts
