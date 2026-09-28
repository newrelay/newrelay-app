class SuperAdmin::NumberProvisioningController < SuperAdmin::ApplicationController
  def show
    @providers = NumberProvisioning::ProviderConfig.admin_view
  end

  def update
    NumberProvisioning::ProviderConfig.save!(params[:providers])
    redirect_to super_admin_number_provisioning_path, notice: 'Number provisioning settings updated.'
  rescue NumberProvisioning::ProviderConfig::ValidationError => e
    redirect_to super_admin_number_provisioning_path, alert: e.message
  end
end
