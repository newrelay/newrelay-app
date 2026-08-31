class Api::V1::Accounts::Reputation::ListingsController < Api::V1::Accounts::BaseController
  # GET /api/v1/accounts/:account_id/reputation/listings
  def index
    enqueue_missing_images
    render json: current_account.reputation_listings.order(primary: :desc, created_at: :asc)
  end

  # GET /api/v1/accounts/:account_id/reputation/listings/:id
  def show
    render json: current_account.reputation_listings.find(params[:id])
  end

  # GET /api/v1/accounts/:account_id/reputation/listings/:id/activities
  def activities
    listing = current_account.reputation_listings.find(params[:id])
    audits = listing.audits.order(created_at: :desc).limit(30)
    render json: audits.as_json(only: %i[id action audited_changes username created_at])
  end

  # POST /api/v1/accounts/:account_id/reputation/listings
  def create
    listing = current_account.reputation_listings.create!(listing_params)
    Reputation::ListingImageJob.perform_later(listing.id) if listing.image.blank?
    render json: listing, status: :created
  end

  # PATCH /api/v1/accounts/:account_id/reputation/listings/:id
  def update
    listing = current_account.reputation_listings.find(params[:id])
    listing.update!(listing_params)
    render json: listing
  end

  # DELETE /api/v1/accounts/:account_id/reputation/listings/:id
  def destroy
    current_account.reputation_listings.find(params[:id]).destroy!
    head :no_content
  end

  private

  # Backfill storefront photos for listings that have none yet (background,
  # no-ops without GOOGLE_MAPS_API_KEY). Capped so index stays cheap.
  def enqueue_missing_images
    current_account.reputation_listings.where(image: nil).limit(20).pluck(:id).each do |id|
      Reputation::ListingImageJob.perform_later(id)
    end
  end

  def listing_params
    params.permit(:name, :address, :category, :country, :phone, :website, :email, :primary, :image,
                  platforms: [:name, :ok])
  end
end
