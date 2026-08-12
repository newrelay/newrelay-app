# Onboards an Indian reseller onto Razorpay Route (linked account). The reseller
# finishes KYC on Razorpay's hosted side; we poll status via sync_status.
class Enterprise::Billing::RazorpayConnectOnboardingService
  class Error < StandardError; end

  pattr_initialize [:account!]

  def create_onboarding_link(country:, refresh_url:, return_url:)
    connected_account = find_or_create_connected_account(country)
    sync_route_account!(connected_account)

    {
      connected_account: connected_account,
      # Razorpay Route has no Stripe-style AccountLink; send the reseller to the
      # Razorpay dashboard / returned activation URL when present.
      onboarding_url: onboarding_url_for(connected_account, return_url)
    }
  end

  def sync_status
    return nil if account.connected_account.blank?
    return account.connected_account unless account.connected_account.payment_provider == 'razorpay'

    sync_route_account!(account.connected_account)
  end

  private

  def find_or_create_connected_account(country)
    return account.connected_account if account.connected_account.present?

    route_account = client.create_route_account(route_account_payload)
    account.create_connected_account!(
      payment_provider: 'razorpay',
      razorpay_account_id: route_account['id'],
      stripe_account_id: nil,
      country: country.to_s.upcase.presence || 'IN',
      charge_routing: 'separate_charge_transfer',
      onboarding_status: 'onboarding_incomplete',
      charges_enabled: false,
      payouts_enabled: false
    )
  end

  def route_account_payload
    admin = account.administrators.first
    {
      email: admin&.email,
      phone: admin&.phone_number.presence || '9999999999',
      type: 'route',
      legal_business_name: account.brand_name.presence || account.name,
      business_type: 'individual',
      contact_name: admin&.name.presence || account.name,
      profile: {
        category: 'services',
        subcategory: 'software',
        addresses: {
          registered: {
            street1: 'To be updated',
            city: 'Mumbai',
            state: 'MAHARASHTRA',
            postal_code: '400001',
            country: 'IN'
          }
        }
      },
      legal_info: {
        pan: ENV.fetch('RAZORPAY_ROUTE_DUMMY_PAN', 'AAAPL1234C')
      }
    }
  end

  def sync_route_account!(connected_account)
    return connected_account if connected_account.razorpay_account_id.blank?

    route_account = client.fetch_route_account(connected_account.razorpay_account_id)
    status = route_account['status'].to_s
    activated = %w[activated].include?(status)

    connected_account.update!(
      onboarding_status: activated ? 'active' : 'onboarding_incomplete',
      charges_enabled: activated,
      payouts_enabled: activated
    )
    connected_account
  rescue Enterprise::Billing::RazorpayClient::Error => e
    Rails.logger.warn("[razorpay_connect] sync failed for account #{account.id}: #{e.message}")
    connected_account
  end

  def onboarding_url_for(connected_account, return_url)
    connected_account.charges_enabled? ? return_url : 'https://dashboard.razorpay.com/app/route/accounts'
  end

  def client
    @client ||= Enterprise::Billing::RazorpayClient.new
  end
end
