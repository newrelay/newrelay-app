class NumberProvisioning::CreateInboxService
  pattr_initialize [:order!]

  CHANNELS = {
    'telnyx' => Channel::TelnyxSms,
    'exotel' => Channel::ExotelSms
  }.freeze

  def perform!
    channel = existing_channel
    if channel && channel.account_id != order.account_id
      order.update!(status: 'inbox_pending', failure_code: 'inbox_conflict')
      return :conflict
    end

    channel ||= channel_class.create!(account_id: order.account_id, phone_number: order.phone_number)
    inbox = channel.inbox || Inbox.create!(account: order.account, channel: channel, name: order.phone_number)
    order.update!(inbox: inbox, status: 'active', failure_code: nil)
    :active
  rescue StandardError => e
    Rails.logger.error(
      "[NumberProvisioning] inbox create failed order_id=#{order.id} error=#{e.class}: #{e.message}"
    )
    order.update!(status: 'inbox_pending', failure_code: order.failure_code.presence || 'unknown')
    :pending
  end

  private

  def existing_channel
    channel_class.find_by(phone_number: order.phone_number)
  end

  def channel_class
    CHANNELS.fetch(order.provider_type)
  end
end
