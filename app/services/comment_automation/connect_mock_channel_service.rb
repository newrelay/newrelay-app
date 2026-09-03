class CommentAutomation::ConnectMockChannelService
  class Error < StandardError; end

  pattr_initialize [:account!, :url!, :name!]

  MOCK_COMMENTS = [
    { text: 'What is the PRICE on this?', name: 'Alice Johnson' },
    { text: 'PRICE please!', name: 'Bob Williams' },
    { text: 'Need the PRICE for two', name: 'Carla Mendes' },
    { text: 'Is the PRICE still on?', name: 'David Kim' },
    { text: 'PRICE?', name: 'Priya Nair' },
    { text: 'Send me the PRICE', name: 'Tom Becker' }
  ].freeze

  def perform
    raise Error, I18n.t('comment_automation.mock.disabled') unless CommentAutomation.mock?
    raise Error, I18n.t('comment_automation.mock.url_blank') if url.to_s.strip.blank?
    raise Error, I18n.t('comment_automation.mock.name_blank') if name.to_s.strip.blank?

    inbox = nil
    ActiveRecord::Base.transaction do
      inbox = find_or_create_inbox
      campaign = find_or_create_campaign(inbox)
      seed_templates
      seed_comments(inbox, campaign)
      vary_log_statuses(campaign)
    end
    inbox
  end

  private

  def find_or_create_inbox
    channel = Channel::Instagram.find_or_initialize_by(instagram_id: "mock-ig-#{account.id}")
    channel.account = account
    channel.access_token = "mock-#{SecureRandom.hex(16)}" if channel.new_record?
    channel.expires_at = 10.years.from_now
    channel.save!

    inbox = channel.inbox || account.inboxes.create!(channel: channel, name: name.to_s.strip)
    inbox.update!(name: name.to_s.strip)
    inbox
  end

  def find_or_create_campaign(inbox)
    campaign = account.comment_automation_campaigns.find_or_initialize_by(inbox: inbox, post_id: post_id)
    campaign.name = "#{name.to_s.strip} Auto-DM"
    campaign.is_active = true
    campaign.save!
    if campaign.triggers.blank?
      campaign.triggers.create!(
        account: account,
        keyword: 'PRICE',
        match_type: :contains,
        public_replies: ['Thanks — check your DMs for the offer!'],
        dm_text_body: 'Here is 40% off this week: https://shop.example.com/sale'
      )
    end
    campaign
  end

  def seed_templates
    return if account.comment_automation_templates.exists?

    account.comment_automation_templates.create!(
      name: 'Lead Qualification DM',
      template_type: :message,
      public_replies: ['Thanks — I sent details to your DMs!'],
      dm_text_body: 'Want the price list or a demo? Reply PRICE or DEMO.',
      favorite: true
    )
    account.comment_automation_templates.create!(
      name: 'Comment Acknowledgement',
      template_type: :comment,
      public_replies: ['Thanks for the comment, sending you more info now.'],
      dm_text_body: 'Here is the info you asked for.',
      favorite: true
    )
  end

  def seed_comments(inbox, campaign)
    MOCK_COMMENTS.each_with_index do |row, index|
      CommentAutomation::InboundCommentJob.perform_now(
        [{
          id: inbox.channel.instagram_id,
          changes: [{
            field: 'comments',
            value: {
              id: "mock-cmt-#{SecureRandom.hex(8)}-#{index}",
              text: row[:text],
              from: { id: "mock-user-#{index}" },
              media: { id: campaign.post_id }
            }
          }]
        }]
      )
    end
  end

  def vary_log_statuses(campaign)
    logs = CommentAutomation::MessageLog.joins(:trigger)
                                        .where(comment_automation_triggers: { campaign_id: campaign.id })
                                        .order(:id)
                                        .to_a
    return if logs.empty?

    names = MOCK_COMMENTS.pluck(:name)
    logs.first(3).each_with_index do |log, index|
      contact = account.contacts.find_or_create_by!(email: "mock-ar-#{account.id}-#{index}@example.com") do |record|
        record.name = names[index]
      end
      log.update!(contact: contact, status: :engaged)
    end
    logs.last.update!(status: :dm_failed) if logs.size > 3
  end

  def post_id
    match = url.to_s.match(%r{instagram\.com/(?:p|reel|tv)/([^/?#]+)}i)
    (match && match[1]) || url.to_s.strip
  end
end
