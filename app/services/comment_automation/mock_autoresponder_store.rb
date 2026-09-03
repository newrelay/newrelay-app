# rubocop:disable Metrics/ClassLength
class CommentAutomation::MockAutoresponderStore
  class Error < StandardError; end

  SOCIAL_INBOX_TYPES = ['Channel::Instagram', 'Channel::FacebookPage'].freeze
  SETTINGS_KEY = 'comment_automation_settings'.freeze

  SETTINGS_DEFAULT = {
    general: {
      globalAutomation: true, defaultResponseType: 'Reply in thread', defaultResponseTime: 'No delay',
      lookbackWindow: '24 hours', assignTo: 'Unassigned', autoApplyTag: 'No tag selected',
      defaultLanguage: 'English (US)', preventDuplicate: true, ignoreBots: true
    },
    behavior: {
      replyType: 'Reply in thread', responseDelay: 'No delay', typingIndicator: true, randomDelay: true,
      randomDelayMin: '2', randomDelayMax: '6', readInboundMessage: true, splitLongMessages: true,
      brandingSignature: 'No signature', useRichPreviews: true
    },
    safety: {
      safeMode: true, maxResponses: '1 per person', cooldownPeriod: '24 hours', dailyLimit: '0',
      respectLimits: true, preventDuplicatesSafe: true, checkSimilar: false, allowAllChannels: false,
      keywordFiltering: true, autoFlag: true, blockUnknown: false,
      rateLimits: [
        { platform: 'Instagram', limit: '200 requests / hour' },
        { platform: 'Facebook', limit: '200 requests / hour' },
        { platform: 'WhatsApp', limit: '1000 messages / day' }
      ]
    },
    hours: {
      enableBusinessHours: true, timeZone: '(GMT+05:30) Asia/Kolkata', outsideAction: 'away_message',
      weeklySchedule: [
        { id: 'mon', label: 'Monday', active: true, start: '09:00 AM', end: '06:00 PM' },
        { id: 'tue', label: 'Tuesday', active: true, start: '09:00 AM', end: '06:00 PM' },
        { id: 'wed', label: 'Wednesday', active: true, start: '09:00 AM', end: '06:00 PM' },
        { id: 'thu', label: 'Thursday', active: true, start: '09:00 AM', end: '06:00 PM' },
        { id: 'fri', label: 'Friday', active: true, start: '09:00 AM', end: '06:00 PM' },
        { id: 'sat', label: 'Saturday', active: false, start: '09:00 AM', end: '06:00 PM' },
        { id: 'sun', label: 'Sunday', active: false, start: '09:00 AM', end: '06:00 PM' }
      ]
    },
    notifications: {
      enableQuietHours: true, quietFrom: '10:00 PM', quietTo: '07:00 AM',
      enableDailyDigest: true, digestTime: '09:00 AM',
      preferences: [
        { id: 'nt1', name: 'Automation Triggered', desc: 'When an automation is triggered.', email: true, inapp: true },
        { id: 'nt2', name: 'New Incoming Message', desc: 'When a new message is received.', email: true, inapp: true },
        { id: 'nt3', name: 'Automation Completed', desc: 'When an automation finishes running.', email: false, inapp: true },
        { id: 'nt4', name: 'Automation Failed', desc: 'When an automation fails.', email: true, inapp: true },
        { id: 'nt5', name: 'Daily Limit Reached', desc: 'When daily message limit is reached.', email: true, inapp: true }
      ]
    },
    advanced: {
      processingMode: 'Real-time (Recommended)', concurrentAutomations: '5', retryFailedActions: true,
      maxRetries: '3', retryInterval: '5 minutes', dataRetention: '12 months', storeMessageHistory: true,
      apiAccess: true, maintenanceMode: false,
      systemHealth: [
        { label: 'Queue health', status: 'Healthy' },
        { label: 'API latency', status: '120ms' },
        { label: 'Uptime', status: '99.98%' }
      ]
    }
  }.freeze

  class << self
    def cache
      @cache ||= {}
    end

    def reset!
      cache.clear
    end
  end

  def initialize(account)
    @account = account
  end

  def social_accounts
    social_inboxes.map { |inbox| serialize_inbox(inbox).merge(overlay("inbox-#{inbox.id}")) }
  end

  def team_members
    @account.users.map { |user| { id: user.id.to_s, name: user.name, email: user.email, avatar: user.avatar_url.to_s } }
  end

  def teams
    @account.teams.pluck(:name)
  end

  def posts
    campaigns.map { |campaign| serialize_campaign(campaign).deep_merge(overlay("post-#{campaign.id}")) }
  end

  def dms
    state[:dms] || []
  end

  def automations
    campaigns.map(&:name)
  end

  def defaults
    state[:defaults]
  end

  def settings
    stored = (@account.custom_attributes || {})[SETTINGS_KEY]
    SETTINGS_DEFAULT.deep_dup.deep_merge(normalize_settings(stored))
  end

  def update_social_account(id, attrs)
    account = social_accounts.find { |item| item[:id].to_s == id.to_s }
    return if account.blank?

    patch = attrs.symbolize_keys.slice(:assignedTeam, :accessLevel, :assignedMembers, :lastSync)
    overlay("inbox-#{id}").merge!(patch)
    account.merge(patch)
  end

  def connect(platform)
    raise Error, I18n.t('comment_automation.mock.disabled') unless mock?
    raise Error, I18n.t('comment_automation.mock.facebook_unsupported') if platform.to_s == 'Facebook'

    inbox = CommentAutomation::ConnectMockChannelService.new(
      account: @account,
      url: 'https://www.instagram.com/p/mock-summer-sale/',
      name: 'Instagram Shop'
    ).perform
    serialize_inbox(inbox).merge(overlay("inbox-#{inbox.id}"))
  end

  def update_response_control(id, attrs)
    key = campaigns.any? { |campaign| campaign.id.to_s == id.to_s } ? "post-#{id}" : "dm-#{id}"
    allowed = attrs.deep_symbolize_keys
    overlay(key).deep_merge!(allowed.slice(:comments, :dms, :enabled, :overridden, :automation))
    posts.find { |post| post[:id].to_s == id.to_s } || dms.find { |dm| dm[:id].to_s == id.to_s }
  end

  def update_defaults(attrs)
    state[:defaults].merge!(attrs.symbolize_keys.slice(:comments, :dms))
    state[:defaults]
  end

  def update_settings(attrs)
    merged = settings.deep_merge(normalize_settings(attrs))
    @account.update!(
      custom_attributes: (@account.custom_attributes || {}).merge(SETTINGS_KEY => merged.deep_stringify_keys)
    )
    settings
  end

  def sync
    social_accounts
  end

  private

  def mock?
    CommentAutomation.mock?
  end

  def state
    self.class.cache[@account.id] ||= empty_state.merge(
      defaults: { comments: true, dms: true },
      dms: [],
      overlays: {}
    )
  end

  def empty_state
    { defaults: { comments: true, dms: true }, dms: [], overlays: {} }
  end

  def normalize_settings(raw)
    return {} if raw.blank?

    raw.to_h.deep_symbolize_keys
  end

  def overlay(key)
    state[:overlays][key] ||= {}
  end

  def social_inboxes
    @account.inboxes.includes(:channel).select { |inbox| SOCIAL_INBOX_TYPES.include?(inbox.channel_type) }
  end

  def campaigns
    @account.comment_automation_campaigns.includes(:inbox, triggers: :message_logs).order(created_at: :desc)
  end

  def serialize_inbox(inbox)
    {
      id: inbox.id.to_s,
      name: inbox.name,
      handle: "@#{inbox.name.to_s.parameterize}",
      platform: inbox.instagram_direct? ? 'Instagram' : 'Facebook',
      avatar: inbox.avatar_url.to_s,
      status: 'Connected',
      automationsCount: @account.comment_automation_campaigns.where(inbox: inbox).count,
      followersCount: '',
      assignedTeam: teams.first.to_s,
      assignedMembers: [],
      accessLevel: 'Manager',
      lastSync: inbox.updated_at&.iso8601
    }
  end

  def serialize_campaign(campaign)
    logs = campaign.triggers.flat_map(&:message_logs)
    {
      id: campaign.id, inboxId: campaign.inbox_id.to_s, title: campaign.name, type: 'Post',
      publishedAt: campaign.created_at.strftime('%b %d, %Y'), thumbnail: campaign.inbox&.avatar_url.to_s,
      comments: { enabled: campaign.is_active, overridden: false, automation: campaign.name },
      dms: { enabled: campaign.is_active, overridden: false, automation: campaign.name },
      stats: { commentsSent: logs.size, dmsSent: logs.count { |log| log.dm_sent? || log.engaged? } }
    }
  end
end
# rubocop:enable Metrics/ClassLength
