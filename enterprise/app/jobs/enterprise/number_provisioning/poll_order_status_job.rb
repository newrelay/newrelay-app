module Enterprise::NumberProvisioning::PollOrderStatusJob
  private

  def bill_order(order)
    Enterprise::NumberProvisioning::OrderBillingService.new(order: order).bill!
  rescue Enterprise::NumberProvisioning::OrderBillingService::Error => e
    order.update!(status: 'billing_failed', failure_code: e.code)
    Rails.logger.info("[NumberProvisioning] billing failed order_id=#{order.id} code=#{e.code}")
    record_charge_failure(order)
    release_unpaid_number(order)
  end

  def record_charge_failure(order)
    Enterprise::Billing::RecordBillingActivityService.new(
      account: order.account,
      action: 'number_provisioning_charge',
      message: order.failure_message || order.failure_code,
      status: 'failed',
      payment_provider: order.account.subscription&.payment_provider,
      metadata: { order_id: order.id, failure_code: order.failure_code }
    ).perform
  rescue StandardError => e
    Rails.logger.error("[NumberProvisioning] billing activity log failed order_id=#{order.id} error=#{e.class}")
  end
end
