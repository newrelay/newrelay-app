json.subscribed_features @account.subscribed_features

plan_name = @account.custom_attributes['plan_name'].to_s.downcase

# The real Subscription record (kept in sync by Stripe webhooks / bypass_plan /
# EnterpriseContract#activate_enterprise_plan) always reflects the account's actual
# payment state, so prefer it over the negotiated contract dates. This matters for
# Enterprise accounts: a customer who pays via an ad-hoc payment link before a
# contract is formalized, or whose Enterprise subscription later goes past_due,
# would otherwise be reported as having no subscription at all.
if @account.subscription.present?
  json.subscription do
    sub = @account.subscription
    json.status sub.status
    json.plan_name sub.plan_name
    json.active sub.active?
    json.grace_period_ends_at sub.grace_period_ends_at
    json.payment_provider sub.payment_provider
    json.current_period_start sub.current_period_start
    json.current_period_end sub.current_period_end
    json.cancel_at_period_end sub.cancel_at_period_end
    json.subscribed_quantity sub.subscribed_quantity
  end
elsif plan_name == 'enterprise'
  contract = EnterpriseContract.find_by(account_id: @account.id)
  if contract
    is_active = contract.contract_end_date >= Time.zone.today
    json.subscription do
      json.status is_active ? 'active' : 'expired'
      json.plan_name 'Enterprise'
      json.active is_active
    end
  else
    json.subscription nil
  end
else
  json.subscription nil
end
