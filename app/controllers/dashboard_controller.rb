class DashboardController < ActionController::Base
  include SwitchLocale

  GLOBAL_CONFIG_KEYS = %w[
    LOGO
    LOGO_DARK
    LOGO_THUMBNAIL
    INSTALLATION_NAME
    WIDGET_BRAND_URL
    TERMS_URL
    BRAND_URL
    BRAND_NAME
    PRIVACY_URL
    DISPLAY_MANIFEST
    CREATE_NEW_ACCOUNT_FROM_DASHBOARD
    CHATWOOT_INBOX_TOKEN
    API_CHANNEL_NAME
    API_CHANNEL_THUMBNAIL
    CLOUD_ANALYTICS_TOKEN
    DIRECT_UPLOADS_ENABLED
    MAXIMUM_FILE_UPLOAD_SIZE
    HCAPTCHA_SITE_KEY
    LOGOUT_REDIRECT_LINK
    DISABLE_USER_PROFILE_UPDATE
    DEPLOYMENT_ENV
    INSTALLATION_PRICING_PLAN
  ].freeze

  before_action :set_application_pack
  before_action :set_global_config
  before_action :set_dashboard_scripts
  around_action :switch_locale
  before_action :ensure_installation_onboarding, only: [:index]
  before_action :render_hc_if_custom_domain, only: [:index]
  before_action :ensure_html_format
  layout 'vueapp'

  def index; end

  private

  def ensure_html_format
    render json: { error: 'Please use API routes instead of dashboard routes for JSON requests' }, status: :not_acceptable if request.format.json?
  end

  def set_global_config
    @global_config = GlobalConfig.get(*GLOBAL_CONFIG_KEYS).merge(app_config)

    # White-labeling overrides: Inject Account branding into global config
    account_id = request.path.match(%r{/app/accounts/(\d+)})&.captures&.first
    account = Account.find_by(id: account_id) if account_id
    account ||= Account.find_by('LOWER(custom_domain) = ?', request.host.downcase)

    apply_branding_overrides(account) if account
  end

  def apply_branding_overrides(account)
    return unless account.white_labeling_enabled?

    if account.effective_brand_logo_url.present?
      @global_config['LOGO'] = account.effective_brand_logo_url
      @global_config['LOGO_DARK'] = (account.dark_logo_url.presence || account.effective_brand_logo_url)
    end
    @global_config['LOGO_THUMBNAIL'] = account.favicon_url if account.favicon_url.present?

    brand_colors = account.effective_brand_colors
    return if brand_colors.blank?

    @global_config['BRAND_COLORS'] = brand_colors
    @brand_colors = brand_colors
    brand_name = account.effective_brand_name
    return if brand_name.blank?

    @global_config['INSTALLATION_NAME'] = brand_name
    @global_config['BRAND_NAME'] = brand_name
  end

  # Convert a hex color (#rrggbb) to "r g b" format for CSS custom properties
  def hex_to_rgb_space(hex)
    return nil if hex.blank?

    hex = hex.delete('#')
    r = hex[0..1].to_i(16)
    g = hex[2..3].to_i(16)
    b = hex[4..5].to_i(16)
    "#{r} #{g} #{b}"
  rescue StandardError
    nil
  end
  helper_method :hex_to_rgb_space

  # Lighten a hex color by adding `amount` to its lightness (0..1 scale).
  # Mirrors the JS `lighten()` from color2k used in generateThemeVariables.
  def lighten_hex(hex, amount)
    return nil if hex.blank?

    hex = hex.delete('#')
    r = hex[0..1].to_i(16) / 255.0
    g = hex[2..3].to_i(16) / 255.0
    b = hex[4..5].to_i(16) / 255.0

    # RGB → HSL
    max_c = [r, g, b].max
    min_c = [r, g, b].min
    l = ((max_c + min_c) / 2.0).clamp(0.0, 1.0)

    # Lighten (clamp 0..1)
    l = (l + amount).clamp(0.0, 1.0)

    d = max_c - min_c
    s = d.zero? ? 0 : d / (1 - ((2 * l) - 1).abs)

    h = compute_hue(r, g, b, max_c, d)

    # HSL → RGB
    c  = (1 - ((2 * l) - 1).abs) * s
    x  = c * (1 - (((h / 60.0) % 2) - 1).abs)
    m  = l - (c / 2.0)

    r2, g2, b2 = hue_to_rgb_components(h, c, x)

    "#{((r2 + m) * 255).round} #{((g2 + m) * 255).round} #{((b2 + m) * 255).round}"
  rescue StandardError
    hex_to_rgb_space(hex)
  end
  helper_method :lighten_hex

  # Determines if a hex color has dark luminance (< 0.5)
  # Mirrors the JS `getLuminance()` from color2k used in generateThemeVariables.
  def dark_background?(hex)
    return false if hex.blank?

    hex = hex.delete('#')
    if hex.length == 3
      r = hex[0].dup.concat(hex[0]).to_i(16) / 255.0
      g = hex[1].dup.concat(hex[1]).to_i(16) / 255.0
      b = hex[2].dup.concat(hex[2]).to_i(16) / 255.0
    elsif hex.length == 6
      r = hex[0..1].to_i(16) / 255.0
      g = hex[2..3].to_i(16) / 255.0
      b = hex[4..5].to_i(16) / 255.0
    else
      return false
    end

    l_r = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055)**2.4
    l_g = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055)**2.4
    l_b = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055)**2.4

    luminance = (0.2126 * l_r) + (0.7152 * l_g) + (0.0722 * l_b)
    luminance < 0.5
  rescue StandardError
    false
  end
  helper_method :dark_background?

  # Build an inline style string with CSS custom properties for brand colors.
  def brand_colors_inline_style(brand_colors)
    parts = []
    if brand_colors['primary'].present?
      parts << "--primary: #{brand_colors['primary']}"
      parts << "--ring: #{brand_colors['primary']}"
      parts << "--sidebar-primary: #{brand_colors['primary']}"
      parts << "--woot-brand: #{hex_to_rgb_space(brand_colors['primary'])}"
    end
    if brand_colors['secondary'].present?
      parts << "--secondary: #{brand_colors['secondary']}"
      parts << "--muted: #{brand_colors['secondary']}"
    end
    if brand_colors['accent'].present?
      parts << "--accent: #{brand_colors['accent']}"
      parts << "--sidebar-accent: #{brand_colors['accent']}"
    end
    if brand_colors['text'].present?
      parts << "--foreground: #{brand_colors['text']}"
      parts << "--slate-12: #{hex_to_rgb_space(brand_colors['text'])}"
    end
    if brand_colors['background'].present?
      parts << "--background: #{brand_colors['background']}"
      parts << "--card: #{brand_colors['background']}"
      parts << "--popover: #{brand_colors['background']}"
      parts << "--background-color: #{hex_to_rgb_space(brand_colors['background'])}"
    end
    # Full theme-preset chrome tokens (sidebar, card, muted, border, …) when stored
    brand_theme_token_keys.each do |key|
      value = brand_colors[key]
      next if value.blank?

      parts << "--#{key}: #{value}"
    end
    parts.compact.join('; ')
  end
  helper_method :brand_colors_inline_style

  def brand_theme_token_keys
    %w[
      foreground card card-foreground popover popover-foreground
      primary-foreground secondary-foreground muted muted-foreground
      accent-foreground destructive destructive-foreground
      border input ring
      sidebar sidebar-foreground sidebar-primary sidebar-primary-foreground
      sidebar-accent sidebar-accent-foreground sidebar-border sidebar-ring
    ]
  end
  helper_method :brand_theme_token_keys

  def compute_hue(r, g, b, max_c, d)
    return 0 if d.zero?

    if max_c == r
      60 * (((g - b) / d) % 6)
    elsif max_c == g
      60 * (((b - r) / d) + 2)
    else
      60 * (((r - g) / d) + 4)
    end
  end

  def hue_to_rgb_components(h, c, x)
    if h < 60
      [c, x, 0]
    elsif h < 120
      [x, c, 0]
    elsif h < 180
      [0, c, x]
    elsif h < 240
      [0, x, c]
    elsif h < 300
      [x, 0, c]
    else
      [c, 0, x]
    end
  end

  def set_dashboard_scripts
    @dashboard_scripts = sensitive_path? ? nil : GlobalConfig.get_value('DASHBOARD_SCRIPTS')
  end

  def ensure_installation_onboarding
    redirect_to '/installation/onboarding' if ::Redis::Alfred.get(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
  end

  def render_hc_if_custom_domain
    domain = request.host
    return if domain == URI.parse(ENV.fetch('FRONTEND_URL', '')).host

    @portal = Portal.find_by('LOWER(custom_domain) = ?', domain.downcase)
    return unless @portal

    @locale = @portal.default_locale
    render 'public/api/v1/portals/show', layout: 'portal', portal: @portal and return
  end

  def app_config
    {
      APP_VERSION: Chatwoot.config[:version],
      VAPID_PUBLIC_KEY: VapidService.public_key,
      ENABLE_ACCOUNT_SIGNUP: GlobalConfigService.load('ENABLE_ACCOUNT_SIGNUP', 'false'),
      FB_APP_ID: GlobalConfigService.load('FB_APP_ID', ''),
      INSTAGRAM_APP_ID: GlobalConfigService.load('INSTAGRAM_APP_ID', ''),
      TIKTOK_APP_ID: GlobalConfigService.load('TIKTOK_APP_ID', ''),
      FACEBOOK_API_VERSION: GlobalConfigService.load('FACEBOOK_API_VERSION', 'v18.0'),
      WHATSAPP_APP_ID: GlobalConfigService.load('WHATSAPP_APP_ID', ''),
      WHATSAPP_CONFIGURATION_ID: GlobalConfigService.load('WHATSAPP_CONFIGURATION_ID', ''),
      IS_ENTERPRISE: ChatwootApp.enterprise?,
      AZURE_APP_ID: GlobalConfigService.load('AZURE_APP_ID', ''),
      GIT_SHA: GIT_HASH,
      ALLOWED_LOGIN_METHODS: allowed_login_methods,
      ACTIVE_PLATFORM_BANNERS: active_platform_banners
    }
  end

  def active_platform_banners
    return [] unless ChatwootApp.chatwoot_cloud?

    PlatformBanner.active.order(created_at: :desc).as_json(only: %i[id banner_message banner_type updated_at])
  end

  def allowed_login_methods
    methods = ['email']
    methods << 'google_oauth' if GlobalConfigService.load('ENABLE_GOOGLE_OAUTH_LOGIN', 'true').to_s != 'false'
    methods << 'saml' if ChatwootHub.pricing_plan != 'community' && GlobalConfigService.load('ENABLE_SAML_SSO_LOGIN', 'true').to_s != 'false'
    methods
  end

  def set_application_pack
    @application_pack = if request.path.include?('/auth') || request.path.include?('/login')
                          'v3app'
                        else
                          'dashboard'
                        end
  end

  def sensitive_path?
    # dont load dashboard scripts on sensitive paths like password reset
    sensitive_paths = [edit_user_password_path].freeze

    # remove app prefix
    current_path = request.path.gsub(%r{^/app}, '')

    sensitive_paths.include?(current_path)
  end
end
