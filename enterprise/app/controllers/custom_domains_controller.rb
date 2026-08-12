class CustomDomainsController < ApplicationController
  def verify
    challenge_id = permitted_params[:id]

    domain = request.host
    record = find_record_by_domain(domain)

    return render plain: 'Domain not found', status: :not_found unless record

    ssl_settings = record.ssl_settings || {}

    return render plain: 'Challenge ID not found', status: :not_found unless ssl_settings['cf_verification_id'] == challenge_id

    render plain: ssl_settings['cf_verification_body'], status: :ok
  end

  def acme_challenge
    challenge_id = permitted_params[:id]

    domain = request.host
    record = find_record_by_domain(domain)

    return render plain: 'Domain not found', status: :not_found unless record

    ssl_settings = record.ssl_settings || {}

    return render plain: 'Challenge ID not found', status: :not_found unless ssl_settings['cf_ssl_verification_id'] == challenge_id

    render plain: ssl_settings['cf_ssl_verification_body'], status: :ok
  end

  private

  def find_record_by_domain(domain)
    Portal.find_by('LOWER(custom_domain) = ?', domain.downcase) ||
      Account.find_by('LOWER(custom_domain) = ?', domain.downcase)
  end

  def permitted_params
    params.permit(:id)
  end
end
