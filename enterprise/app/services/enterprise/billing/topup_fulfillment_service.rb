class Enterprise::Billing::TopupFulfillmentService
  pattr_initialize [:account!]

  def fulfill(credits:, amount_cents:, currency:, stripe_session_id: nil, external_payment_id: nil)
    payment_ref = external_payment_id.presence || stripe_session_id

    account.with_lock do
      # Idempotent: if this payment was already fulfilled (providers can retry
      # webhooks), don't double-credit the account.
      return if already_fulfilled?(payment_ref)

      create_stripe_credit_grant(credits, amount_cents, currency) if stripe_session_id.present?
      update_account_credits(credits)
      mark_fulfilled!(payment_ref) if payment_ref.present?
    end

    Rails.logger.info("Topup fulfilled for account #{account.id}: #{credits} credits, #{amount_cents} cents")
  end

  private

  def already_fulfilled?(stripe_session_id)
    return false if stripe_session_id.blank?

    fulfilled = Array(account.custom_attributes['fulfilled_topup_sessions'])
    fulfilled.include?(stripe_session_id)
  end

  def mark_fulfilled!(stripe_session_id)
    fulfilled = Array(account.custom_attributes['fulfilled_topup_sessions'])
    fulfilled = (fulfilled + [stripe_session_id]).uniq.last(50)
    account.update!(
      custom_attributes: account.custom_attributes.merge('fulfilled_topup_sessions' => fulfilled)
    )
  end

  # Stripe Credit Grants are optional bookkeeping - Captain usage in this app is
  # enforced via account.limits['captain_responses']. Don't fail the top-up if
  # CreditGrant isn't enabled on the Stripe account.
  def create_stripe_credit_grant(credits, amount_cents, currency)
    return if stripe_customer_id.blank?

    Stripe::Billing::CreditGrant.create(
      customer: stripe_customer_id,
      name: "Topup: #{credits} credits",
      amount: {
        type: 'monetary',
        monetary: { currency: currency, value: amount_cents }
      },
      applicability_config: {
        scope: { price_type: 'metered' }
      },
      category: 'paid',
      expires_at: 6.months.from_now.to_i,
      metadata: {
        account_id: account.id.to_s,
        source: 'topup',
        credits: credits.to_s
      }
    )
  rescue Stripe::StripeError => e
    Rails.logger.warn("[TopupFulfillment] CreditGrant skipped for account #{account.id}: #{e.message}")
  end

  def update_account_credits(credits)
    current_limits = account.limits || {}
    current_total = current_limits['captain_responses'].to_i
    new_total = current_total + credits

    account.update!(
      limits: current_limits.merge(
        'captain_responses' => new_total
      )
    )
  end

  def stripe_customer_id
    account.custom_attributes['stripe_customer_id']
  end
end
