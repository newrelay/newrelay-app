class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::SanitizeHelper
  include FrontendUrlsHelper

  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'Chatwoot <accounts@chatwoot.com>')
  before_action { ensure_current_account(params.try(:[], :account)) }
  after_action :apply_branded_from_header
  around_action :switch_locale
  layout 'mailer/base'
  # Fetch template from Database if available
  # Order: Account Specific > Installation Specific > Fallback to file
  prepend_view_path ::EmailTemplate.resolver
  append_view_path Rails.root.join('app/views/mailers')
  helper :frontend_urls
  helper_method :branded_global_config
  helper do
    def global_config
      branded_global_config
    end
  end

  rescue_from(*ExceptionList::SMTP_EXCEPTIONS, with: :handle_smtp_exceptions)

  def smtp_config_set_or_development?
    ENV.fetch('SMTP_ADDRESS', nil).present? || Rails.env.development?
  end

  private

  def handle_smtp_exceptions(message)
    Rails.logger.warn 'Failed to send Email'
    Rails.logger.error "Exception: #{message}"
  end

  def send_mail_with_liquid(*args)
    Rails.logger.info "Email sent to #{args[0][:to]} with subject #{args[0][:subject]}"
    mail(*args) do |format|
      # explored sending a multipart email containing both text type and html
      # parsing the html with nokogiri will remove the links as well
      # might also remove tags like b,li etc. so lets rethink about this later
      # format.text { Nokogiri::HTML(render(layout: false)).text }
      format.html { render }
    end
  end

  def liquid_droppables
    # Merge additional objects into this in your mailer
    # liquid template handler converts these objects into drop objects
    {
      account: Current.account,
      user: @agent,
      conversation: @conversation,
      inbox: @conversation&.inbox
    }
  end

  def branded_global_config
    @branded_global_config ||= begin
      config = GlobalConfig.get('BRAND_NAME', 'BRAND_URL', 'LOGO')
      apply_account_branding_to_mailer_config(config, mailer_brand_account)
      config['LOGO'] = absolute_asset_url(config['LOGO'].presence || '/brand-assets/logo.svg')
      config
    end
  end

  def liquid_locals
    # expose variables you want to be exposed in liquid
    locals = {
      global_config: branded_global_config,
      action_url: @action_url
    }

    locals.merge({ attachment_url: @attachment_url }) if @attachment_url
    locals.merge({ failed_contacts: @failed_contacts, imported_contacts: @imported_contacts })
    locals
  end

  def locale_from_account(account)
    return unless account

    I18n.available_locales.map(&:to_s).include?(account.locale) ? account.locale : nil
  end

  def ensure_current_account(account)
    Current.reset
    Current.account = account if account.present?
  end

  def switch_locale(&)
    locale ||= locale_from_account(Current.account)
    locale ||= I18n.default_locale
    # ensure locale won't bleed into other requests
    # https://guides.rubyonrails.org/i18n.html#managing-the-locale-across-requests
    I18n.with_locale(locale, &)
  end

  def mailer_brand_account
    nearest_branding_account(Current.account.presence || mailer_url_account)
  end

  def nearest_branding_account(account)
    return account if account.blank?

    current = account
    loop do
      return current if own_mailer_branding?(current)
      break if current.parent.blank?

      current = current.parent
    end

    account
  end

  def own_mailer_branding?(account)
    account.custom_domain.present? || account.effective_brand_name.present? || account.effective_brand_logo_url.present?
  end

  def mailer_display_name(account)
    return if account.blank?

    account.effective_brand_name.presence || account.brand_name.presence || (account.custom_domain.present? ? account.name : nil)
  end

  def apply_account_branding_to_mailer_config(config, account)
    return config if account.blank?

    brand_name = mailer_display_name(account)
    config['BRAND_NAME'] = brand_name if brand_name.present?
    config['BRAND_URL'] = frontend_origin(account: account) if account_custom_domain(account).present?

    logo = absolute_brand_logo_url(account)
    config['LOGO'] = logo if logo.present?

    config
  end

  def apply_branded_from_header
    return if message.to.blank?

    account = mailer_brand_account
    name = mailer_display_name(account)
    return if account.blank? || name.blank?

    address = Mail::Address.new
    address.display_name = name
    address.address = mailer_from_email(account)
    message.from = [address.format]
  end

  def mailer_from_email(account)
    domain = account.custom_domain.presence
    stored_address = parsed_support_email(account)

    if resend_sending_ready?(account, domain)
      return stored_address if stored_address.present? && stored_address.downcase.end_with?("@#{domain}")

      return account.ssl_settings['resend_from_email'].presence || "noreply@#{domain}"
    end

    stored_address.presence || platform_sender_email
  rescue Mail::Field::ParseError, Mail::Field::IncompleteParseError
    platform_sender_email
  end

  def parsed_support_email(account)
    stored = account.read_attribute(:support_email).presence
    return if stored.blank?

    Mail::Address.new(stored).address
  end

  def resend_sending_ready?(account, domain)
    domain.present? && account.ssl_settings&.[]('resend_status') == 'verified'
  end

  def platform_sender_email
    Mail::Address.new(ENV.fetch('MAILER_SENDER_EMAIL', 'accounts@chatwoot.com')).address
  rescue Mail::Field::ParseError, Mail::Field::IncompleteParseError
    'accounts@chatwoot.com'
  end
end
