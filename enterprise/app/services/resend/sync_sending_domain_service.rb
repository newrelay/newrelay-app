class Resend::SyncSendingDomainService < Resend::BaseService
  pattr_initialize [:account!]

  def perform
    return { skipped: true } if api_key.blank?
    return { errors: ['No hostname found'] } if @account.custom_domain.blank?

    data = existing_domain || create_domain
    return { errors: [@create_error || 'Could not create Resend domain'] } if data.blank?

    verify_domain(data['id'])
    data = fetch_domain(data['id']) || data
    persist(data)

    { data: data }
  end

  private

  def hostname
    @hostname ||= @account.custom_domain.downcase
  end

  def existing_domain
    stored_id = @account.ssl_settings&.[]('resend_domain_id')
    fetched = fetch_domain(stored_id) if stored_id.present?
    return fetched if fetched.present? && fetched['name'].to_s.downcase == hostname

    response = request(:get, '/domains')
    return unless response.success?

    Array(response.parsed_response['data']).find { |domain| domain['name'].to_s.downcase == hostname }
  end

  def create_domain
    response = request(:post, '/domains', body: { name: hostname })
    return response.parsed_response if response.success?

    @create_error = error_messages(response).join(', ')
    nil
  end

  def fetch_domain(domain_id)
    return if domain_id.blank?

    response = request(:get, "/domains/#{domain_id}")
    response.parsed_response if response.success?
  end

  def verify_domain(domain_id)
    request(:post, "/domains/#{domain_id}/verify")
  end

  def persist(data)
    ssl_settings = @account.ssl_settings || {}
    ssl_settings['resend_domain_id'] = data['id']
    ssl_settings['resend_status'] = data['status']
    ssl_settings['resend_records'] = Array(data['records'])
    ssl_settings['resend_from_email'] = "noreply@#{hostname}"
    @account.update(ssl_settings: ssl_settings)
  end
end
