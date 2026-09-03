class SuperAdmin::CloudflareDomainsController < SuperAdmin::ApplicationController
  def show
    result = Cloudflare::ListCustomHostnamesService.new(page: params[:page]).perform
    @hostnames = result[:data] || []
    @error = format_cloudflare_errors(result[:errors])
  end

  def destroy
    domain = params[:hostname]
    result = Cloudflare::DeleteCustomHostnameService.new(domain: domain).perform

    if result[:errors].present?
      redirect_to super_admin_cloudflare_domains_path, alert: format_cloudflare_errors(result[:errors])
    else
      clear_local_domain(domain)
      # rubocop:disable Rails/I18nLocaleTexts
      redirect_to super_admin_cloudflare_domains_path, notice: "Removed #{domain} from Cloudflare"
      # rubocop:enable Rails/I18nLocaleTexts
    end
  end

  private

  # Cloudflare returns errors as an array of hashes, e.g.
  #   [{ "code" => 10000, "message" => "Authentication error" }]
  # (our own guards return plain strings). Extract the human-readable message so
  # the admin banner/flash shows "Authentication error" instead of the raw hash.
  def format_cloudflare_errors(errors)
    return if errors.blank?

    Array(errors).filter_map do |error|
      error.is_a?(Hash) ? error['message'].presence || error.to_json : error.to_s
    end.join(', ')
  end

  # Keep the DB in sync so the freed hostname can be reused and is not re-verified later.
  def clear_local_domain(domain)
    Account.where(custom_domain: domain).update_all(custom_domain: nil)
    Portal.where(custom_domain: domain).update_all(custom_domain: nil)
  end
end
