class Api::V1::Accounts::Reputation::TemplatesController < Api::V1::Accounts::BaseController
  before_action :template, only: [:show, :update, :destroy]

  # GET /api/v1/accounts/:account_id/reputation/templates
  def index
    render json: current_account.reputation_templates.order(created_at: :desc)
  end

  # POST /api/v1/accounts/:account_id/reputation/templates
  def create
    template = current_account.reputation_templates.create!(template_params)
    render json: template, status: :created
  end

  # PATCH /api/v1/accounts/:account_id/reputation/templates/:id
  def update
    template.update!(template_params)
    render json: template
  end

  # DELETE /api/v1/accounts/:account_id/reputation/templates/:id
  def destroy
    template.destroy!
    head :no_content
  end

  private

  def template
    @template ||= current_account.reputation_templates.find(params[:id])
  end

  def template_params
    params.require(:template).permit(:name, :channel, :body, :subject, :active, :template_type)
  end
end
