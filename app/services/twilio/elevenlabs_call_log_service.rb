class Twilio::ElevenlabsCallLogService
  pattr_initialize [:account!, :payload!]

  def perform
    return unless payload['type'] == 'post_call_transcription'

    data = payload['data']
    return unless data.is_a?(Hash)

    channel = channel_for(data)
    return if channel.blank?

    conversation_id = data['conversation_id'].to_s
    return if conversation_id.blank?
    return if already_logged?(channel, conversation_id)

    record_call(channel, data, conversation_id)
  end

  private

  def channel_for(data)
    agent_id = data['agent_id'].presence
    channel = Channel::TwilioSms.find_by(account_id: account.id, elevenlabs_agent_id: agent_id) if agent_id
    return channel if channel

    called = called_number(data)
    return if called.blank?

    digits = called.gsub(/\D/, '')
    Channel::TwilioSms.where(account_id: account.id).find { |row| row.phone_number.to_s.gsub(/\D/, '') == digits }
  end

  def already_logged?(channel, conversation_id)
    channel.inbox.messages.exists?(source_id: source_id(conversation_id, 0))
  end

  def record_call(channel, data, conversation_id)
    inbox = channel.inbox
    contact_inbox = build_contact_inbox(inbox, data, conversation_id)
    conversation = open_conversation(inbox, contact_inbox)
    turns_for(data).each_with_index do |turn, index|
      write_turn(conversation, contact_inbox, conversation_id, turn, index)
    end
  end

  def build_contact_inbox(inbox, data, conversation_id)
    phone = caller_phone(data)
    ContactInboxWithContactBuilder.new(
      inbox: inbox,
      source_id: phone.presence || "elevenlabs:#{conversation_id}",
      contact_attributes: { name: phone.presence || 'Voice caller', phone_number: phone }
    ).perform
  end

  def turns_for(data)
    turns = transcript_turns(data)
    return turns if turns.present?

    [{ 'role' => 'agent', 'message' => data.dig('analysis', 'transcript_summary').presence || 'Voice call' }]
  end

  def write_turn(conversation, contact_inbox, conversation_id, turn, index)
    content = turn['message'].to_s.strip
    return if content.blank?

    incoming = turn['role'] == 'user'
    # source_id is set so the channel does not text this transcript back to the caller
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content: content,
      message_type: incoming ? :incoming : :outgoing,
      sender: incoming ? contact_inbox.contact : nil,
      source_id: source_id(conversation_id, index),
      private: false
    )
  end

  def open_conversation(inbox, contact_inbox)
    conversation = if inbox.lock_to_single_conversation
                     contact_inbox.conversations.last
                   else
                     contact_inbox.conversations.where.not(status: :resolved).last
                   end
    return conversation if conversation

    Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id
    )
  end

  def transcript_turns(data)
    Array(data['transcript']).select { |turn| turn.is_a?(Hash) && turn['message'].present? }
  end

  def caller_phone(data)
    normalize_phone(variable(data, 'system__caller_id') || phone_call_value(data, 'external_number') || phone_call_value(data, 'from'))
  end

  def called_number(data)
    variable(data, 'system__called_number') || phone_call_value(data, 'agent_number') || phone_call_value(data, 'to')
  end

  def variable(data, key)
    vars = data.dig('conversation_initiation_client_data', 'dynamic_variables')
    vars[key] if vars.is_a?(Hash)
  end

  def phone_call_value(data, key)
    phone_call = data.dig('metadata', 'phone_call')
    phone_call[key] if phone_call.is_a?(Hash)
  end

  def normalize_phone(value)
    digits = value.to_s.gsub(/[^\d]/, '')
    return if digits.length < 8

    "+#{digits}"
  end

  def source_id(conversation_id, index)
    "elevenlabs:#{conversation_id}:#{index}"
  end
end
