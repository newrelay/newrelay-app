class Cloudflare::CheckCustomHostnameService < Cloudflare::BaseCloudflareZoneService
  pattr_initialize [:record!]

  def perform
    return { errors: ['Cloudflare API token or zone ID not found'] } if api_token.blank? || zone_id.blank?
    return { errors: ['No custom domain found'] } if @record.custom_domain.blank?

    response = HTTParty.get(
      "#{BASE_URI}/zones/#{zone_id}/custom_hostnames?hostname=#{@record.custom_domain}", headers: headers
    )

    return { errors: response.parsed_response['errors'] } unless response.success?

    data = response.parsed_response['result']

    if data.present?
      custom_hostname = data.first
      update_ssl_settings(@record, custom_hostname)

      # If the status is still pending, force Cloudflare to run a live DNS scan immediately
      if custom_hostname['status'] == 'pending' || custom_hostname.dig('ssl', 'status') == 'pending_validation'
        trigger_validation_retry(
          custom_hostname['id'],
          custom_hostname.dig('ssl', 'method'),
          custom_hostname.dig('ssl', 'type')
        )
      end

      return { data: data }
    end

    { errors: ['Hostname is missing in Cloudflare'] }
  end

  private

  def trigger_validation_retry(custom_hostname_id, ssl_method, ssl_type)
    HTTParty.patch(
      "#{BASE_URI}/zones/#{zone_id}/custom_hostnames/#{custom_hostname_id}",
      headers: headers,
      body: {
        ssl: {
          method: ssl_method || 'http',
          type: ssl_type || 'dv'
        }
      }.to_json
    )
  rescue StandardError => e
    Rails.logger.error("Cloudflare SSL Validation Retry failed for hostname #{custom_hostname_id}: #{e.message}")
  end
end
