class Inboxes::SyncSocialAvatarService
  pattr_initialize [:inbox!]

  def perform
    return inbox.avatar_url if inbox.avatar.attached?

    url = remote_avatar_url
    return '' if url.blank?

    Avatar::AvatarFromUrlJob.perform_now(inbox, url)
    inbox.reload.avatar_url.to_s
  rescue StandardError => e
    Rails.logger.warn("[inbox_avatar] inbox_id=#{inbox.id} #{e.class}: #{e.message}")
    ''
  end

  def remote_avatar_url
    case inbox.channel_type
    when 'Channel::Instagram'
      instagram_profile_picture_url
    when 'Channel::FacebookPage'
      facebook_picture_url
    else
      ''
    end
  end

  private

  def instagram_profile_picture_url
    channel = inbox.channel
    return if CommentAutomation.mock_channel?(channel)

    token = channel[:access_token]
    return if token.blank?

    version = GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')
    response = HTTParty.get(
      "https://graph.instagram.com/#{version}/me",
      query: { fields: 'profile_picture_url', access_token: token },
      headers: { 'Accept' => 'application/json' }
    )
    return unless response.success?

    parsed_body(response)['profile_picture_url']
  end

  def facebook_picture_url
    channel = inbox.channel
    token = channel.page_access_token
    return if token.blank? || channel.page_id.blank?

    response = HTTParty.get(
      "https://graph.facebook.com/#{channel.page_id}/picture",
      query: { type: 'large', redirect: false, access_token: token },
      headers: { 'Accept' => 'application/json' }
    )
    return facebook_redirect_url(channel.page_id, token) unless response.success?

    parsed_body(response).dig('data', 'url').presence || facebook_redirect_url(channel.page_id, token)
  end

  def facebook_redirect_url(page_id, token)
    "https://graph.facebook.com/#{page_id}/picture?#{ { type: 'large', access_token: token }.to_query }"
  end

  def parsed_body(response)
    body = response.parsed_response
    body = JSON.parse(body) if body.is_a?(String)
    body.is_a?(Hash) ? body : {}
  end
end
