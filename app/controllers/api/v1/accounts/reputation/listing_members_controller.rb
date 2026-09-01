class Api::V1::Accounts::Reputation::ListingMembersController < Api::V1::Accounts::Reputation::BaseController
  before_action :listing
  before_action :authorize_admin!, only: [:create, :destroy]

  def index
    render json: listing.members.as_json(only: %i[id name email available_name])
  end

  def create
    member = listing.listing_members.find_or_create_by!(
      account: current_account,
      user_id: params.require(:user_id)
    )
    render json: member.user.as_json(only: %i[id name email available_name]), status: :created
  end

  def destroy
    listing.listing_members.find_by!(user_id: params[:id]).destroy!
    head :no_content
  end

  private

  def listing
    @listing ||= scoped_listings.find(params[:listing_id])
  end

  def authorize_admin!
    raise Pundit::NotAuthorizedError unless administrator?
  end
end
