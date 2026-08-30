class Api::V1::Reputation::SyncController < ApplicationController
  skip_before_action :set_current_user

  def create
    ids = integration_ids
    return head :not_found if ids.empty?

    ids.each { |id| Reputation::ReviewSyncJob.perform_later(id) }
    listing&.update!(synced_at: Time.current)

    render json: { ok: true, queued: ids }
  end

  private

  def integration
    @integration ||= Reputation::Integration.find_by(id: params[:id])
  end

  def listing
    return @listing if defined?(@listing)

    @listing = integration ? nil : Reputation::Listing.find_by(id: params[:id])
  end

  def integration_ids
    return [integration.id] if integration&.active?
    return listing.account.reputation_integrations.active.pluck(:id) if listing

    []
  end
end
