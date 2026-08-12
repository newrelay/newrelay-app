class Enterprise::Billing::SyncPaymentTransactionsService
  pattr_initialize [:account!]

  # Syncs invoices for one account: by its Stripe customer id, then by invoice/subscription
  # metadata account_id (covers cases where the local stripe_customer_id is missing/stale).
  def perform
    imported = sync_by_customer
    imported += sync_by_account_metadata if account.payment_transactions.none? || imported.zero?
    imported
  end

  def self.backfill_all!(limit: 100)
    imported = 0
    Stripe::Invoice.list(limit: limit).auto_paging_each do |invoice|
      matched = resolve_account(invoice)
      next if matched.blank?

      status = status_for(invoice)
      next if status.blank?

      Enterprise::Billing::RecordPaymentTransactionService.new(
        account: matched,
        invoice: invoice,
        status: status
      ).perform
      ensure_customer_id!(matched, invoice.customer)
      imported += 1
    end
    imported
  rescue Stripe::StripeError => e
    Rails.logger.error("[SyncPaymentTransactions.backfill_all!] #{e.class}: #{e.message}")
    0
  end

  def self.resolve_account(invoice)
    customer_id = invoice.customer
    matched = Account.where("custom_attributes->>'stripe_customer_id' = ?", customer_id).first
    matched ||= Subscription.find_by(stripe_customer_id: customer_id)&.account

    account_id = invoice_account_id(invoice)
    matched ||= Account.find_by(id: account_id) if account_id.present?
    matched
  end

  def self.invoice_account_id(invoice)
    invoice.metadata['account_id'].presence ||
      invoice.parent&.subscription_details&.metadata&.[]('account_id').presence ||
      subscription_metadata_account_id(invoice)
  end

  def self.subscription_metadata_account_id(invoice)
    sub_id = invoice['subscription'].presence ||
             invoice.parent&.subscription_details&.subscription
    return if sub_id.blank?

    Stripe::Subscription.retrieve(sub_id).metadata['account_id']
  rescue Stripe::StripeError
    nil
  end

  def self.status_for(invoice)
    case invoice.status
    when 'paid' then 'succeeded'
    when 'open', 'uncollectible'
      invoice.attempted ? 'failed' : nil
    end
  end

  def self.ensure_customer_id!(account, customer_id)
    return if customer_id.blank?
    return if account.custom_attributes['stripe_customer_id'] == customer_id

    account.update_column(
      :custom_attributes,
      account.custom_attributes.merge('stripe_customer_id' => customer_id)
    )
  end

  private

  def sync_by_customer
    customer_id = stripe_customer_id
    return 0 if customer_id.blank?

    imported = 0
    Stripe::Invoice.list(customer: customer_id, limit: 100).auto_paging_each do |invoice|
      imported += 1 if import_invoice(invoice)
    end
    imported
  rescue Stripe::StripeError => e
    Rails.logger.error("[SyncPaymentTransactions] account=#{account.id} customer sync #{e.class}: #{e.message}")
    0
  end

  def sync_by_account_metadata
    imported = 0
    Stripe::Invoice.list(limit: 100).auto_paging_each do |invoice|
      next unless self.class.invoice_account_id(invoice).to_s == account.id.to_s

      next unless import_invoice(invoice)

      self.class.ensure_customer_id!(account, invoice.customer)
      imported += 1
    end
    imported
  rescue Stripe::StripeError => e
    Rails.logger.error("[SyncPaymentTransactions] account=#{account.id} metadata sync #{e.class}: #{e.message}")
    0
  end

  def stripe_customer_id
    account.custom_attributes['stripe_customer_id'].presence ||
      account.subscription&.stripe_customer_id.presence
  end

  def import_invoice(invoice)
    status = self.class.status_for(invoice)
    return false if status.blank?

    Enterprise::Billing::RecordPaymentTransactionService.new(
      account: account,
      invoice: invoice,
      status: status
    ).perform
    true
  end
end
