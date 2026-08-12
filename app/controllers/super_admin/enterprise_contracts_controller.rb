class SuperAdmin::EnterpriseContractsController < SuperAdmin::ApplicationController
  # Lets "Set Plan" links from the Enterprise Inquiries page pre-fill the account
  # and sensible contract defaults, e.g. /super_admin/enterprise_contracts/new?account_id=61
  def new_resource(incoming_params = {})
    attrs = {
      billing_interval: 'monthly',
      contract_start_date: Time.zone.today,
      contract_end_date: 1.year.from_now.to_date
    }.merge(incoming_params.to_h.symbolize_keys)
    attrs[:account_id] ||= params[:account_id] if params[:account_id].present?

    resource_class.new(attrs)
  end

  private

  # Admins configure a contract by clicking "Set plan"/"Edit plan" from the Enterprise
  # Inquiries list, then need to come straight back there to send the payment link -
  # Administrate's default redirect (to the contract's own show page) breaks that flow
  # and strands the admin one click away from where they actually need to be next.
  def after_resource_created_path(requested_resource)
    redirect_target_for(requested_resource)
  end

  def after_resource_updated_path(requested_resource)
    redirect_target_for(requested_resource)
  end

  def redirect_target_for(contract)
    return super_admin_enterprise_inquiries_path if contract.account.custom_attributes['enterprise_inquiry'].present?

    [namespace, contract]
  end

  def resource_params
    params = super
    if params[:negotiated_limit_overrides].is_a?(ActionController::Parameters) || params[:negotiated_limit_overrides].is_a?(Hash)
      # Convert valid string numbers to integers and remove blanks
      overrides = {}
      params[:negotiated_limit_overrides].each do |k, v|
        next if v.blank?

        overrides[k] = v.to_i if v.to_s.match?(/\A\d+\z/)
      end
      params[:negotiated_limit_overrides] = overrides
    elsif params[:negotiated_limit_overrides].blank?
      params[:negotiated_limit_overrides] = {}
    end

    params[:negotiated_features].reject!(&:blank?) if params[:negotiated_features].is_a?(Array)

    params
  end
end
