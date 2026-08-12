class Enterprise::Billing::CreateSessionService
  def create_session(customer_id, return_url = ENV.fetch('FRONTEND_URL'))
    Stripe::BillingPortal::Session.create(
      {
        customer: customer_id,
        return_url: return_url
      }
    )
  rescue StandardError => e
    raise e unless Rails.env.development? || Rails.env.test?

    Struct.new(:url).new("/super_admin/plan_management")
  end
end
