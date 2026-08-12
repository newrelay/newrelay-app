module FrontendUrlsHelper
  def frontend_url(path, **query_params)
    custom_override = nil
    if path == 'auth/confirmation' && ENV['CONFIRMATION_URL'].present?
      custom_override = ENV.fetch('CONFIRMATION_URL', nil)
    elsif path == 'auth/password/edit' && ENV['RESET_PASSWORD_URL'].present?
      custom_override = ENV.fetch('RESET_PASSWORD_URL', nil)
    end

    base_url = root_url
    if defined?(@resource) && @resource.present? && @resource.respond_to?(:accounts)
      custom_domain = nil
      @resource.accounts.each do |acc|
        dom = acc.custom_domain.presence || acc.parent&.custom_domain.presence
        if dom.present?
          custom_domain = dom
          break
        end
      end
      if custom_domain.present?
        begin
          uri = URI.parse(root_url)
          uri.host = custom_domain
          uri.port = nil if (uri.scheme == 'https' && uri.port == 443) || (uri.scheme == 'http' && uri.port == 80)
          base_url = uri.to_s
        rescue StandardError
          # Fallback to default root_url if parsing fails
        end
      end
    end

    base_url = base_url.chomp('/')

    if custom_override.present?
      if custom_override.start_with?('http://', 'https://')
        url_params = if query_params.blank?
                       ''
                     else
                       "#{custom_override.include?('?') ? '&' : '?'}#{query_params.to_query}"
                     end
        "#{custom_override}#{url_params}"
      else
        url_params = query_params.blank? ? '' : "?#{query_params.to_query}"
        "#{base_url}/#{custom_override.sub(%r{\A/}, '')}#{url_params}"
      end
    else
      url_params = query_params.blank? ? '' : "?#{query_params.to_query}"
      "#{base_url}/app/#{path}#{url_params}"
    end
  end
end
