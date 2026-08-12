# Thin HTTP wrapper around the Razorpay REST API. Uses RestClient (already in the
# Gemfile) so we don't need an extra gem for the MVP. Auth is HTTP Basic with
# key_id:key_secret per https://razorpay.com/docs/api/authentication/
class Enterprise::Billing::RazorpayClient
  BASE_URL = 'https://api.razorpay.com/v1'.freeze

  class Error < StandardError; end

  def create_subscription(payload)
    post('/subscriptions', payload)
  end

  def fetch_subscription(subscription_id)
    get("/subscriptions/#{subscription_id}")
  end

  def cancel_subscription(subscription_id, cancel_at_cycle_end: true)
    post("/subscriptions/#{subscription_id}/cancel", { cancel_at_cycle_end: cancel_at_cycle_end })
  end

  def create_payment_link(payload)
    post('/payment_links', payload)
  end

  def fetch_payment_link(payment_link_id)
    get("/payment_links/#{payment_link_id}")
  end

  def create_plan(payload)
    post('/plans', payload)
  end

  def fetch_plan(plan_id)
    get("/plans/#{plan_id}")
  end

  # Razorpay Route linked account (API v2).
  def create_route_account(payload)
    request(:post, '/accounts', payload, base_url: 'https://api.razorpay.com/v2')
  end

  def fetch_route_account(account_id)
    request(:get, "/accounts/#{account_id}", nil, base_url: 'https://api.razorpay.com/v2')
  end

  def create_transfer(payload)
    post('/transfers', payload)
  end

  private

  def get(path)
    request(:get, path)
  end

  def post(path, payload)
    request(:post, path, payload)
  end

  def request(method, path, payload = nil, base_url: BASE_URL)
    raise Error, 'Razorpay is not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.' if key_id.blank? || key_secret.blank?

    args = {
      method: method,
      url: "#{base_url}#{path}",
      user: key_id,
      password: key_secret,
      headers: { content_type: :json, accept: :json }
    }
    args[:payload] = payload.to_json if payload.present?

    response = RestClient::Request.execute(args)
    JSON.parse(response.body)
  rescue RestClient::ExceptionWithResponse => e
    message = begin
      JSON.parse(e.response&.body.to_s).dig('error', 'description')
    rescue JSON::ParserError
      e.message
    end
    raise Error, message.presence || e.message
  end

  def key_id
    ENV.fetch('RAZORPAY_KEY_ID', nil)
  end

  def key_secret
    ENV.fetch('RAZORPAY_KEY_SECRET', nil)
  end
end
