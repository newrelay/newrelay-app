class SuperAdmin::NumberProvisioningController < SuperAdmin::ApplicationController
  def show
    @providers = NumberProvisioning::ProviderConfig.admin_view
    recent = NumberProvisioning::Order.where(created_at: 7.days.ago..)
    @status_counts = recent.group(:status).count
    @failure_code_counts = recent.where.not(failure_code: nil).group(:failure_code).count
  end

  def update
    NumberProvisioning::ProviderConfig.save!(params[:providers])
    NumberProvisioning::ProviderConfig.clear_cache
    redirect_to super_admin_number_provisioning_path, notice: 'Number provisioning settings updated.' # rubocop:disable Rails/I18nLocaleTexts
  rescue NumberProvisioning::ProviderConfig::ValidationError => e
    redirect_to super_admin_number_provisioning_path, alert: e.message
  end
end
