# Cancels the account's active Razorpay subscription at cycle end (default) so
# access continues until period end, matching Stripe cancel_at_period_end behavior.
class Enterprise::Billing::RazorpayCancelSubscriptionService
  class Error < StandardError; end

  pattr_initialize [:account!]

  def perform(cancel_at_cycle_end: true)
    subscription = account.subscription
    raise Error, 'No Razorpay subscription found' if subscription.blank? || subscription.payment_provider != 'razorpay'
    raise Error, 'No Razorpay subscription id on file' if subscription.razorpay_subscription_id.blank?
    raise Error, 'Subscription is already canceled' if subscription.status == 'canceled'

    result = Enterprise::Billing::RazorpayClient.new.cancel_subscription(
      subscription.razorpay_subscription_id,
      cancel_at_cycle_end: cancel_at_cycle_end
    )

    subscription.update!(
      status: result['status'].presence || subscription.status,
      cancel_at_period_end: cancel_at_cycle_end
    )

    { status: subscription.status, razorpay_subscription_id: subscription.razorpay_subscription_id }
  end
end
