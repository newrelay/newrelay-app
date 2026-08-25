class Campaigns::AnalyticsService
  DEFAULT_RANGE_DAYS = 30

  def initialize(account:, since: nil, until_time: nil, status: nil, inbox_id: nil)
    @account = account
    @since = parse_time(since) || DEFAULT_RANGE_DAYS.days.ago.beginning_of_day
    @until_time = parse_time(until_time) || Time.zone.now.end_of_day
    @status = status.presence
    @inbox_id = inbox_id.presence
  end

  def perform
    scoped = base_scope
    {
      summary: build_summary(scoped),
      campaigns: build_campaign_rows(scoped),
      filters: {
        since: @since.iso8601,
        until: @until_time.iso8601
      }
    }
  end

  private

  def base_scope
    scope = @account.campaigns.includes(:inbox).where(created_at: @since..@until_time)
    scope = scope.where(campaign_status: @status) if @status.present?
    scope = scope.where(inbox_id: @inbox_id) if @inbox_id.present?
    scope.order(created_at: :desc)
  end

  def build_summary(scoped)
    {
      total_campaigns: scoped.count,
      active: scoped.active.count,
      completed: scoped.completed.count,
      processing: scoped.processing.count,
      attributed_conversations: attributed_conversations_count(scoped)
    }
  end

  def attributed_conversations_count(scoped)
    campaign_ids = scoped.ids
    return 0 if campaign_ids.empty?

    @account.conversations.where(campaign_id: campaign_ids).count
  end

  def build_campaign_rows(scoped)
    conversation_counts = @account.conversations
                                  .where(campaign_id: scoped.ids)
                                  .group(:campaign_id)
                                  .count

    scoped.map do |campaign|
      {
        id: campaign.id,
        display_id: campaign.display_id,
        title: campaign.title,
        description: campaign.description,
        campaign_type: campaign.campaign_type,
        campaign_status: campaign.campaign_status,
        scheduled_at: campaign.scheduled_at,
        created_at: campaign.created_at,
        audience_count: audience_count(campaign),
        conversations_count: conversation_counts[campaign.id] || 0,
        inbox: inbox_payload(campaign.inbox)
      }
    end
  end

  def audience_count(campaign)
    audience = campaign.audience
    return 0 unless audience.is_a?(Array)

    audience.size
  end

  def inbox_payload(inbox)
    return nil unless inbox

    {
      id: inbox.id,
      name: inbox.name,
      channel_type: inbox.channel_type
    }
  end

  def parse_time(value)
    return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)
    return if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
