class Api::V1::Accounts::Integrations::ExotelController < Api::BaseController
  skip_before_action :authenticate_access_token!, raise: false
  skip_before_action :validate_bot_access_token!, raise: false
  skip_before_action :authenticate_user!, raise: false

  def incoming_call
    if params[:CallSid].blank? || params[:From].blank?
      return render json: { error: 'Missing required CallSid or From parameters' }, status: :bad_request
    end

    account = Account.find(params[:account_id])
    call_sid = params[:CallSid]
    from_number = params[:From]

    # Initialize/fetch conversation for logging
    conversation = fetch_or_create_conversation(account, call_sid, from_number)

    # Greeting message
    greeting_text = 'Welcome to Daksh AI. How can I assist you today?'

    # Log greeting response
    conversation.messages.create!(
      account: account,
      inbox: conversation.inbox,
      message_type: :outgoing,
      content: greeting_text
    )

    audio_url = generate_speech_audio(account, greeting_text) || '/voice_agent/default_fallback.mp3'
    callback_url = "#{request.base_url}/api/v1/accounts/#{account.id}/integrations/exotel/speech_callback?CallSid=#{call_sid}&From=#{CGI.escape(from_number)}"

    response_xml = <<~XML
      <Response>
        <Play>#{request.base_url}#{audio_url}</Play>
        <Record action="#{callback_url}" method="POST" maxLength="15" playBeep="false" />
      </Response>
    XML

    render xml: response_xml
  end

  def speech_callback
    if params[:CallSid].blank? || params[:From].blank?
      return render json: { error: 'Missing required CallSid or From parameters' }, status: :bad_request
    end

    account = Account.find(params[:account_id])
    call_sid = params[:CallSid]
    from_number = params[:From]
    recording_url = params[:RecordingUrl]

    # Transcribe recording or use parameter for testing
    user_speech = params[:Transcription].presence || transcribe_audio(recording_url)

    conversation = fetch_or_create_conversation(account, call_sid, from_number)

    # Log incoming user speech
    conversation.messages.create!(
      account: account,
      inbox: conversation.inbox,
      message_type: :incoming,
      content: user_speech,
      sender: conversation.contact
    )

    # Generate AI response
    ai_response = generate_ai_response(account, user_speech).presence || 'I am sorry, I did not catch that. Can you please repeat?'

    # Log outgoing AI agent response
    conversation.messages.create!(
      account: account,
      inbox: conversation.inbox,
      message_type: :outgoing,
      content: ai_response
    )

    audio_url = generate_speech_audio(account, ai_response) || '/voice_agent/default_fallback.mp3'
    callback_url = "#{request.base_url}/api/v1/accounts/#{account.id}/integrations/exotel/speech_callback?CallSid=#{call_sid}&From=#{CGI.escape(from_number)}"

    response_xml = if ai_response.downcase.include?('transfer') || ai_response.downcase.include?('hold on')
                     <<~XML
                       <Response>
                         <Play>#{request.base_url}#{audio_url}</Play>
                         <Hangup />
                       </Response>
                     XML
                   else
                     <<~XML
                       <Response>
                         <Play>#{request.base_url}#{audio_url}</Play>
                         <Record action="#{callback_url}" method="POST" maxLength="15" playBeep="false" />
                       </Response>
                     XML
                   end

    render xml: response_xml
  end

  private

  def fetch_or_create_conversation(account, call_sid, from_number)
    from_number = normalize_phone_number(from_number)
    contact = account.contacts.find_by(phone_number: from_number)
    if contact.nil?
      contact = account.contacts.create!(
        name: "Guest #{from_number.last(4)}",
        phone_number: from_number
      )
    end

    inbox = account.inboxes.find_by(name: 'Exotel Voice Agent')
    if inbox.nil?
      api_channel = Channel::Api.create!(account: account)
      inbox = account.inboxes.create!(name: 'Exotel Voice Agent', channel: api_channel)
      user = account.users.first
      InboxMember.create!(user: user, inbox: inbox) if user
    end

    contact_inbox = ContactInbox.find_or_create_by!(
      contact_id: contact.id,
      inbox_id: inbox.id
    ) do |ci|
      ci.source_id = from_number
    end

    conversation = account.conversations.find_by(uuid: call_sid) ||
                   account.conversations.where("additional_attributes ->> 'call_sid' = ?", call_sid).first

    if conversation.nil?
      conversation = account.conversations.create!(
        account: account,
        inbox: inbox,
        status: :open,
        contact: contact,
        contact_inbox: contact_inbox,
        additional_attributes: { call_sid: call_sid, type: 'voice_call' }
      )
    end
    conversation
  end

  def transcribe_audio(recording_url)
    return 'Hello, I would like to learn about Daksh AI features.' if recording_url.blank?

    # In production, download recording_url and call transcription API (Whisper/etc)
    # For local/testing, we fallback to a smart simulation based on the url
    'Simulated audio transcript from recording'
  end

  def generate_ai_response(account, prompt)
    openai_hook = account.hooks.find_by(app_id: 'openai', status: 'enabled')
    api_key = openai_hook&.settings&.dig('api_key') || ENV.fetch('OPENAI_API_KEY', nil)

    if api_key.present?
      begin
        response = HTTParty.post(
          'https://api.openai.com/v1/chat/completions',
          headers: {
            'Authorization' => "Bearer #{api_key}",
            'Content-Type' => 'application/json'
          },
          body: {
            model: 'gpt-4o-mini',
            messages: [
              { role: 'system',
                content: 'You are a lifelike voice AI assistant representing newrelay (a premium CRM platform). Give short, conversational audio-friendly answers (1-2 sentences max).' },
              { role: 'user', content: prompt }
            ],
            max_tokens: 150
          }.to_json
        )
        return response.parsed_response.dig('choices', 0, 'message', 'content') if response.success?
      rescue StandardError => e
        Rails.logger.error "OpenAI Call Failed: #{e.message}"
      end
    end

    # Fallback to local rule-based response
    generate_rule_based_response(prompt)
  end

  def generate_rule_based_response(prompt)
    prompt_clean = prompt.downcase
    if prompt_clean.include?('feature') || prompt_clean.include?('crm') || prompt_clean.include?('daksh')
      'Daksh AI is an advanced CRM platform featuring task boards, contacts management, corporate registries, and voice AI integrations.'
    elsif prompt_clean.include?('pricing') || prompt_clean.include?('cost')
      'Our pricing starts at twenty-nine dollars per user month. Contact sales for details.'
    elsif prompt_clean.include?('human') || prompt_clean.include?('agent') || prompt_clean.include?('operator')
      'Let me transfer you to a human agent. Please hold on.'
    else
      "I heard you say: #{prompt}. How else can I assist you with Daksh AI today?"
    end
  end

  def generate_speech_audio(account, text)
    elevenlabs_hook = account.hooks.find_by(app_id: 'elevenlabs', status: 'enabled')
    api_key = elevenlabs_hook&.settings&.dig('api_key') || ENV.fetch('ELEVENLABS_API_KEY', 'mock_key')
    voice_id = elevenlabs_hook&.settings&.dig('voice_id')

    client = ElevenLabs.new(api_key, voice_id)
    client.text_to_speech(text)
  end

  def normalize_phone_number(phone_number)
    return nil if phone_number.blank?

    # URL-decoded '+' can turn into a space
    normalized = phone_number.strip.gsub(/\A\s+/, '+')
    # Prepend '+' if missing
    normalized = "+#{normalized}" unless normalized.start_with?('+')
    normalized
  end
end
