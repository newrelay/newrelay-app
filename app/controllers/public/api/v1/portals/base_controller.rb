class Public::Api::V1::Portals::BaseController < PublicController
  include SwitchLocale

  before_action :show_plain_layout
  before_action :set_color_scheme
  before_action :set_global_config
  around_action :set_locale
  after_action :allow_iframe_requests

  PORTAL_LAYOUTS = %w[classic documentation].freeze

  private

  def show_plain_layout
    @is_plain_layout_enabled = params[:show_plain_layout] == 'true'
  end

  def set_color_scheme
    @theme_from_params = params[:theme] if %w[dark light].include?(params[:theme])
  end

  def set_portal_layout
    @portal_layout = PORTAL_LAYOUTS.include?(@portal&.layout) ? @portal.layout : 'classic'
  end

  def set_view_variant
    request.variant = :documentation if @portal_layout == 'documentation' && !@is_plain_layout_enabled
  end

  def portal
    @portal ||= if params[:slug].present?
                  Portal.find_by!(slug: params[:slug], archived: false)
                else
                  domain = request.host
                  p = Portal.find_by(custom_domain: domain, archived: false)
                  p ||= Account.find_by(custom_domain: domain)&.portals&.active&.first
                  raise ActiveRecord::RecordNotFound, "Portal not found for domain: #{domain}" if p.blank?

                  p
                end
  end

  def set_locale(&)
    switch_locale_with_portal(&) if params[:locale].present?
    switch_locale_with_article(&) if params[:article_slug].present?

    yield
  end

  def switch_locale_with_portal(&)
    @locale = validate_and_get_locale(params[:locale])

    I18n.with_locale(@locale, &)
  end

  def switch_locale_with_article(&)
    article = Article.find_by(slug: params[:article_slug])
    Rails.logger.info "Article: not found for slug: #{params[:article_slug]}"
    render_404 && return if article.blank?

    article_locale = if article.category.present?
                       article.category.locale
                     else
                       article.locale
                     end
    @locale = validate_and_get_locale(article_locale)
    I18n.with_locale(@locale, &)
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options') if @is_plain_layout_enabled
  end

  def render_404
    portal
    render 'public/api/v1/portals/error/404', status: :not_found
  end

  def set_global_config
    @global_config = GlobalConfig.get('LOGO_THUMBNAIL', 'BRAND_NAME', 'BRAND_URL', 'INSTALLATION_NAME')
  end
end
