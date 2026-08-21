class Api::V1::Accounts::Reputation::ListingsController < Api::V1::Accounts::BaseController
  # GET /api/v1/accounts/:account_id/reputation/listings
  def index
    render json: current_account.reputation_listings.order(primary: :desc, created_at: :asc)
  end

  # POST /api/v1/accounts/:account_id/reputation/listings
  def create
    listing = current_account.reputation_listings.create!(listing_params)
    render json: listing, status: :created
  end

  # DELETE /api/v1/accounts/:account_id/reputation/listings/:id
  def destroy
    current_account.reputation_listings.find(params[:id]).destroy!
    head :no_content
  end

  private

  def listing_params
    params.permit(:name, :address, :category, :country, :phone, :website, :email, :primary,
                  platforms: [:name, :ok])
  end
end
