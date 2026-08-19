class SuperAdmin::CloudflareDomainsController < SuperAdmin::ApplicationController
  def show
    result = Cloudflare::ListCustomHostnamesService.new(page: params[:page]).perform
    @hostnames = result[:data] || []
    @error = result[:errors]&.join(', ')
  end

  def destroy
    domain = params[:hostname]
    result = Cloudflare::DeleteCustomHostnameService.new(domain: domain).perform

    if result[:errors].present?
      redirect_to super_admin_cloudflare_domains_path, alert: result[:errors].join(', ')
    else
      clear_local_domain(domain)
      # rubocop:disable Rails/I18nLocaleTexts
      redirect_to super_admin_cloudflare_domains_path, notice: "Removed #{domain} from Cloudflare"
      # rubocop:enable Rails/I18nLocaleTexts
    end
  end

  private

  # Keep the DB in sync so the freed hostname can be reused and is not re-verified later.
  def clear_local_domain(domain)
    Account.where(custom_domain: domain).update_all(custom_domain: nil)
    Portal.where(custom_domain: domain).update_all(custom_domain: nil)
  end
end
