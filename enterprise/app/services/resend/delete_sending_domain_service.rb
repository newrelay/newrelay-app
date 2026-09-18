class Resend::DeleteSendingDomainService < Resend::BaseService
  pattr_initialize [:domain!]

  def perform
    return { skipped: true } if api_key.blank?
    return { errors: ['No domain provided'] } if @domain.blank?

    domain_id = find_domain_id
    return { data: true } if domain_id.blank?

    response = request(:delete, "/domains/#{domain_id}")
    return { errors: error_messages(response) } unless response.success?

    { data: response.parsed_response }
  end

  private

  def find_domain_id
    response = request(:get, '/domains')
    return unless response.success?

    match = Array(response.parsed_response['data']).find { |domain| domain['name'].to_s.downcase == @domain.downcase }
    match&.[]('id')
  end
end
