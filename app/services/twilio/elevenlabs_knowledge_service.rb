class Twilio::ElevenlabsKnowledgeService
  ELEVENLABS_KNOWLEDGE_URL = 'https://api.elevenlabs.io/v1/convai/knowledge-base/url'.freeze
  # ponytail: one page per document, capped so Connect stays inside the request. Raise the cap if a site needs more pages.
  MAX_PAGES = 15

  def initialize(inbox:, hook:, agent_id:)
    @inbox = inbox
    @hook = hook
    @agent_id = agent_id
  end

  def perform
    locators = website_documents.filter_map { |document| locator_for(document) }
    return if locators.empty?

    response = HTTParty.patch(
      "#{Twilio::ConnectElevenlabsService::ELEVENLABS_AGENTS_URL}/#{agent_id}",
      headers: json_headers,
      body: agent_body(locators).to_json,
      timeout: 20
    )
    return if response.success?

    raise Twilio::ConnectElevenlabsService::Error, "ElevenLabs: #{response.code}"
  end

  private

  attr_reader :inbox, :hook, :agent_id

  def website_documents
    return [] unless inbox.respond_to?(:captain_assistant) && inbox.captain_assistant

    inbox.captain_assistant.documents.available
         .where("external_link LIKE 'http://%' OR external_link LIKE 'https://%'")
         .limit(MAX_PAGES)
  end

  def locator_for(document)
    id = document.metadata&.[]('elevenlabs_knowledge_base_id').presence || create_document(document)
    return if id.blank?

    { type: 'url', id: id, name: document.name.presence || document.external_link, usage_mode: 'auto' }
  end

  def create_document(document)
    response = HTTParty.post(
      ELEVENLABS_KNOWLEDGE_URL,
      headers: json_headers,
      body: { url: document.external_link, name: document.name.presence || document.external_link }.to_json,
      timeout: 30
    )
    body = response.parsed_response
    id = body['id'] if response.success? && body.is_a?(Hash)
    return if id.blank?

    document.update!(metadata: (document.metadata || {}).merge('elevenlabs_knowledge_base_id' => id))
    id
  end

  def agent_body(locators)
    {
      conversation_config: {
        agent: {
          prompt: {
            prompt: 'You answer phone calls for this business. Answer from the attached website knowledge base. ' \
                    'If it does not contain the answer, say you do not have that information. Reply in short spoken sentences.',
            knowledge_base: locators,
            rag: { enabled: true }
          }
        }
      }
    }
  end

  def json_headers
    { 'xi-api-key' => hook.settings['api_key'], 'Content-Type' => 'application/json' }
  end
end
