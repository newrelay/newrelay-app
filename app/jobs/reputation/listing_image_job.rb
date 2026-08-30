# Resolves a storefront photo for a listing from Google Places and stores a
# KEYLESS image URL (Google's photo endpoint 302s to a googleusercontent URL —
# we capture that so GOOGLE_MAPS_API_KEY is never persisted or sent to the browser).
# No-ops without the key. Stores '' on a genuine miss so the listing is not
# retried on every index load.
class Reputation::ListingImageJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(listing_id)
    listing = Reputation::Listing.find_by(id: listing_id)
    return if listing.nil? || listing.image.present?

    api_key = ENV.fetch('GOOGLE_MAPS_API_KEY', nil)
    return if api_key.blank?

    listing.update!(image: resolve_image(listing, api_key).to_s)
  end

  private

  def resolve_image(listing, api_key)
    query = [listing.name, listing.address].compact_blank.join(' ')
    return nil if query.blank?

    ref = photo_reference(query, api_key)
    return nil if ref.blank?

    keyless_photo_url(ref, api_key)
  rescue StandardError => e
    Rails.logger.error "ListingImageJob failed for listing #{listing.id}: #{e.message}"
    nil
  end

  def photo_reference(query, api_key)
    resp = HTTParty.get(
      "https://maps.googleapis.com/maps/api/place/textsearch/json?query=#{CGI.escape(query)}&key=#{api_key}",
      http_opts
    )
    return nil unless resp.success?

    resp.parsed_response.dig('results', 0, 'photos', 0, 'photo_reference')
  end

  def keyless_photo_url(ref, api_key)
    resp = HTTParty.get(
      "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=#{ref}&key=#{api_key}",
      http_opts.merge(follow_redirects: false)
    )
    resp.headers['location']
  end

  def http_opts
    Rails.env.development? ? { verify: false } : {}
  end
end
