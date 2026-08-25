# Phase 3 (flag: reputation_demo_surfaces): transcribe a video testimonial and
# run ONE LLM pass over the transcript → summary / topics / sentiment /
# marketing score / quotable line / suggested reply (E1-E6).
#
# One OpenAI client (via LegacyBaseOpenAiService) does both the transcription
# and the chat completion — no new client, no new dependency, no new provider.
# Honest by design: returns { error: ... } (blank AI fields) when there's no
# audio, no key, or the file is too large — never fabricated insight.
class Reputation::VideoInsightsService < Llm::LegacyBaseOpenAiService
  TRANSCRIBE_MODEL = 'gpt-4o-mini-transcribe'.freeze
  # OpenAI transcription hard-caps at 25MB decimal. Our upload cap is 100MB, so a
  # long video can exceed this — skip transcription rather than 413.
  # ponytail: extract+downsample audio if large videos need transcripts.
  TRANSCRIBE_BYTE_LIMIT = 25_000_000

  def initialize(testimonial:)
    super()
    @testimonial = testimonial
  end

  def generate
    return { 'error' => 'No video attached' } unless @testimonial.video.attached?
    return { 'error' => 'Video too large to transcribe (25MB max)' } if too_large?

    transcript = transcribe
    return { 'error' => 'Empty transcript' } if transcript.blank?

    analyze(transcript).merge('transcript' => transcript, 'processed_at' => Time.current.to_i)
  rescue StandardError => e
    Rails.logger.error("Video insights failed for testimonial #{@testimonial.id}: #{e.message}")
    { 'error' => e.message }
  end

  private

  def too_large?
    @testimonial.video.blob.byte_size > TRANSCRIBE_BYTE_LIMIT
  end

  # OpenAI transcription accepts webm/mp4 directly, so the video blob is the audio source.
  def transcribe
    blob = @testimonial.video.blob
    temp_dir = Rails.root.join('tmp/uploads/video-testimonials')
    FileUtils.mkdir_p(temp_dir)
    path = File.join(temp_dir, "#{blob.key}-#{blob.filename}")
    File.open(path, 'wb') { |f| blob.open { |bf| IO.copy_stream(bf, f) } }

    File.open(path, 'rb') do |file|
      @client.audio.transcribe(parameters: { model: TRANSCRIBE_MODEL, file: file, temperature: 0.0 })['text']
    end
  ensure
    FileUtils.rm_f(path) if path
  end

  def analyze(transcript)
    response = @client.chat(parameters: {
                              model: @model,
                              temperature: 0.2,
                              response_format: { type: 'json_object' },
                              messages: [{ role: 'user', content: prompt(transcript) }]
                            })
    parsed = JSON.parse(sanitize_json_response(response.dig('choices', 0, 'message', 'content')))
    {
      'summary' => parsed['summary'].to_s,
      'topics' => Array(parsed['topics']).map(&:to_s).first(6),
      'sentiment' => parsed['sentiment'].to_i.clamp(0, 100),
      'marketing_score' => parsed['marketing_score'].to_i.clamp(0, 100),
      'quotable' => parsed['quotable'].to_s,
      'suggested_reply' => parsed['suggested_reply'].to_s
    }
  end

  def prompt(transcript)
    <<~PROMPT
      You are a marketing analyst reviewing a customer video testimonial transcript.
      Respond ONLY with JSON, no prose:
      {"summary": "<2-3 sentence summary>",
       "topics": ["<3-6 short topic tags>"],
       "sentiment": <integer 0-100, how positive>,
       "marketing_score": <integer 0-100, how usable as marketing content>,
       "quotable": "<the single most quotable sentence, verbatim from the transcript>",
       "suggested_reply": "<a brief, warm thank-you reply under 60 words>"}

      Transcript:
      #{transcript.to_s.truncate(6000)}
    PROMPT
  end
end
