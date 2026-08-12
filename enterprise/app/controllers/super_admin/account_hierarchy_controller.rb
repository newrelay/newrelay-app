class SuperAdmin::AccountHierarchyController < SuperAdmin::ApplicationController
  def show
    @resellers = Account.where(is_reseller: true).includes(:subscription, children: :subscription).order(:name)
  end

  def account
    @account = Account.includes(:subscription, :parent).find(params[:account_id])
    @billing_activity = @account.billing_activity_logs.includes(:user).recent_first.limit(100)
    @plan_name = @account.subscription&.plan_name.presence || @account.custom_attributes['plan_name']
  end
end
