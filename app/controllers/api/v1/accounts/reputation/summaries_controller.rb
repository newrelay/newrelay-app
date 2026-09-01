class Api::V1::Accounts::Reputation::SummariesController < Api::V1::Accounts::Reputation::BaseController
  # GET /api/v1/accounts/:account_id/reputation/summary
  def show
    ids = administrator? ? nil : scoped_listing_ids
    render json: Reputation::SummaryBuilder.new(current_account, listing_ids: ids).as_json
  end
end
