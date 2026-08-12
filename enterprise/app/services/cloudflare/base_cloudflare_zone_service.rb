class Cloudflare::BaseCloudflareZoneService
  private

  BASE_URI = 'https://api.cloudflare.com/client/v4'.freeze
  private_constant :BASE_URI

  def headers
    {
      'Authorization' => "Bearer #{api_token}",
      'Content-Type' => 'application/json'
    }
  end

  def api_token
    @api_token ||= GlobalConfigService.load('CLOUDFLARE_API_KEY', nil)
  end

  def zone_id
    @zone_id ||= GlobalConfigService.load('CLOUDFLARE_ZONE_ID', nil)
  end

  def update_ssl_settings(record, data)
    verification_record = data['ownership_verification_http']
    txt_verification = data['ownership_verification']
    ssl_record = data['ssl']
    verification_errors = data['verification_errors']&.first || ''

    # Start with existing settings to preserve verification data if it exists
    ssl_settings = record.ssl_settings || {}

    # Prefer TXT ownership token for DNS instruction UI (Option 2). Keep HTTP
    # challenge id for the well-known endpoint used by Cloudflare.
    if txt_verification.present? && txt_verification['value'].present?
      ssl_settings['cf_verification_body'] = txt_verification['value']
    end

    if verification_record.present?
      ssl_settings['cf_verification_id'] = verification_record['http_url'].split('/').last
      ssl_settings['cf_verification_body'] ||= verification_record['http_body']
    end

    # Also save ACME SSL verification fields if they exist (for HTTP SSL validation)
    if ssl_record.present? && ssl_record['validation_records'].present?
      ssl_validation = ssl_record['validation_records'].first
      if ssl_validation['http_url'].present?
        ssl_settings['cf_ssl_verification_id'] = ssl_validation['http_url'].split('/').last
        ssl_settings['cf_ssl_verification_body'] = ssl_validation['http_body']
      elsif ssl_validation['txt_name'].present?
        # TXT SSL validation challenge
        ssl_settings['cf_ssl_verification_id'] = ssl_validation['txt_name']
        ssl_settings['cf_ssl_verification_body'] = ssl_validation['txt_value']
      end
    end

    # Only overwrite the SSL status once Cloudflare actually reports one - an absent
    # `ssl` block just means the check ran before SSL provisioning caught up, not that
    # the domain regressed, so we keep showing the previous (e.g. "pending") status.
    ssl_settings['cf_status'] = ssl_record['status'] if ssl_record.present?
    ssl_settings['cf_verification_errors'] = verification_errors

    record.update(ssl_settings: ssl_settings)
  end
end
