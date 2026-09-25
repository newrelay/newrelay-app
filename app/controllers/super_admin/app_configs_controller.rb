class SuperAdmin::AppConfigsController < SuperAdmin::ApplicationController
  LEGACY_CONFIG_KEYS = { 'captain' => 'relay-ai' }.freeze
  CONFIG_HEADINGS = { 'relay-ai' => 'Relay AI' }.freeze

  before_action :set_config
  before_action :redirect_legacy_config, only: :show
  before_action :allowed_configs
  helper_method :config_heading

  def show
    # ref: https://github.com/rubocop/rubocop/issues/7767
    # rubocop:disable Style/HashTransformValues
    @app_config = InstallationConfig.where(name: @allowed_configs)
                                    .pluck(:name, :serialized_value)
                                    .map { |name, serialized_value| [name, serialized_value['value']] }
                                    .to_h
    # rubocop:enable Style/HashTransformValues
    @installation_configs = ConfigLoader.new.general_configs.each_with_object({}) do |config_hash, result|
      result[config_hash['name']] = config_hash.except('name')
    end
  end

  def create
    errors = []
    if @config == 'relay-ai' && captain_key_invalid?
      errors << 'OpenAI API Key could not be verified against the configured endpoint. Please check the key and try again.'
    else
      params['app_config'].each do |key, value|
        next unless @allowed_configs.include?(key)

        i = InstallationConfig.where(name: key).first_or_create(value: value, locked: false)
        i.value = value
        errors.concat(i.errors.full_messages) unless i.save
      end
    end

    if errors.any?
      redirect_to super_admin_app_config_path(config: @config), alert: errors.join(', ')
    else
      redirect_to super_admin_settings_path, flash: success_flash
    end
  end

  def test_captain_key
    key = params[:api_key].presence || InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    endpoint = params[:api_endpoint].presence || InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value

    render json: { valid: Integrations::Openai::KeyValidator.valid?(key, endpoint: endpoint) }
  end

  private

  def captain_key_invalid?
    submitted = params['app_config'] || {}
    key = submitted['CAPTAIN_OPEN_AI_API_KEY']
    return false if key.blank?

    endpoint = submitted['CAPTAIN_OPEN_AI_ENDPOINT'].presence || InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    !Integrations::Openai::KeyValidator.valid?(key, endpoint: endpoint)
  end

  def set_config
    requested = params[:config].presence || 'general'
    @config = LEGACY_CONFIG_KEYS[requested] || requested
  end

  def redirect_legacy_config
    return unless LEGACY_CONFIG_KEYS.key?(params[:config].to_s)

    redirect_to super_admin_app_config_path(config: @config)
  end

  def config_heading
    CONFIG_HEADINGS.fetch(@config, @config.titleize)
  end

  def allowed_configs
    mapping = {
      'facebook' => %w[FB_APP_ID FB_VERIFY_TOKEN FB_APP_SECRET IG_VERIFY_TOKEN FACEBOOK_API_VERSION ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT],
      'shopify' => %w[SHOPIFY_CLIENT_ID SHOPIFY_CLIENT_SECRET],
      'microsoft' => %w[AZURE_APP_ID AZURE_APP_SECRET],
      'email' => %w[MAILER_INBOUND_EMAIL_DOMAIN RESEND_API_KEY RESEND_WEBHOOK_SECRET ACCOUNT_EMAILS_LIMIT ACCOUNT_EMAILS_PLAN_LIMITS],
      'linear' => %w[LINEAR_CLIENT_ID LINEAR_CLIENT_SECRET],
      'slack' => %w[SLACK_CLIENT_ID SLACK_CLIENT_SECRET],
      'instagram' => %w[INSTAGRAM_APP_ID INSTAGRAM_APP_SECRET INSTAGRAM_VERIFY_TOKEN INSTAGRAM_API_VERSION ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT],
      'tiktok' => %w[TIKTOK_APP_ID TIKTOK_APP_SECRET TIKTOK_API_VERSION],
      'whatsapp_embedded' => %w[WHATSAPP_APP_ID WHATSAPP_APP_SECRET WHATSAPP_CONFIGURATION_ID WHATSAPP_API_VERSION],
      'notion' => %w[NOTION_CLIENT_ID NOTION_CLIENT_SECRET],
      'google' => %w[GOOGLE_OAUTH_CLIENT_ID GOOGLE_OAUTH_CLIENT_SECRET GOOGLE_OAUTH_REDIRECT_URI ENABLE_GOOGLE_OAUTH_LOGIN],
      'relay-ai' => %w[CAPTAIN_OPEN_AI_API_KEY CAPTAIN_OPEN_AI_MODEL CAPTAIN_OPEN_AI_ENDPOINT],
      'number_provisioning' => %w[TELNYX_RESELLER_API_KEY]
    }

    @allowed_configs = mapping.fetch(
      @config,
      %w[ENABLE_ACCOUNT_SIGNUP FIREBASE_PROJECT_ID FIREBASE_CREDENTIALS WEBHOOK_TIMEOUT MAXIMUM_FILE_UPLOAD_SIZE WIDGET_TOKEN_EXPIRY]
    )
  end

  def success_notice
    message = "#{config_heading} settings updated successfully"
    return message unless restart_required_config_saved?

    "#{message.delete_suffix('.')}. Restart newrelay web and worker processes to apply this change everywhere."
  end

  def success_flash
    restart_required_config_saved? ? { success: success_notice } : { notice: success_notice }
  end

  def restart_required_config_saved?
    params.fetch('app_config', {}).keys.intersect?(InstallationConfig::RESTART_REQUIRED_CONFIG_KEYS)
  end
end

SuperAdmin::AppConfigsController.prepend_mod_with('SuperAdmin::AppConfigsController')
