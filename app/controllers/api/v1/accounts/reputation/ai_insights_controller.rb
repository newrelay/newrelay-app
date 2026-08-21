class Api::V1::Accounts::Reputation::AiInsightsController < Api::V1::Accounts::BaseController
  # GET /api/v1/accounts/:account_id/reputation/ai_insights
  # Cached per account per day — one LLM call, not one per page load.
  def show
    data = Rails.cache.fetch(cache_key, expires_in: 1.day, skip_nil: true) do
      Reputation::AiInsightsService.new(account: current_account).generate
    end
    render json: data || {}
  end

  private

  def cache_key
    "reputation_ai_insights/#{current_account.id}/#{Date.current}"
  end
end
