class Webhooks::InstagramController < ActionController::API
  include MetaTokenVerifyConcern

  before_action :verify_meta_signature!, only: :events

  def events
    Rails.logger.info('Instagram webhook received events')
    if params['object'].casecmp('instagram').zero?
      entry_params = params.to_unsafe_hash[:entry]

      route_comment_entries(entry_params)
      route_message_entries(entry_params)

      render json: :ok
    else
      Rails.logger.warn("Message is not received from the instagram webhook event: #{params['object']}")
      head :unprocessable_entity
    end
  end

  private

  def route_comment_entries(entry_params)
    comment_entries = Array(entry_params).select { |entry| comment_entry?(entry.with_indifferent_access) }
    return if comment_entries.blank?

    ::CommentAutomation::InboundCommentJob.perform_later(comment_entries)
  end

  def route_message_entries(entry_params)
    message_entries = Array(entry_params).reject { |entry| comment_entry?(entry.with_indifferent_access) }
    return if message_entries.blank?

    if contains_echo_event?(message_entries)
      ::Webhooks::InstagramEventsJob.set(wait: 2.seconds).perform_later(message_entries)
    else
      ::Webhooks::InstagramEventsJob.perform_later(message_entries)
    end
  end

  def comment_entry?(entry)
    Array(entry[:changes]).any? { |change| change[:field] == 'comments' }
  end

  def contains_echo_event?(entry_params)
    return false unless entry_params.is_a?(Array)

    entry_params.any? do |entry|
      # Check messaging array for echo events
      messaging_events = entry[:messaging] || []
      messaging_events.any? { |messaging| messaging.dig(:message, :is_echo).present? }
    end
  end

  def valid_token?(token)
    # Validates against both IG_VERIFY_TOKEN (Instagram channel via Facebook page) and
    # INSTAGRAM_VERIFY_TOKEN (Instagram channel via direct Instagram login)
    token == GlobalConfigService.load('IG_VERIFY_TOKEN', '') ||
      token == GlobalConfigService.load('INSTAGRAM_VERIFY_TOKEN', '')
  end

  def meta_app_secrets
    [
      *instagram_channel_meta_app_secrets,
      GlobalConfigService.load('INSTAGRAM_APP_SECRET', nil),
      GlobalConfigService.load('FB_APP_SECRET', nil)
    ]
  end

  def instagram_channel_meta_app_secrets
    instagram_channels_from_payload.flat_map { |channel| channel_meta_app_secrets(channel) }
  end

  def instagram_channels_from_payload
    Array(params.to_unsafe_hash[:entry]).flat_map do |entry|
      instagram_ids_from_entry(entry.with_indifferent_access).flat_map do |instagram_id|
        [
          Channel::Instagram.find_by(instagram_id: instagram_id),
          Channel::FacebookPage.find_by(instagram_id: instagram_id)
        ]
      end
    end.compact.uniq
  end

  def instagram_ids_from_entry(entry)
    # Comment entries carry the connected account's instagram id at the top level,
    # not nested under a sender/recipient the way messaging entries do.
    return [entry[:id]].compact if entry[:changes].present?

    messages = entry[:messaging].presence || entry[:standby] || []
    messages.filter_map { |messaging| instagram_id_from_messaging(messaging.with_indifferent_access) }
  end

  def instagram_id_from_messaging(messaging)
    return messaging.dig(:sender, :id) if messaging.dig(:message, :is_echo).present?

    messaging.dig(:recipient, :id)
  end
end
