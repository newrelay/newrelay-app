class Enterprise::Billing::RecordPaymentTransactionService
  pattr_initialize [:account!, :invoice!, :status!]

  def perform
    txn = PaymentTransaction.find_or_initialize_by(stripe_invoice_id: invoice.id)
    txn.update!(
      account: account,
      stripe_customer_id: invoice.customer,
      stripe_charge_id: invoice_charge_id,
      amount: invoice_amount,
      currency: invoice.currency,
      status: status,
      description: invoice_description,
      billing_reason: invoice.billing_reason,
      hosted_invoice_url: invoice.hosted_invoice_url,
      invoice_pdf: invoice.invoice_pdf,
      paid_at: status == 'succeeded' ? invoice_paid_at : nil
    )
    txn
  end

  private

  def invoice_amount
    cents = status == 'succeeded' ? invoice.amount_paid : invoice.amount_due
    cents.to_f / 100
  end

  def invoice_paid_at
    timestamp = invoice.status_transitions&.paid_at || invoice.created
    Time.zone.at(timestamp)
  end

  def invoice_charge_id
    invoice.charge.presence || invoice.payments&.data&.first&.payment&.charge
  rescue StandardError
    nil
  end

  def invoice_description
    invoice.description.presence ||
      invoice.lines&.data&.first&.description.presence ||
      invoice.billing_reason&.titleize
  end
end
