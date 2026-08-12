class Cloudflare::DeleteCustomHostnameService < Cloudflare::BaseCloudflareZoneService
  pattr_initialize [:domain!]

  def perform
    return { errors: ['Cloudflare API token or zone ID not found'] } if api_token.blank? || zone_id.blank?
    return { errors: ['No domain provided'] } if @domain.blank?

    # 1. Find the hostname ID on Cloudflare by query
    response = HTTParty.get(
      "#{BASE_URI}/zones/#{zone_id}/custom_hostnames?hostname=#{@domain}",
      headers: headers
    )

    return { errors: response.parsed_response['errors'] } unless response.success?

    data = response.parsed_response['result']
    return { errors: ["Hostname #{@domain} not found in Cloudflare"] } if data.blank?

    custom_hostname_id = data.first['id']

    # 2. Delete the custom hostname
    delete_response = HTTParty.delete(
      "#{BASE_URI}/zones/#{zone_id}/custom_hostnames/#{custom_hostname_id}",
      headers: headers
    )

    return { errors: delete_response.parsed_response['errors'] } unless delete_response.success?

    { data: delete_response.parsed_response['result'] }
  end
end
