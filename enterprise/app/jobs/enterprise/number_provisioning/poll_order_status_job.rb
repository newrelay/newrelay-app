module Enterprise::NumberProvisioning::PollOrderStatusJob
  private

  def bill_order(order)
    Enterprise::NumberProvisioning::OrderBillingService.new(order: order).bill!
  end
end
