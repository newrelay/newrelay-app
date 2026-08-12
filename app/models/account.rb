# == Schema Information
#
# Table name: accounts
#
#  id                    :integer          not null, primary key
#  auto_resolve_duration :integer
#  brand_logo_url        :string
#  brand_name            :string
#  brand_primary_color   :string
#  brand_secondary_color :string
#  custom_attributes     :jsonb
#  custom_domain         :string
#  domain                :string(100)
#  feature_flags         :bigint           default(0), not null
#  internal_attributes   :jsonb            not null
#  is_reseller           :boolean          default(FALSE), not null
#  limits                :jsonb
#  locale                :integer          default("en")
#  name                  :string           not null
#  settings              :jsonb
#  ssl_settings          :jsonb
#  status                :integer          default("active")
#  support_email         :string(100)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  parent_id             :bigint
#
# Indexes
#
#  index_accounts_on_lower_custom_domain  (lower((custom_domain)::text)) UNIQUE WHERE ((custom_domain IS NOT NULL) AND ((custom_domain)::text <> ''::text))
#  index_accounts_on_parent_id            (parent_id)
#  index_accounts_on_status               (status)
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => accounts.id)
#

class Account < ApplicationRecord
  CAPABILITY_KEYS = %w[white_labeling custom_domain reseller_dashboard api_access].freeze

  # used for single column multi flags
  include FlagShihTzu
  include Reportable
  include Featurable
  include CacheKeys
  include CaptainFeaturable
  include AccountEmailRateLimitable
  include AccountSettingsSchema

  DEFAULT_QUERY_SETTING = {
    flag_query_mode: :bit_operator,
    check_for_column: false
  }.freeze

  validates :name, presence: true
  # `domain` is the inbound email domain used to construct reply addresses
  # (see `inbound_email_domain`). Do not repurpose it for a website or any
  # non-mail-related domain.
  validates :domain, length: { maximum: 100 }
  validates :custom_domain, uniqueness: { allow_blank: true, case_sensitive: false }, length: { maximum: 255 }
  validates_with JsonSchemaValidator,
                 schema: SETTINGS_PARAMS_SCHEMA,
                 attribute_resolver: ->(record) { record.settings }
  validate :validate_reporting_timezone
  validate :validate_support_email_format, if: :will_save_change_to_support_email?
  validate :parent_must_be_a_reseller
  validate :no_self_parenting
  validate :only_two_levels_deep
  validate :t3_subaccount_limit_enforced, if: -> { parent_id.present? }
  validate :reseller_capability_allowed, if: -> { is_reseller? }
  validate :custom_domain_capability_allowed, if: :will_save_change_to_custom_domain?

  before_validation -> { normalize_empty_string_to_nil(%i[custom_domain]) }
  before_validation -> { self.custom_domain = custom_domain&.downcase }
  before_validation :sync_branding_fields_from_brand_colors

  store_accessor :settings, :auto_resolve_after, :auto_resolve_message, :auto_resolve_ignore_waiting

  store_accessor :settings, :audio_transcriptions, :auto_resolve_label
  store_accessor :settings, :captain_models, :captain_features
  store_accessor :settings, :reporting_timezone
  store_accessor :settings, :keep_pending_on_bot_failure
  store_accessor :settings, :captain_auto_resolve_mode
  include AccountCaptainAutoResolve

  belongs_to :parent, class_name: 'Account', optional: true
  has_many :children, class_name: 'Account', foreign_key: :parent_id, dependent: :nullify, inverse_of: :parent
  has_many :sub_accounts, class_name: 'Account', foreign_key: :parent_id, dependent: :nullify, inverse_of: :parent
  has_one :connected_account, dependent: :destroy
  has_many :marketplace_plan_prices, dependent: :destroy
  has_one :subscription, dependent: :destroy
  has_one :enterprise_contract, dependent: :destroy
  has_many :payment_transactions, dependent: :destroy
  has_many :billing_activity_logs, dependent: :destroy

  has_many :account_users, dependent: :destroy_async
  has_many :agent_bot_inboxes, dependent: :destroy_async
  has_many :agent_bots, dependent: :destroy_async
  has_many :api_channels, dependent: :destroy_async, class_name: '::Channel::Api'
  has_many :articles, dependent: :destroy_async, class_name: '::Article'
  has_many :assignment_policies, dependent: :destroy_async
  has_many :automation_rules, dependent: :destroy_async
  has_many :macros, dependent: :destroy_async
  has_many :campaigns, dependent: :destroy_async
  has_many :canned_responses, dependent: :destroy_async
  has_many :categories, dependent: :destroy_async, class_name: '::Category'
  has_many :contacts, dependent: :destroy_async
  has_many :conversations, dependent: :destroy_async
  has_many :csat_survey_responses, dependent: :destroy_async
  has_many :custom_attribute_definitions, dependent: :destroy_async
  has_many :custom_filters, dependent: :destroy_async
  has_many :dashboard_apps, dependent: :destroy_async
  has_many :data_imports, dependent: :destroy_async
  has_many :email_channels, dependent: :destroy_async, class_name: '::Channel::Email'
  has_many :facebook_pages, dependent: :destroy_async, class_name: '::Channel::FacebookPage'
  has_many :instagram_channels, dependent: :destroy_async, class_name: '::Channel::Instagram'
  has_many :tiktok_channels, dependent: :destroy_async, class_name: '::Channel::Tiktok'
  has_many :hooks, dependent: :destroy_async, class_name: 'Integrations::Hook'
  has_many :inboxes, dependent: :destroy_async
  has_many :labels, dependent: :destroy_async
  has_many :line_channels, dependent: :destroy_async, class_name: '::Channel::Line'
  has_many :mentions, dependent: :destroy_async
  has_many :messages, dependent: :destroy_async
  has_many :notes, dependent: :destroy_async
  has_many :notification_settings, dependent: :destroy_async
  has_many :notifications, dependent: :destroy_async
  has_many :portals, dependent: :destroy_async, class_name: '::Portal'
  has_many :sms_channels, dependent: :destroy_async, class_name: '::Channel::Sms'
  has_many :teams, dependent: :destroy_async
  has_many :telegram_channels, dependent: :destroy_async, class_name: '::Channel::Telegram'
  has_many :twilio_sms, dependent: :destroy_async, class_name: '::Channel::TwilioSms'
  has_many :twitter_profiles, dependent: :destroy_async, class_name: '::Channel::TwitterProfile'
  has_many :users, through: :account_users
  has_many :web_widgets, dependent: :destroy_async, class_name: '::Channel::WebWidget'
  has_many :webhooks, dependent: :destroy_async
  has_many :working_hours, dependent: :destroy_async
  has_many :tasks, dependent: :destroy_async
  has_many :bulk_action_audits, dependent: :destroy_async
  has_many :reputation_integrations, dependent: :destroy_async, class_name: 'Reputation::Integration'
  has_many :reputation_reviews, dependent: :destroy_async, class_name: 'Reputation::Review'
  has_many :reputation_templates, dependent: :destroy_async, class_name: 'Reputation::Template'
  has_many :reputation_review_requests, dependent: :destroy_async, class_name: 'Reputation::ReviewRequest'
  has_many :reputation_widgets, dependent: :destroy_async, class_name: 'Reputation::Widget'
  has_many :reputation_video_testimonials, dependent: :destroy_async, class_name: 'Reputation::VideoTestimonial'

  has_one_attached :contacts_export
  has_one_attached :logo
  has_one_attached :dark_logo
  has_one_attached :favicon

  enum :locale, LANGUAGES_CONFIG.map { |key, val| [val[:iso_639_1_code], key] }.to_h, prefix: true
  enum :status, { active: 0, suspended: 1 }

  scope :with_auto_resolve, -> { where("(settings ->> 'auto_resolve_after')::int IS NOT NULL") }

  before_validation :validate_limit_keys
  after_create_commit :notify_creation
  after_update_commit :clear_unread_conversation_counts_cache, if: :saved_change_to_feature_conversation_unread_counts?
  before_save :set_pending_ssl_status, if: :will_save_change_to_custom_domain?
  before_destroy :rescue_orphaned_tenants, if: :is_reseller?
  after_destroy :remove_account_sequences
  after_save :propagate_status_change, if: :saved_change_to_status?
  after_save :enqueue_cloudflare_verification, if: :saved_change_to_custom_domain?

  def agents
    users.where(account_users: { role: :agent })
  end

  def administrators
    users.where(account_users: { role: :administrator })
  end

  def all_conversation_tags
    # returns array of tags
    conversation_ids = conversations.pluck(:id)
    ActsAsTaggableOn::Tagging.includes(:tag)
                             .where(context: 'labels',
                                    taggable_type: 'Conversation',
                                    taggable_id: conversation_ids)
                             .map { |tagging| tagging.tag.name }
  end

  def webhook_data
    {
      id: id,
      name: name
    }
  end

  def inbound_email_domain
    domain.presence || GlobalConfig.get('MAILER_INBOUND_EMAIL_DOMAIN')['MAILER_INBOUND_EMAIL_DOMAIN'] || ENV.fetch('MAILER_INBOUND_EMAIL_DOMAIN',
                                                                                                                   false)
  end

  def support_email
    super.presence || ENV.fetch('MAILER_SENDER_EMAIL') { GlobalConfig.get('MAILER_SUPPORT_EMAIL')['MAILER_SUPPORT_EMAIL'] }
  end

  def logo_url
    return Rails.application.routes.url_helpers.rails_blob_path(logo, only_path: true) if logo.attached?
    return parent.logo_url if parent_id.present?

    ''
  end

  def dark_logo_url
    return Rails.application.routes.url_helpers.rails_blob_path(dark_logo, only_path: true) if dark_logo.attached?
    return parent.dark_logo_url if parent_id.present?

    ''
  end

  def favicon_url
    return Rails.application.routes.url_helpers.rails_blob_path(favicon, only_path: true) if favicon.attached?
    return parent.favicon_url if parent_id.present?

    ''
  end

  def usage_limits
    {
      agents: ChatwootApp.max_limit.to_i,
      inboxes: ChatwootApp.max_limit.to_i
    }
  end

  def capability_enabled?(key)
    capability_key = key.to_s
    return false unless CAPABILITY_KEYS.include?(capability_key)

    feature_enabled?(capability_key)
  end

  def white_labeling_enabled?
    capability_enabled?(:white_labeling)
  end

  def custom_domain_enabled?
    capability_enabled?(:custom_domain)
  end

  def reseller_dashboard_enabled?
    capability_enabled?(:reseller_dashboard)
  end

  def effective_brand_name
    return unless white_labeling_enabled?

    brand_name.presence || custom_attributes.dig('brand_colors', 'brand_name')
  end

  def effective_brand_logo_url
    return unless white_labeling_enabled?

    brand_logo_url.presence || logo_url.presence
  end

  def effective_brand_colors
    return {} unless white_labeling_enabled?

    # brand_colors is the source of truth; the columns only fill gaps for API-only writes
    {
      'brand_name' => brand_name.presence,
      'primary' => brand_primary_color.presence,
      'background' => brand_secondary_color.presence
    }.merge(custom_attributes.fetch('brand_colors', {})).compact
  end

  def connected_account_ready_for_marketplace?
    connected_account&.charges_enabled?
  end

  def locale_english_name
    # the locale can also be something like pt_BR, en_US, fr_FR, etc.
    # the format is `<locale_code>_<country_code>`
    # we need to extract the language code from the locale
    account_locale = locale&.split('_')&.first
    ISO_639.find(account_locale)&.english_name&.downcase || 'english'
  end

  def onboarding_step
    step = custom_attributes['onboarding_step']
    return nil if step.blank?

    enrichment_key = format(Redis::Alfred::ACCOUNT_ONBOARDING_ENRICHMENT, account_id: id)
    Redis::Alfred.exists?(enrichment_key) ? 'enrichment' : step
  end

  def reset_cache_keys
    super
    clear_unread_conversation_counts_cache
  end

  def custom_attributes
    if parent_id.present?
      parent.custom_attributes.slice('plan_name', 'subscribed_quantity', 'subscription_status', 'brand_colors').merge(super || {})
    else
      super || {}
    end
  end

  def limits
    parent_id.present? ? parent.limits : super
  end

  private

  def notify_creation
    Rails.configuration.dispatcher.dispatch(ACCOUNT_CREATED, Time.zone.now, account: self)
  end

  def clear_unread_conversation_counts_cache
    ::Conversations::UnreadCounts::Store.clear_account!(id)
  end

  trigger.after(:insert).for_each(:row) do
    "execute format('create sequence IF NOT EXISTS conv_dpid_seq_%s', NEW.id);"
  end

  trigger.name('camp_dpid_before_insert').after(:insert).for_each(:row) do
    "execute format('create sequence IF NOT EXISTS camp_dpid_seq_%s', NEW.id);"
  end

  def validate_limit_keys
    # method overridden in enterprise module
  end

  def validate_reporting_timezone
    return if reporting_timezone.blank? || ActiveSupport::TimeZone[reporting_timezone].present?

    errors.add(:reporting_timezone, I18n.t('errors.account.reporting_timezone.invalid'))
  end

  def validate_support_email_format
    value = attributes['support_email']
    return if value.blank?

    parsed = Mail::Address.new(value).address
    errors.add(:support_email, I18n.t('errors.account.support_email.invalid')) if parsed.blank?
  rescue Mail::Field::ParseError, Mail::Field::IncompleteParseError
    errors.add(:support_email, I18n.t('errors.account.support_email.invalid'))
  end

  def parent_must_be_a_reseller
    return if parent.blank?

    errors.add(:parent_id, 'must reference an account with is_reseller = true') unless parent.is_reseller?
  end

  def no_self_parenting
    errors.add(:parent_id, 'cannot be its own parent') if parent_id.present? && parent_id == id
  end

  def only_two_levels_deep
    return if parent.blank?

    errors.add(:parent_id, 'cannot set a parent that itself has a parent (max 2 tiers)') if parent.parent_id.present?
  end

  def t3_subaccount_limit_enforced
    return if parent.blank?

    limit = parent.limits['t3_subaccounts']
    return if limit.nil? # unlimited

    existing_count = parent.children.where.not(id: id).count
    return unless existing_count >= limit.to_i

    errors.add(:parent_id, "exceeds the reseller parent's sub-account limit of #{limit}")
  end

  def reseller_capability_allowed
    limit = limits['t3_subaccounts']
    return unless limit.present? && limit.to_i == 0

    errors.add(:is_reseller, 'is not allowed on this plan tier')
  end

  def custom_domain_capability_allowed
    return if custom_domain.blank? || custom_domain_enabled?

    errors.add(:custom_domain, 'is not available on the current plan')
  end

  def sync_branding_fields_from_brand_colors
    brand_colors = custom_attributes['brand_colors']
    return unless brand_colors.is_a?(Hash)

    self.brand_name = brand_colors['brand_name'] if brand_colors['brand_name'].present?
    self.brand_primary_color = brand_colors['primary'] if brand_colors['primary'].present?
    self.brand_secondary_color = brand_colors['background'] if brand_colors['background'].present?
  end

  def remove_account_sequences
    ActiveRecord::Base.connection.exec_query("drop sequence IF EXISTS camp_dpid_seq_#{id}")
    ActiveRecord::Base.connection.exec_query("drop sequence IF EXISTS conv_dpid_seq_#{id}")
  end

  def propagate_status_change
    if suspended?
      if is_reseller?
        sub_accounts.find_each do |child|
          Enterprise::Billing::TenantRescueService.new.call(child)
        end
      else
        sub_accounts.update_all(status: :suspended)
      end
    elsif active?
      sub_accounts.update_all(status: :active)
    end
  end

  def rescue_orphaned_tenants
    sub_accounts.find_each do |child|
      Enterprise::Billing::TenantRescueService.new.call(child)
    end
  end

  def set_pending_ssl_status
    if custom_domain.blank?
      self.ssl_settings = {}
      return
    end

    self.ssl_settings = (ssl_settings || {}).merge(
      'cf_status' => 'pending_validation'
    )
  end

  def enqueue_cloudflare_verification
    if saved_change_to_custom_domain? && custom_domain_before_last_save.present?
      Enterprise::CloudflareDeletionJob.perform_later(custom_domain_before_last_save)
    end

    return if custom_domain.blank?

    Enterprise::CloudflareVerificationJob.perform_later('Account', id)
  end
end

Account.prepend_mod_with('Account')
Account.prepend_mod_with('Account::PlanUsageAndLimits')
Account.include_mod_with('Concerns::Account')
Account.include_mod_with('Audit::Account')
