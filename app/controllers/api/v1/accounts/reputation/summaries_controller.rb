class Api::V1::Accounts::Reputation::SummariesController < Api::V1::Accounts::BaseController
  # GET /api/v1/accounts/:account_id/reputation/summary
  def show
    render json: Reputation::SummaryBuilder.new(current_account).as_json
  end
end
