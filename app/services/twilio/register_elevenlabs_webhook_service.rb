class Twilio::RegisterElevenlabsWebhookService
  pattr_initialize [:inbox!, :channel!, :hook!, :agent_id!]

  def perform
    webhook_id = existing_webhook_id || create_webhook
    response = HTTParty.patch(agent_url, headers: json_headers, body: agent_body(webhook_id).to_json, timeout: 20)
    return if response.success?

    raise Twilio::ConnectElevenlabsService::Error, "ElevenLabs: #{response.code}"
  end

  private

  def existing_webhook_id
    existing = Channel::TwilioSms.where(account_id: inbox.account_id).where.not(elevenlabs_webhook_secret: nil).first
    return if existing.blank?

    channel.update!(
      elevenlabs_webhook_id: existing.elevenlabs_webhook_id,
      elevenlabs_webhook_secret: existing.elevenlabs_webhook_secret
    )
    existing.elevenlabs_webhook_id
  end

  def create_webhook
    response = HTTParty.post(
      Twilio::ConnectElevenlabsService::ELEVENLABS_WEBHOOKS_URL,
      headers: json_headers,
      body: webhook_body.to_json,
      timeout: 20
    )
    body = response.parsed_response
    webhook_id = body['webhook_id'] if response.success? && body.is_a?(Hash)
    secret = body['webhook_secret'] if body.is_a?(Hash)
    raise Twilio::ConnectElevenlabsService::Error, "ElevenLabs: #{response.code}" if webhook_id.blank? || secret.blank?

    channel.update!(elevenlabs_webhook_id: webhook_id, elevenlabs_webhook_secret: secret)
    webhook_id
  end

  def webhook_body
    {
      settings: {
        auth_type: 'hmac',
        name: "Inbox #{inbox.id}",
        webhook_url: Rails.application.routes.url_helpers.webhooks_elevenlabs_url(inbox.account_id)
      }
    }
  end

  def agent_body(webhook_id)
    {
      platform_settings: {
        workspace_overrides: {
          webhooks: { post_call_webhook_id: webhook_id, events: ['transcript'] }
        }
      }
    }
  end

  def agent_url
    "#{Twilio::ConnectElevenlabsService::ELEVENLABS_AGENTS_URL}/#{agent_id}"
  end

  def json_headers
    { 'xi-api-key' => hook.settings['api_key'], 'Content-Type' => 'application/json' }
  end
end
