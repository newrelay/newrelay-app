class Cloudflare::ListCustomHostnamesService < Cloudflare::BaseCloudflareZoneService
  pattr_initialize [:page]

  def perform
    return { errors: ['Cloudflare API token or zone ID not found'] } if api_token.blank? || zone_id.blank?

    response = HTTParty.get(
      "#{BASE_URI}/zones/#{zone_id}/custom_hostnames?per_page=50&page=#{@page || 1}",
      headers: headers
    )

    return { errors: response.parsed_response['errors'] } unless response.success?

    { data: response.parsed_response['result'] || [], result_info: response.parsed_response['result_info'] }
  rescue StandardError => e
    { errors: ["Could not reach Cloudflare: #{e.message}"] }
  end
end
