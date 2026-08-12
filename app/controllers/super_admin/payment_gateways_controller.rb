class SuperAdmin::PaymentGatewaysController < SuperAdmin::ApplicationController
  def show
    @gateways = Enterprise::Billing::PaymentGatewayRegistry.admin_view
  end

  def update
    Enterprise::Billing::PaymentGatewayRegistry.save!(params[:gateways] || {})
    redirect_to super_admin_payment_gateways_path, notice: 'Payment gateway settings updated.'
  rescue Enterprise::Billing::PaymentGatewayRegistry::ValidationError => e
    redirect_to super_admin_payment_gateways_path, alert: e.message
  end
end
