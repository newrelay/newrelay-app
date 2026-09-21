class Webhooks::ResendController < ActionController::API
  def process_payload
    payload = request.raw_post
    return head :unauthorized unless verified?(payload)

    event = JSON.parse(payload)
    enqueue_received_email(event)
    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  private

  def verified?(payload)
    Resend::WebhookVerifier.valid?(
      payload: payload,
      id: request.headers['svix-id'],
      timestamp: request.headers['svix-timestamp'],
      signatures: request.headers['svix-signature'],
      secret: webhook_secret
    )
  end

  def webhook_secret
    GlobalConfigService.load('RESEND_WEBHOOK_SECRET', nil)
  end

  def enqueue_received_email(event)
    return unless event['type'] == 'email.received'

    email_id = event.dig('data', 'email_id')
    return if email_id.blank?

    Resend::ProcessReceivedEmailJob.perform_later(email_id)
  end
end
