class Api::V1::Accounts::DealsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :ensure_default_pipeline
  before_action :fetch_deal, only: [:show, :update, :destroy]

  def index
    deals = Current.account.deals.includes(:pipeline, :pipeline_stage, :contact, :owner)
    deals = deals.where(pipeline_id: params[:pipeline_id]) if params[:pipeline_id].present?
    deals = deals.where(pipeline_stage_id: params[:pipeline_stage_id]) if params[:pipeline_stage_id].present?
    @deals = deals.order(updated_at: :desc)
  end

  def show; end

  def create
    @deal = Current.account.deals.create!(deal_params)
  end

  def update
    @deal.update!(deal_params)
  end

  def destroy
    @deal.destroy!
    head :ok
  end

  private

  def ensure_default_pipeline
    Pipelines::EnsureDefaultService.new(account: Current.account).perform
  end

  def fetch_deal
    @deal = Current.account.deals.find(params[:id])
  end

  def deal_params
    params.require(:deal).permit(
      :name, :amount_cents, :currency, :close_on, :priority, :probability,
      :pipeline_id, :pipeline_stage_id, :contact_id, :company_id, :owner_id
    )
  end
end
