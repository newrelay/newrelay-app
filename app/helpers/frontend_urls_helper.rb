module FrontendUrlsHelper
  def frontend_url(path, **query_params)
    custom_override = nil
    if path == 'auth/confirmation' && ENV['CONFIRMATION_URL'].present?
      custom_override = ENV.fetch('CONFIRMATION_URL', nil)
    elsif path == 'auth/password/edit' && ENV['RESET_PASSWORD_URL'].present?
      custom_override = ENV.fetch('RESET_PASSWORD_URL', nil)
    end

    base_url = frontend_origin(account: mailer_url_account)
    url_params = query_params.blank? ? '' : "?#{query_params.to_query}"

    if custom_override.present?
      if custom_override.start_with?('http://', 'https://')
        override_params = if query_params.blank?
                            ''
                          else
                            "#{custom_override.include?('?') ? '&' : '?'}#{query_params.to_query}"
                          end
        "#{custom_override}#{override_params}"
      else
        "#{base_url}/#{custom_override.sub(%r{\A/}, '')}#{url_params}"
      end
    else
      "#{base_url}/app/#{path}#{url_params}"
    end
  end

  def frontend_origin(account: nil)
    origin_for_account(account || mailer_url_account)
  end

  def account_app_url(account, path)
    "#{frontend_origin(account: account)}/app/accounts/#{account.id}/#{path.to_s.sub(%r{\A/}, '')}"
  end

  def conversation_frontend_url(conversation)
    account_app_url(conversation.account, "conversations/#{conversation.display_id}")
  end

  def absolute_asset_url(path)
    return if path.blank?
    return path if path.start_with?('http://', 'https://')

    "#{default_frontend_origin}#{path.start_with?('/') ? path : "/#{path}"}"
  end

  def absolute_brand_logo_url(account)
    absolute_asset_url(account&.effective_brand_logo_url)
  end

  def mailer_url_account
    resource_account_with_domain || conversation_mailer_account || Current.account.presence
  end

  private

  def resource_account_with_domain
    return unless defined?(@resource) && @resource.respond_to?(:accounts)

    @resource.accounts.detect { |account| account_custom_domain(account).present? }
  end

  def conversation_mailer_account
    @conversation&.account if defined?(@conversation)
  end

  def account_custom_domain(account)
    return if account.blank?

    account.custom_domain.presence || account.parent&.custom_domain.presence
  end

  def origin_for_account(account)
    base = default_frontend_origin
    domain = account_custom_domain(account)
    return base if domain.blank?

    uri = URI.parse(base)
    uri.host = domain
    uri.port = nil
    uri.to_s.chomp('/')
  rescue StandardError
    base
  end

  def default_frontend_origin
    root_url.to_s.chomp('/')
  end
end
