class Twilio::ElevenlabsVoicesService
  VOICES_URL = 'https://api.elevenlabs.io/v2/voices'.freeze
  VOICE_URL = 'https://api.elevenlabs.io/v1/voices'.freeze
  ADD_URL = 'https://api.elevenlabs.io/v1/voices/add'.freeze
  AGENTS_URL = Twilio::ConnectElevenlabsService::ELEVENLABS_AGENTS_URL
  MAX_PAGES = 5
  MAX_CLIP_BYTES = 10.megabytes
  CLIP_TYPES = %w[audio/mpeg audio/mp3 audio/wav audio/x-wav audio/wave].freeze

  pattr_initialize [:account!]

  def list
    return { connected: false, voices: [] } if hook.blank?

    live = fetch_pages
    { connected: true, voices: merge_voices(live) }
  end

  def enqueue(name:, clip:, consent:, tone: nil, persona: nil)
    raise Twilio::ConnectElevenlabsService::Error, 'voice_consent_required' unless consent
    raise Twilio::ConnectElevenlabsService::Error, 'voice_agent_credentials_missing' if hook.blank?
    raise Twilio::ConnectElevenlabsService::Error, 'voice_clip_invalid' unless clip_ok?(clip)

    voice = account.elevenlabs_voices.create!(
      name: name.to_s.strip,
      tone: tone.to_s.strip.presence,
      persona: persona.to_s.strip.presence,
      status: :pending,
      consent_statement: ElevenlabsVoice::CONSENT_SENTENCE,
      consent_accepted_at: Time.current
    )
    voice.clip.attach(clip)
    Twilio::CreateElevenlabsVoiceJob.perform_later(voice.id)
    voice
  end

  def create_remote(voice)
    return mark_failed(voice, 'voice_agent_credentials_missing') if hook.blank?

    response = upload_clip(voice)
    voice_id = created_voice_id(response)
    return fail_voice(voice, response) if voice_id.blank?

    save_created_voice(voice, voice_id)
  rescue StandardError => e
    mark_failed(voice, e.message) unless voice.ready? || voice.failed?
  ensure
    voice.clip.purge_later if voice.clip.attached?
  end

  def apply_voice(hook, agent_id, voice_id)
    before = agent_prompt(hook, agent_id)
    patch_voice(hook, agent_id, voice_id)
    after = agent_prompt(hook, agent_id)
    return if before['knowledge_base'] == after['knowledge_base'] && before['rag'] == after['rag']

    restore_knowledge(hook, agent_id, voice_id, before)
  end

  private

  def hook
    record = account.hooks.find_by(app_id: 'elevenlabs', status: 'enabled')
    record if record&.settings&.dig('api_key').present?
  end

  def fetch_pages
    voices = []
    token = nil
    MAX_PAGES.times do
      body = voice_page(token)
      voices.concat(Array(body['voices']).select { |row| row.is_a?(Hash) })
      token = body['next_page_token']
      break unless body['has_more'] && token.present?
    end
    voices
  end

  def voice_page(token)
    query = { page_size: 100 }
    query[:next_page_token] = token if token.present?
    response = HTTParty.get(VOICES_URL, headers: api_headers, query: query, timeout: 20)
    raise Twilio::ConnectElevenlabsService::Error, "ElevenLabs: #{response.code}" unless response.success?

    response.parsed_response.is_a?(Hash) ? response.parsed_response : {}
  end

  def merge_voices(live)
    locals = account.elevenlabs_voices.order(created_at: :desc).to_a
    seen = live.pluck('voice_id')
    merged = live.map { |row| Twilio::ElevenlabsVoiceRow.live(row, locals.find { |item| item.voice_id == row['voice_id'] }) }
    locals.each { |item| merged.unshift(Twilio::ElevenlabsVoiceRow.local(item)) unless seen.include?(item.voice_id) }
    merged
  end

  def clip_ok?(clip)
    return false if clip.blank? || clip.size > MAX_CLIP_BYTES

    type = clip.content_type.to_s
    CLIP_TYPES.include?(type) || clip.original_filename.to_s.match?(/\.(mp3|wav)\z/i)
  end

  def upload_clip(voice)
    voice.clip.open do |file|
      HTTParty.post(
        ADD_URL,
        headers: api_headers,
        multipart: true,
        body: upload_fields(voice, file),
        timeout: 120
      )
    end
  end

  def upload_fields(voice, file)
    fields = { name: voice.name, files: file }
    fields[:description] = voice.persona if voice.persona.present?
    fields[:labels] = { description: voice.tone }.to_json if voice.tone.present?
    fields
  end

  def fetch_voice(voice_id)
    response = HTTParty.get("#{VOICE_URL}/#{voice_id}", headers: api_headers, timeout: 20)
    return {} unless response.success? && response.parsed_response.is_a?(Hash)

    response.parsed_response
  end

  def fail_voice(voice, response)
    mark_failed(voice, "ElevenLabs: #{response.code}")
  end

  def mark_failed(voice, message)
    voice.update!(status: :failed, error_message: message.to_s.truncate(180))
  end

  def created_voice_id(response)
    return unless response.success? && response.parsed_response.is_a?(Hash)

    response.parsed_response['voice_id'].presence
  end

  def save_created_voice(voice, voice_id)
    details = fetch_voice(voice_id)
    voice.update!(
      voice_id: voice_id,
      status: :ready,
      preview_url: details['preview_url'],
      requires_verification: details['requires_verification'] == true,
      error_message: nil
    )
  end

  def agent_prompt(hook, agent_id)
    response = HTTParty.get("#{AGENTS_URL}/#{agent_id}", headers: api_headers_for(hook), timeout: 20)
    raise Twilio::ConnectElevenlabsService::Error, "ElevenLabs: #{response.code}" unless response.success?

    body = response.parsed_response
    body.is_a?(Hash) ? (body.dig('conversation_config', 'agent', 'prompt') || {}) : {}
  end

  def patch_voice(hook, agent_id, voice_id)
    response = HTTParty.patch(
      "#{AGENTS_URL}/#{agent_id}",
      headers: json_headers(hook),
      body: { conversation_config: { tts: { voice_id: voice_id } } }.to_json,
      timeout: 20
    )
    return if response.success?

    raise Twilio::ConnectElevenlabsService::Error, "ElevenLabs: #{response.code}"
  end

  def restore_knowledge(hook, agent_id, voice_id, before)
    prompt = { knowledge_base: before['knowledge_base'], rag: before['rag'] }.compact
    response = HTTParty.patch(
      "#{AGENTS_URL}/#{agent_id}",
      headers: json_headers(hook),
      body: { conversation_config: { tts: { voice_id: voice_id }, agent: { prompt: prompt } } }.to_json,
      timeout: 20
    )
    return if response.success?

    raise Twilio::ConnectElevenlabsService::Error, "ElevenLabs: #{response.code}"
  end

  def api_headers
    api_headers_for(hook)
  end

  def api_headers_for(record)
    { 'xi-api-key' => record.settings['api_key'] }
  end

  def json_headers(record)
    api_headers_for(record).merge('Content-Type' => 'application/json')
  end
end
