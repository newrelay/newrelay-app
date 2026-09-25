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
  end

  private

  # TODO: the real per-provider status field/values are unconfirmed -- same "no captured
  # response" gap the design doc flags for price normalization (see §3a) applies here.
  # Verify against a real Telnyx/Exotel response before relying on this in production.
  def handle_status(order, raw_status, attempt)
    case raw_status.is_a?(Hash) ? raw_status['status'] : nil
    when 'active'
      mark_active(order)
    when 'failed'
      order.update!(status: 'failed', provisioning_error: raw_status.to_s)
    else
      requeue_or_fail(order, attempt, nil)
    end
  end

  def mark_active(order)
    # TODO: create Channel::TelnyxSms/Channel::ExotelSms + Inbox here once those channel
    # models exist, then set order.inbox_id (see design doc §2 model note). Building the
    # channel models is explicitly out of this task's critical path.
    order.update!(status: 'active')
    bill_order(order)
  end

  # No-op in OSS -- Enterprise overrides this to compute margin/billing_reference via
  # Enterprise::NumberProvisioning::OrderBillingService (see design doc §1a consequence 2).
  def bill_order(order); end

  def requeue_or_fail(order, attempt, error)
    if attempt >= MAX_ATTEMPTS
      order.update!(status: 'failed', provisioning_error: error || 'polling attempts exhausted')
    else
      self.class.set(wait: RESCHEDULE_WAIT).perform_later(order.id, attempt + 1)
    end
  end
end

NumberProvisioning::PollOrderStatusJob.prepend_mod_with('NumberProvisioning::PollOrderStatusJob')
