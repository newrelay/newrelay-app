class Api::V1::Accounts::NumberProvisioning::OrdersController < Api::V1::Accounts::BaseController
  before_action :set_order, only: [:requirements, :voice_agent]
  rescue_from ::NumberProvisioning::VoiceAgentAttachService::Error, with: :render_voice_agent_error
  before_action :check_authorization

  rescue_from ::NumberProvisioning::Provider::ProviderDisabledError, with: :render_provider_disabled
  rescue_from ::NumberProvisioning::Provider::CountryNotAllowedError, with: :render_country_not_allowed
  rescue_from ::NumberProvisioning::Provider::RequestError, with: :render_provider_request_error
  rescue_from Net::OpenTimeout, Net::ReadTimeout, with: :render_provider_timeout

  IDEMPOTENCY_TTL = 10.minutes.to_i
  IDEMPOTENCY_IN_PROGRESS = 'in_progress'.freeze
  SEARCH_CACHE_TTL = 5.minutes.to_i

  def index
    @orders = Current.account.number_provisioning_orders.includes(:voice_agent, :inbox).order(created_at: :desc)
  end

  def provisioning_config
    providers = NumberProvisioning::ProviderConfig::DEFINITIONS.keys.index_with do |id|
      NumberProvisioning::ProviderConfig.enabled_for?(id)
    end
    render json: { enabled: providers.values.any?, providers: providers }
  end

  def search
    country_code = params[:country_code].to_s.upcase
    provider = NumberProvisioning.for(account: Current.account, country_code: country_code)
    cache_key = "number_provisioning:search:v2:#{country_code}:#{params[:type]}"
    cache_key = "#{cache_key}:dummy" if country_code == 'IN' && NumberProvisioning::DummyExotel.enabled?
    cached = Redis::Alfred.get(cache_key)
    wholesale = if cached
                  JSON.parse(cached)
                else
                  results = provider.search(country_code: country_code, type: params[:type])
                  Redis::Alfred.setex(cache_key, results.to_json, SEARCH_CACHE_TTL)
                  results
                end
    cache_quotes(country_code, wholesale)
    @results = with_customer_margin(wholesale, provider.class::PROVIDER_TYPE)
  end

  def create
    provider = NumberProvisioning.for(account: Current.account, country_code: order_params[:country_code])
    @order = resolve_idempotent_order(provider)
  rescue ActiveRecord::RecordNotUnique
    render_could_not_create_error('An order for this number is already in progress.')
  end

  # Demo only. A dummy India order stays in this modal step until a document
  # is uploaded, then the poll continues and the number can become active.
  def requirements
    document = params[:document]
    unless @order.status == 'requirements_pending' && NumberProvisioning::DummyExotel.enabled?
      return render_could_not_create_error('Documents are not required for this number.')
    end
    return render_could_not_create_error('Choose a document to upload.') if document.blank?

    @order.requirement_document.attach(document)
    NumberProvisioning::DummyExotel.mark_documents_submitted(@order.provider_order_id)
    ::NumberProvisioning::PollOrderStatusJob.perform_now(@order.id)
    @order.reload
  end

  def voice_agent
    ::NumberProvisioning::VoiceAgentAttachService.new(order: @order).perform
    @order.reload
  end

  private

  def resolve_idempotent_order(provider)
    return render_could_not_create_error('An Idempotency-Key is required.') if idempotency_key.blank?
    return place_order(provider) if Redis::Alfred.set(idempotency_cache_key, IDEMPOTENCY_IN_PROGRESS, nx: true, ex: IDEMPOTENCY_TTL)

    existing = Redis::Alfred.get(idempotency_cache_key)
    return render_order_in_progress if existing == IDEMPOTENCY_IN_PROGRESS

    parsed = parse_idempotency(existing)
    return render_order_in_progress if parsed.nil?
    if parsed['phone_number'] != order_params[:phone_number]
      return render_could_not_create_error('This Idempotency-Key was already used for a different phone number.')
    end

    order = Current.account.number_provisioning_orders.find_by(id: parsed['order_id'])
    return order if order && order.status != 'failed'
    return render_order_in_progress unless Redis::Alfred.set(idempotency_cache_key, IDEMPOTENCY_IN_PROGRESS, nx: true, ex: IDEMPOTENCY_TTL)

    place_order(provider)
  end

  def place_order(provider)
    quote = wholesale_quote(order_params[:country_code], order_params[:phone_number])
    return render_cost_unknown if quote.nil?

    @order = Current.account.number_provisioning_orders.create!(
      country_code: order_params[:country_code].to_s.upcase,
      phone_number: order_params[:phone_number],
      provider_type: provider.class::PROVIDER_TYPE,
      provider_cost_cents: quote[:provider_cost_cents],
      currency: quote[:currency],
      status: 'order_placed'
    )
    store_idempotency_key(@order)
    submit_to_provider(provider, @order)
    mark_dummy_requirements_pending(@order)
    enqueue_poll(@order)
    @order
  rescue Net::OpenTimeout, Net::ReadTimeout
    @order&.reload
    if @order&.provider_order_id.present?
      enqueue_poll(@order)
    elsif @order
      @order.update!(status: 'failed', failure_code: 'timeout')
    end
    raise
  end

  def submit_to_provider(provider, order)
    response = provider.order(phone_number: order.phone_number)
    order.update!(provider_order_id: provider_order_id_from(response))
    Rails.logger.info(
      "[NumberProvisioning] order placed account_id=#{Current.account.id} provider_type=#{order.provider_type} " \
      "order_id=#{order.id} provider_order_id=#{order.provider_order_id}"
    )
  rescue ::NumberProvisioning::Provider::RequestError => e
    code = request_failure_code(e)
    order.update!(status: 'failed', failure_code: code)
    Rails.logger.info(
      "[NumberProvisioning] order failed account_id=#{Current.account.id} provider_type=#{order.provider_type} " \
      "order_id=#{order.id} code=#{code} status=#{e.status} body=#{e.body}"
    )
    raise
  end

  def enqueue_poll(order)
    ::NumberProvisioning::PollOrderStatusJob.perform_later(order.id)
  end

  def mark_dummy_requirements_pending(order)
    return unless NumberProvisioning::DummyExotel.enabled?
    return unless order.provider_order_id.to_s.start_with?(NumberProvisioning::DummyExotel::PREFIX)

    order.update!(status: 'requirements_pending')
  end

  def set_order
    @order = Current.account.number_provisioning_orders.find(params[:id])
  end

  def render_order_in_progress
    render_could_not_create_error('An order for this number is already being processed. Please try again in a moment.')
  end

  def render_cost_unknown
    render_could_not_create_error(::NumberProvisioning::Order.failure_message_for('cost_unknown'))
  end

  def store_idempotency_key(order)
    Redis::Alfred.set(
      idempotency_cache_key,
      { order_id: order.id, phone_number: order.phone_number }.to_json,
      ex: IDEMPOTENCY_TTL
    )
  end

  def parse_idempotency(raw)
    JSON.parse(raw)
  rescue JSON::ParserError
    nil
  end

  def idempotency_key
    request.headers['Idempotency-Key']
  end

  def idempotency_cache_key
    "number_provisioning:idempotency:#{Current.account.id}:#{idempotency_key}"
  end

  def quote_cache_key(country_code, phone_number)
    "number_provisioning:quote:v2:#{country_code.to_s.upcase}:#{phone_number}"
  end

  def cache_quotes(country_code, rows)
    Array(rows).each do |row|
      data = row.respond_to?(:symbolize_keys) ? row.symbolize_keys : row
      next if data[:phone_number].blank?

      Redis::Alfred.setex(
        quote_cache_key(country_code, data[:phone_number]),
        { monthly_price_cents: data[:monthly_price_cents], currency: data[:currency] }.to_json,
        SEARCH_CACHE_TTL
      )
    end
  end

  def wholesale_quote(country_code, phone_number)
    raw = Redis::Alfred.get(quote_cache_key(country_code, phone_number))
    return nil if raw.blank?

    parsed = JSON.parse(raw)
    cents = parsed['monthly_price_cents']
    return nil if cents.blank?

    cents = cents.to_i
    return nil unless cents.positive?

    { provider_cost_cents: cents, currency: parsed['currency'].to_s.upcase }
  rescue JSON::ParserError
    nil
  end

  def with_customer_margin(rows, provider_type)
    percent = BigDecimal(NumberProvisioning::ProviderConfig.margin_percent_for(provider_type).to_s)
    Array(rows).map do |row|
      data = row.respond_to?(:symbolize_keys) ? row.symbolize_keys : row
      cents = data[:monthly_price_cents]
      priced = if cents.nil?
                 nil
               else
                 cents.to_i + (BigDecimal(cents.to_i) * percent / 100).round.to_i
               end
      data.merge(monthly_price_cents: priced)
    end
  end

  def request_failure_code(error)
    body = error.body.to_s
    return 'insufficient_balance' if error.status.to_i == 402 || body.match?(/insufficient balance|34005/i)

    'unknown'
  end

  def check_authorization
    authorize(@order || ::NumberProvisioning::Order)
  end

  def render_voice_agent_error(exception)
    render_could_not_create_error(exception.message)
  end

  def render_provider_disabled(exception)
    log_handled_error(exception)
    render_could_not_create_error(::NumberProvisioning::Order.failure_message_for('provider_disabled'))
  end

  def render_country_not_allowed(exception)
    log_handled_error(exception)
    render_could_not_create_error('Phone numbers are only available for the United States and India.')
  end

  def render_provider_request_error(exception)
    log_handled_error(exception)
    render_could_not_create_error(@order&.failure_message || ::NumberProvisioning::Order.failure_message_for('unknown'))
  end

  def render_provider_timeout(exception)
    log_handled_error(exception)
    render_could_not_create_error(::NumberProvisioning::Order.failure_message_for('timeout'))
  end

  def provider_order_id_from(response)
    response['id']
  end

  def order_params
    params.require(:order).permit(:country_code, :phone_number)
  end

end
