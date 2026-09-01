class Api::V1::Accounts::Reputation::IntegrationRequestsController < Api::V1::Accounts::Reputation::BaseController
  # POST /api/v1/accounts/:account_id/reputation/integration_requests
  def create
    request = current_account.reputation_integration_requests.create!(integration_request_params)
    render json: request, status: :created
  end

  private

  def integration_request_params
    params.require(:integration_request).permit(:platform, :email, :notes)
  end
end
