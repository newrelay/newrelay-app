class NumberProvisioning::PollOrderStatusJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 0 if respond_to?(:sidekiq_options)

  NETWORK_ERRORS = [Net::ReadTimeout, Net::OpenTimeout, HTTParty::Error, SocketError,
                    Errno::ECONNREFUSED, OpenSSL::SSL::SSLError, Timeout::Error].freeze

  MAX_ATTEMPTS = 30
  RESCHEDULE_WAIT = 1.minute
  POLL_LOCK_TTL = 55

  def perform(order_id, attempt = 0)
    lock_key = "number_provisioning:poll_lock:#{order_id}"
    lock_acquired = Redis::Alfred.set(lock_key, '1', nx: true, ex: POLL_LOCK_TTL)
    return unless lock_acquired

    order = NumberProvisioning::Order.find_by(id: order_id)
    return if order.blank? || order.finished?

    if order.status == 'inbox_pending'
      attach_inbox!(order)
      return
    end

    provider = NumberProvisioning.for(account: order.account, country_code: order.country_code)
    raw_status = provider.status(provider_order_id: order.provider_order_id)
    handle_status(order, raw_status, attempt)
  rescue *NETWORK_ERRORS, ::NumberProvisioning::Provider::RequestError => e
    requeue_or_fail(order, attempt, e.message) if order
  rescue ::NumberProvisioning::Provider::ProviderDisabledError => e
    mark_failed(order, 'provider_disabled', e.message) if order
  rescue StandardError => e
    Rails.logger.error("[NumberProvisioning] poll failed order_id=#{order_id} error=#{e.class}: #{e.message}")
    mark_failed(order, 'unknown', e.message) if order
  ensure
    Redis::Alfred.delete(lock_key) if lock_acquired
  end

  private

  def handle_status(order, raw_status, attempt)
    status_value = raw_status.is_a?(Hash) ? raw_status['status'] : nil
    case status_value
    when 'active'
      handle_provider_ready(order, attempt)
    when 'failed'
      mark_failed(order, 'unknown')
    when *NumberProvisioning::Order::REQUIREMENT_STATUSES
      order.update!(status: status_value)
    else
      requeue_or_fail(order, attempt, nil)
    end
  end

  def handle_provider_ready(order, attempt)
    bill_order(order)
    order.reload
    return if order.finished?
    return requeue_or_fail(order, attempt, nil) if order.billing_reference.blank?

    attach_inbox!(order)
  end

  def attach_inbox!(order)
    result = NumberProvisioning::CreateInboxService.new(order: order).perform!
    return if result == :active || result == :conflict

    self.class.set(wait: RESCHEDULE_WAIT).perform_later(order.id, 0)
  end

  def bill_order(order); end

  def release_unpaid_number(order)
    return if order.billing_reference.present?

    provider = NumberProvisioning.for(account: order.account, country_code: order.country_code)
    return unless provider.release(phone_number: order.phone_number, provider_order_id: order.provider_order_id)

    order.update!(status: 'failed')
  rescue StandardError => e
    Rails.logger.info("[NumberProvisioning] release skipped order_id=#{order.id} error=#{e.class}")
  end

  def mark_failed(order, code, detail = nil)
    order.update!(status: 'failed', failure_code: code)
    Rails.logger.info(
      "[NumberProvisioning] order failed account_id=#{order.account_id} order_id=#{order.id} " \
      "code=#{code} detail=#{detail}"
    )
  end

  def requeue_or_fail(order, attempt, error)
    if attempt >= MAX_ATTEMPTS
      mark_failed(order, 'unknown', error || 'polling attempts exhausted')
    else
      self.class.set(wait: RESCHEDULE_WAIT).perform_later(order.id, attempt + 1)
    end
  end
end

NumberProvisioning::PollOrderStatusJob.prepend_mod_with('NumberProvisioning::PollOrderStatusJob')
