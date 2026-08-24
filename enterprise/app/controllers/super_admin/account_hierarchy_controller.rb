class SuperAdmin::AccountHierarchyController < SuperAdmin::ApplicationController
  def show
    @resellers = Account.where(is_reseller: true).includes(:subscription, children: :subscription).order(:name)
    tree_ids = @resellers.flat_map { |reseller| [reseller.id, *reseller.children.map(&:id)] }
    @parent_count = @resellers.size
    @child_count = @resellers.sum { |reseller| reseller.children.size }
    @agent_count = AccountUser.where(account_id: tree_ids).count
    @user_counts = AccountUser.where(account_id: tree_ids).group(:account_id).count
    @conversation_counts = Conversation.where(account_id: tree_ids).group(:account_id).count
    total_accounts = Account.count
    @coverage_percent = total_accounts.zero? ? 0 : ((tree_ids.uniq.size.to_f / total_accounts) * 100).round
  end

  def account
    @account = Account.includes(:subscription, :parent).find(params[:account_id])
    @billing_activity = @account.billing_activity_logs.includes(:user).recent_first.limit(100)
    @plan_name = @account.subscription&.plan_name.presence || @account.custom_attributes['plan_name']
  end
end
