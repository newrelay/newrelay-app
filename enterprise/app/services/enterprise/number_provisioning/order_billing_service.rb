# Computes margin_cents and writes billing_reference on a NumberProvisioning::Order once
# it reaches 'active'. Idempotency pattern copied from
# Enterprise::Billing::TopupFulfillmentService (account.with_lock + an
# already-billed guard), per design doc §1a consequence 2.
#
# TODO: the actual charge/billing-record creation is deliberately not implemented here.
# Enterprise::Billing::RecordPaymentTransactionService (account:, invoice:, status:) expects
# a Stripe `invoice` object, which doesn't fit a number-provisioning order -- the real call
# needs to be designed against whatever billing record type this feature settles on (see
# design doc §1a consequence 3 and §2's margin_cents/billing_reference notes), not guessed.
class Enterprise::NumberProvisioning::OrderBillingService
  pattr_initialize [:order!]

  def bill!
    order.account.with_lock do
      next if already_billed?

      order.update!(margin_cents: compute_margin_cents, billing_reference: generate_billing_reference)
      # TODO: create the real charge/billing record here once record_payment_transaction_service's
      # expected inputs for a non-Stripe-invoice charge are known.
    end
  end

  private

  def already_billed?
    order.billing_reference.present?
  end

  # TODO: margin/markup rate is unresolved (see design doc §1a consequence 3 -- meaning
  # of margin_cents pending confirmation against Enterprise::Billing::CloudPlans' pricing
  # config, not traced in this pass). Stubbed at zero rather than guessed.
  def compute_margin_cents
    0
  end

  def generate_billing_reference
    "numprov_#{order.id}_#{SecureRandom.hex(6)}"
  end
end
