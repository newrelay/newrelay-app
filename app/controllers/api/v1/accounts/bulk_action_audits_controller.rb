class Api::V1::Accounts::BulkActionAuditsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_bulk_action_audits, only: [:index]
  before_action :fetch_bulk_action_audit, only: [:show]

  def index
    render json: @bulk_action_audits
  end

  def show
    render json: @bulk_action_audit
  end

  private

  def fetch_bulk_action_audits
    @bulk_action_audits = Current.account.bulk_action_audits
    @bulk_action_audits = @bulk_action_audits.where(status: permitted_params[:status]) if permitted_params[:status].present?
    return if permitted_params[:operation_type].blank?

    @bulk_action_audits = @bulk_action_audits.where(operation_type: permitted_params[:operation_type])
  end

  def fetch_bulk_action_audit
    @bulk_action_audit = Current.account.bulk_action_audits.find(permitted_params[:id])
  end

  def permitted_params
    params.permit(:id, :status, :operation_type)
  end
end
