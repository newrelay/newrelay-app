class ElevenLabs
  BASE_URL = 'https://api.elevenlabs.io/v1'.freeze
  DEFAULT_VOICE_ID = '21m00Tcm4TlvDq8ikWAM'.freeze # Rachel

  def initialize(api_key, voice_id = nil)
    @api_key = api_key
    @voice_id = voice_id.presence || DEFAULT_VOICE_ID
  end

  def text_to_speech(text)
    public_dir = Rails.root.join('public', 'voice_agent')
    FileUtils.mkdir_p(public_dir)

    filename = "speech_#{SecureRandom.hex(8)}.mp3"
    file_path = public_dir.join(filename)

    if Rails.env.development? || Rails.env.test?
      # Write a tiny valid silent/click MP3 file so players don't crash
      # This is a tiny 1-frame MP3 base64 encoded
      tiny_mp3 = Base64.decode64('SUQzBAAAAAAAAFRYWFgAAAASAAADbWFqb3JfYnJhbmQAZGlzdABUWFhYAAAAEgAAA21pbm9yX3ZlcnNpb24AMABUWFhYAAAAHAAAAGNvbXBhdGlibGVfYnJhbmRzAGRpc3Rpc29tcDRhVElYWgAAAA8AAADHY29tLmFwcGxlLml0dW5lcwBNN2RhdGEAAAA8AAAAGGhkcl90eXBlAAAADAAAAAAAAAAAcGFyAAAADAAAAAEAAAABc2ZyYQAAAAwAAAABAAAAAHNkZXAAAADAAAAAEAAAAAE=')
      File.binwrite(file_path, tiny_mp3)
      return "/voice_agent/#{filename}"
    end

    response = HTTParty.post(
      "#{BASE_URL}/text-to-speech/#{@voice_id}",
      headers: {
        'xi-api-key' => @api_key,
        'Content-Type' => 'application/json',
        'accept' => 'audio/mpeg'
      },
      body: {
        text: text,
        model_id: 'eleven_monolingual_v1',
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.5
        }
      }.to_json
    )

    if response.success?
      File.binwrite(file_path, response.body)
      "/voice_agent/#{filename}"
    else
      Rails.logger.error "ElevenLabs API Error: #{response.body}"
      nil
    end
  end
end
