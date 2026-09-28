class Api::V1::Accounts::NumberProvisioning::OrdersController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  rescue_from ::NumberProvisioning::Provider::ProviderDisabledError, with: :render_provider_disabled
  rescue_from ::NumberProvisioning::Provider::RequestError, with: :render_provider_request_error

  IDEMPOTENCY_TTL = 10.minutes.to_i
  IDEMPOTENCY_IN_PROGRESS = 'in_progress'.freeze

  def index
    @orders = Current.account.number_provisioning_orders.order(created_at: :desc)
  end

  def search
    provider = NumberProvisioning.for(account: Current.account, country_code: params[:country_code])
    @results = provider.search(country_code: params[:country_code], type: params[:type])
  end

  def create
    # Resolved before any idempotency claim: a disabled/unresolvable provider is a
    # static, request-independent condition (not something idempotency protects
    # against), and claiming the Redis slot first would orphan it as permanently
    # "in_progress" for the rest of the TTL if this raises.
    provider = NumberProvisioning.for(account: Current.account, country_code: order_params[:country_code])
    @order = resolve_idempotent_order(provider)
  end

  private

  # Atomically claims the idempotency slot (outside-voice review finding: a plain
  # GET-then-later-SET lets two near-simultaneous requests both pass the check
  # before either writes). Three outcomes: we claim the slot and proceed fresh;
  # another request is claiming it right now (reject, don't duplicate-order); or
  # the slot already holds a real order from a prior attempt -- replay it, unless
  # it failed, in which case reclaim the slot for a genuine retry instead of
  # silently no-op'ing for the rest of the TTL window.
  def resolve_idempotent_order(provider)
    return place_order(provider) if idempotency_key.blank?
    return place_order(provider) if Redis::Alfred.set(idempotency_cache_key, IDEMPOTENCY_IN_PROGRESS, nx: true, ex: IDEMPOTENCY_TTL)

    existing = Redis::Alfred.get(idempotency_cache_key)
    return render_order_in_progress if existing == IDEMPOTENCY_IN_PROGRESS

    order = Current.account.number_provisioning_orders.find_by(id: existing)
    return order if order && order.status != 'failed'

    Redis::Alfred.set(idempotency_cache_key, IDEMPOTENCY_IN_PROGRESS, ex: IDEMPOTENCY_TTL)
    place_order(provider)
  end

  def render_order_in_progress
    render_could_not_create_error('An order for this number is already being processed. Please try again in a moment.')
  end

  def place_order(provider)
    order = Current.account.number_provisioning_orders.create!(
      country_code: order_params[:country_code],
      phone_number: order_params[:phone_number],
      provider_type: provider.class::PROVIDER_TYPE,
      status: 'order_placed'
    )
    store_idempotency_key(order.id)
    submit_to_provider(provider, order)

    ::NumberProvisioning::PollOrderStatusJob.perform_later(order.id)
    order
  end

  def submit_to_provider(provider, order)
    response = provider.order(phone_number: order_params[:phone_number])
    order.update!(provider_order_id: provider_order_id_from(response))
    Rails.logger.info(
      "[NumberProvisioning] order placed account_id=#{Current.account.id} provider_type=#{order.provider_type} " \
      "order_id=#{order.id} provider_order_id=#{order.provider_order_id}"
    )
  rescue ::NumberProvisioning::Provider::RequestError => e
    # Without this, a provider failure here (network blip, or the number being taken by
    # another buyer between search and confirm) left the row stuck in 'order_placed'
    # forever -- no job ever watches it, since PollOrderStatusJob is only enqueued in
    # place_order, after this method returns.
    order.update!(status: 'failed', provisioning_error: e.message)
    Rails.logger.info(
      "[NumberProvisioning] order failed account_id=#{Current.account.id} provider_type=#{order.provider_type} " \
      "order_id=#{order.id} error=#{e.message}"
    )
    raise
  end

  def store_idempotency_key(order_id)
    return if idempotency_key.blank?

    Redis::Alfred.set(idempotency_cache_key, order_id, ex: IDEMPOTENCY_TTL)
  end

  def idempotency_key
    request.headers['Idempotency-Key']
  end

  def idempotency_cache_key
    "number_provisioning:idempotency:#{Current.account.id}:#{idempotency_key}"
  end

  def check_authorization
    authorize(@order || ::NumberProvisioning::Order)
  end

  def render_provider_disabled(exception)
    log_handled_error(exception)
    render_could_not_create_error('This provider is not available yet.')
  end

  def render_provider_request_error(exception)
    log_handled_error(exception)
    render_could_not_create_error(exception.message)
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
