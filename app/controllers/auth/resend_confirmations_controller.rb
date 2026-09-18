# Unauthenticated endpoint for resending confirmation emails during signup.
# This is a standalone controller (not on DeviseOverrides::ConfirmationsController)
# because OmniAuth middleware intercepts all POST /auth/* routes as provider
# callbacks, and Devise controller filters cause 307 redirects for custom actions.
# Inherits from ActionController::API to avoid both issues entirely.
# Rate-limited by Rack::Attack (IP + email) and gated by hCaptcha.
class Auth::ResendConfirmationsController < ActionController::API
  def create
    return head(:ok) unless ChatwootCaptcha.new(params[:h_captcha_client_response]).valid?

    email = params[:email]
    return head(:ok) unless email.is_a?(String)

    user = User.from_email(email.strip.downcase)
    Current.mailer_account = Account.for_custom_domain(request.host)
    user&.send_confirmation_instructions unless user&.confirmed?
    head :ok
  ensure
    Current.mailer_account = nil
  end
end
