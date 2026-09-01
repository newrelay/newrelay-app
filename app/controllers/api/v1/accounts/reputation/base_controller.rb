class Api::V1::Accounts::Reputation::BaseController < Api::V1::Accounts::BaseController
  before_action :authorize_reputation_access!

  private

  def authorize_reputation_access!
    return if Current.account_user.permissions.intersect?(%w[administrator reputation_manage])

    raise Pundit::NotAuthorizedError
  end

  def administrator?
    Current.account_user.administrator?
  end

  def scoped_listings
    rel = current_account.reputation_listings
    return rel if administrator?

    rel.joins(:listing_members).where(reputation_listing_members: { user_id: Current.user.id })
  end

  def scoped_listing_ids
    @scoped_listing_ids ||= scoped_listings.distinct.pluck(:id)
  end

  def scoped_reviews
    rel = current_account.reputation_reviews
    return rel if administrator?

    rel.joins(:reputation_integration).where(reputation_integrations: { reputation_listing_id: scoped_listing_ids })
  end

  def scoped_integrations
    rel = current_account.reputation_integrations
    return rel if administrator?

    rel.where(reputation_listing_id: scoped_listing_ids)
  end

  def scoped_review_requests
    rel = current_account.reputation_review_requests
    return rel if administrator?

    rel.where(reputation_listing_id: scoped_listing_ids)
  end

  def scoped_video_testimonials
    rel = current_account.reputation_video_testimonials
    return rel if administrator?

    rel.where(reputation_listing_id: scoped_listing_ids)
  end

  def scoped_feedback
    rel = current_account.reputation_feedback_submissions
    return rel if administrator?

    rel.joins(:reputation_review_request)
       .where(reputation_review_requests: { reputation_listing_id: scoped_listing_ids })
  end

  # Members must land on a listing they own. Admin may omit (nil = account-wide leftover).
  def assignable_listing_id
    id = params[:listing_id].presence
    if id.present?
      raise ActiveRecord::RecordNotFound unless scoped_listings.exists?(id)

      return id
    end
    return if administrator?

    scoped_listing_ids.first
  end
end
