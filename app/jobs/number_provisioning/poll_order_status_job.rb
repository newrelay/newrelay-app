class NumberProvisioning::PollOrderStatusJob < ApplicationJob
  queue_as :default

  NETWORK_ERRORS = [Net::ReadTimeout, Net::OpenTimeout, HTTParty::Error, SocketError,
                    Errno::ECONNREFUSED, OpenSSL::SSL::SSLError, Timeout::Error].freeze

  MAX_ATTEMPTS = 30
  RESCHEDULE_WAIT = 1.minute
  TERMINAL_STATUSES = %w[active failed cancelled].freeze

  def perform(order_id, attempt = 0)
    order = NumberProvisioning::Order.find_by(id: order_id)
    return if order.blank? || order.status.in?(TERMINAL_STATUSES)

    provider = NumberProvisioning.for(account: order.account, country_code: order.country_code)
    raw_status = provider.status(provider_order_id: order.provider_order_id)
    handle_status(order, raw_status, attempt)
  rescue *NETWORK_ERRORS => e
    requeue_or_fail(order, attempt, e.message)
  rescue ::NumberProvisioning::Provider::ProviderDisabledError => e
    # Outside-voice review finding: without this, a flag flipping off mid-flight (or
    # the unseeded-config bug this same review caught) escapes perform() unrescued --
    # not in NETWORK_ERRORS, so Sidekiq treats it as a hard job failure and the order
    # is left stuck with no clean 'failed' state instead of a real, visible outcome.
    order.update!(status: 'failed', provisioning_error: e.message)
    Rails.logger.info(
      "[NumberProvisioning] order failed account_id=#{order.account_id} provider_type=#{order.provider_type} " \
      "order_id=#{order.id} error=#{e.message}"
    )
  end

  private

  # TODO: the real per-provider status field/values are unconfirmed -- same "no captured
  # response" gap the design doc flags for price normalization (see §3a) applies here.
  # Verify against a real Telnyx/Exotel response before relying on this in production.
  def handle_status(order, raw_status, attempt)
    status_value = raw_status.is_a?(Hash) ? raw_status['status'] : nil
    case status_value
    when 'active'
      mark_active(order)
    when 'failed'
      order.update!(status: 'failed', provisioning_error: raw_status.to_s)
    when nil
      # Malformed/unexpected response shape -- keep the requeue/max-attempts posture,
      # this is "actually broken", not a provider telling us something.
      requeue_or_fail(order, attempt, nil)
    else
      # CEO review finding 1A: a recognized-but-not-active/failed status used to fall
      # through to requeue_or_fail, which silently retried 30x over 30 minutes and then
      # mislabeled a real "needs regulatory requirements" response as 'failed'. The
      # submission flow itself still isn't built (see design doc), but at minimum this
      # stops mislabeling it -- the order lands in requirements_pending, not a lie.
      Rails.logger.info(
        "[NumberProvisioning] order requires attention account_id=#{order.account_id} " \
        "provider_type=#{order.provider_type} order_id=#{order.id} raw_status=#{status_value}"
      )
      order.update!(status: 'requirements_pending')
    end
  end

  def mark_active(order)
    # TODO: create Channel::TelnyxSms/Channel::ExotelSms + Inbox here once those channel
    # models exist, then set order.inbox_id (see design doc §2 model note). Building the
    # channel models is explicitly out of this task's critical path.
    order.update!(status: 'active')
    Rails.logger.info(
      "[NumberProvisioning] order active account_id=#{order.account_id} provider_type=#{order.provider_type} " \
      "order_id=#{order.id} provider_order_id=#{order.provider_order_id}"
    )
    bill_order(order)
  end

  # No-op in OSS -- Enterprise overrides this to compute margin/billing_reference via
  # Enterprise::NumberProvisioning::OrderBillingService (see design doc §1a consequence 2).
  def bill_order(order); end

  def requeue_or_fail(order, attempt, error)
    if attempt >= MAX_ATTEMPTS
      order.update!(status: 'failed', provisioning_error: error || 'polling attempts exhausted')
      Rails.logger.info(
        "[NumberProvisioning] order failed account_id=#{order.account_id} provider_type=#{order.provider_type} " \
        "order_id=#{order.id} error=#{order.provisioning_error}"
      )
    else
      self.class.set(wait: RESCHEDULE_WAIT).perform_later(order.id, attempt + 1)
    end
  end
end

NumberProvisioning::PollOrderStatusJob.prepend_mod_with('NumberProvisioning::PollOrderStatusJob')
