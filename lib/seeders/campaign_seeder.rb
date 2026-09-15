## Seeds live-chat campaigns against the website inbox so /widget_tests can be used locally.
#
#   Seeders::CampaignSeeder.new(account: Account.find(1)).perform!
#
class Seeders::CampaignSeeder
  PAGES = %w[home pricing about].freeze

  def initialize(account:)
    raise 'Campaign seeding is not allowed in production.' unless ENV.fetch('ENABLE_ACCOUNT_SEEDING', !Rails.env.production?)

    @account = account
  end

  def perform!
    @account.enable_features!('campaigns') unless @account.feature_enabled?('campaigns')
    ensure_website_inbox!
    ensure_inbox_membership!

    campaigns = seed_campaigns
    print_summary(campaigns)
    campaigns
  end

  private

  def ensure_website_inbox!
    @inbox = @account.inboxes.find_by(channel_type: 'Channel::WebWidget')
    return if @inbox.present?

    channel = Channel::WebWidget.create!(account: @account, website_url: "#{base_url}/widget_tests")
    @inbox = @account.inboxes.create!(name: 'Campaign Test Website', channel: channel)
  end

  def ensure_inbox_membership!
    return if sender.blank?

    InboxMember.find_or_create_by!(inbox: @inbox, user: sender)
  end

  def seed_campaigns
    campaign_attrs.map do |attrs|
      campaign = @account.campaigns.find_or_initialize_by(title: attrs[:title], inbox: @inbox)
      campaign.assign_attributes(attrs.merge(account: @account, inbox: @inbox, sender: sender, enabled: true))
      campaign.save!
      campaign
    end
  end

  def campaign_attrs
    [
      {
        title: '[Test] Welcome on Home',
        message: 'Hi! Welcome to Acme. Need a hand getting started? Ask me anything.',
        trigger_rules: { url: "#{base_url}/widget_tests/home/", time_on_page: 3 },
        trigger_only_during_business_hours: false
      },
      {
        title: '[Test] Pricing help',
        message: 'Looking at pricing? I can help you pick a plan or start a trial.',
        trigger_rules: { url: "#{base_url}/widget_tests/pricing/", time_on_page: 3 },
        trigger_only_during_business_hours: false
      },
      {
        title: '[Test] About us',
        message: 'Want to know more about Acme? I can walk you through how we work.',
        trigger_rules: { url: "#{base_url}/widget_tests/about/", time_on_page: 5 },
        trigger_only_during_business_hours: false
      }
    ]
  end

  def sender
    @sender ||= @account.administrators.first || @account.users.first
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000').chomp('/')
  end

  def print_summary(campaigns)
    Rails.logger.info("[campaign_seeder] inbox=#{@inbox.name} campaigns=#{campaigns.size}")
    campaigns.each do |campaign|
      Rails.logger.info("  - #{campaign.title}: #{campaign.trigger_rules['url']} (#{campaign.trigger_rules['time_on_page']}s)")
    end
  end
end
