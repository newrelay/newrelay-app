class Instagram::WebhooksBaseService
  attr_reader :channel

  def initialize(channel)
    @channel = channel
  end

  private

  def inbox_channel(_instagram_id)
    @inbox = ::Inbox.find_by(channel: @channel)
  end

  def find_or_create_contact(user)
    @contact_inbox = @inbox.contact_inboxes.where(source_id: user['id']).first
    @contact = @contact_inbox.contact if @contact_inbox

    if @contact
      update_instagram_profile_link(user)
      apply_comment_automation_attribution(user['id'])
      return
    end

    @contact_inbox = @inbox.channel.create_contact_inbox(
      user['id'], user['name']
    )

    @contact = @contact_inbox.contact
    update_instagram_profile_link(user)
    apply_comment_automation_attribution(user['id'])
    Avatar::AvatarFromUrlJob.perform_later(@contact, user['profile_pic']) if user['profile_pic']
  end

  def update_instagram_profile_link(user)
    return unless user['username']

    instagram_attributes = build_instagram_attributes(user)
    @contact.update!(additional_attributes: @contact.additional_attributes.merge(instagram_attributes))
  end

  def apply_comment_automation_attribution(commenter_id)
    return if @contact.custom_attributes['comment_automation_campaign_id'].present?

    log = CommentAutomation::MessageLog.where(inbox: @inbox, commenter_id: commenter_id, status: :dm_sent).order(created_at: :desc).first
    return if log.blank?

    @contact.update!(custom_attributes: @contact.custom_attributes.merge(
      'comment_automation_campaign_id' => log.trigger.campaign_id,
      'comment_automation_trigger_id' => log.trigger_id
    ))
    log.update!(status: :engaged, contact: @contact)
    Rails.logger.info(
      "[comment_automation] event=engaged campaign_id=#{log.trigger.campaign_id} trigger_id=#{log.trigger_id} contact_id=#{@contact.id}"
    )
  end

  def build_instagram_attributes(user)
    attributes = {
      # TODO: Remove this once we show the social_instagram_user_name in the UI instead of the username
      'social_profiles': { 'instagram': user['username'] },
      'social_instagram_user_name': user['username']
    }

    # Add optional attributes if present
    optional_fields = %w[
      follower_count
      is_user_follow_business
      is_business_follow_user
      is_verified_user
    ]

    optional_fields.each do |field|
      next if user[field].nil?

      attributes["social_instagram_#{field}"] = user[field]
    end

    attributes
  end
end
