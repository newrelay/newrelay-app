class Api::V1::Accounts::Reputation::AiInsightsController < Api::V1::Accounts::Reputation::BaseController
  # GET /api/v1/accounts/:account_id/reputation/ai_insights
  # GET /api/v1/accounts/:account_id/reputation/ai_insights?listing_id=X
  # Cached per account (or account+listing) per day — one LLM call, not one per page load.
  def show
    listing_id = permitted_listing_id
    data = Rails.cache.fetch(cache_key(listing_id), expires_in: 1.day, skip_nil: true) do
      Reputation::AiInsightsService.new(account: current_account, listing_id: listing_id,
                                        listing_ids: listing_id.blank? && !administrator? ? scoped_listing_ids : nil).generate
    end
    render json: data || {}
  end

  private

  def permitted_listing_id
    id = params[:listing_id].presence
    return if id.blank? && administrator?
    raise ActiveRecord::RecordNotFound if id.present? && scoped_listings.where(id: id).none?

    id
  end

  # v2: bumped when the response shape changes (added topics/keywords/suggestions)
  # so stale cached entries from the old shape don't linger for the rest of the day.
  def cache_key(listing_id)
    scope = listing_id.presence || (administrator? ? 'account' : "members/#{Current.user.id}")
    "reputation_ai_insights/v2/#{current_account.id}/#{scope}/#{Date.current}"
  end
end
