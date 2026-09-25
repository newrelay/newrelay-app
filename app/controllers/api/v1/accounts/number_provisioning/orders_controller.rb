class Api::V1::Accounts::NumberProvisioning::OrdersController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def search
    provider = NumberProvisioning.for(account: Current.account, country_code: params[:country_code])
    @results = provider.search(country_code: params[:country_code], type: params[:type])
  end

  def create
    provider = NumberProvisioning.for(account: Current.account, country_code: order_params[:country_code])
    @order = Current.account.number_provisioning_orders.create!(
      country_code: order_params[:country_code],
      phone_number: order_params[:phone_number],
      provider_type: provider_type_for(provider),
      status: 'order_placed'
    )

    response = provider.order(phone_number: order_params[:phone_number])
    @order.update!(provider_order_id: provider_order_id_from(response))

    ::NumberProvisioning::PollOrderStatusJob.perform_later(@order.id)
  end

  private

  def check_authorization
    authorize(@order || ::NumberProvisioning::Order)
  end

  def provider_type_for(provider)
    provider.class.name.demodulize.remove('Provider').underscore
  end

  # TODO: the raw order-id field is unconfirmed per provider -- same "no captured response"
  # gap the design doc flags for price normalization (see §3a). Verify against a real
  # Telnyx/Exotel order response before relying on this in production.
  def provider_order_id_from(response)
    response['id']
  end

  def order_params
    params.require(:order).permit(:country_code, :phone_number)
  end
end
