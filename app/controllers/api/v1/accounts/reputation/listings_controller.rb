class Api::V1::Accounts::Reputation::ListingsController < Api::V1::Accounts::Reputation::BaseController
  # GET /api/v1/accounts/:account_id/reputation/listings
  def index
    enqueue_missing_images
    listings = current_account.reputation_listings.order(primary: :desc, created_at: :asc)
    render json: listings.as_json(methods: :photo_urls)
  end

  # GET /api/v1/accounts/:account_id/reputation/listings/:id
  def show
    render json: current_account.reputation_listings.find(params[:id]).as_json(methods: :photo_urls)
  end

  # POST /api/v1/accounts/:account_id/reputation/listings/:id/photos
  def upload_photos
    listing = current_account.reputation_listings.find(params[:id])
    listing.photos.attach(params[:photos])
    render json: listing.as_json(methods: :photo_urls)
  end

  # DELETE /api/v1/accounts/:account_id/reputation/listings/:id/photos/:photo_id
  def destroy_photo
    listing = current_account.reputation_listings.find(params[:id])
    listing.photos.find(params[:photo_id]).purge
    render json: listing.as_json(methods: :photo_urls)
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
    render json: listing.as_json(methods: :photo_urls), status: :created
  end

  # PATCH /api/v1/accounts/:account_id/reputation/listings/:id
  def update
    listing = current_account.reputation_listings.find(params[:id])
    listing.update!(listing_params)
    render json: listing.as_json(methods: :photo_urls)
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
                  :description, :additional_categories, :service_area,
                  platforms: [:name, :ok], hours: {}, holiday_hours: [:date, :label], amenities: {}, social_links: {})
  end
end
