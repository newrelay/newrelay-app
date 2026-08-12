class Captain::Llm::BrandColorGeneratorService < Captain::BaseTaskService
  RESPONSE_SCHEMA = Captain::Llm::BrandColorGeneratorSchema

  pattr_initialize [:account!, :url, :image, :prompt]

  def perform
    return { error: 'No input provided' } unless url.present? || image.present? || prompt.present?
    
    response = make_api_call(model: model_to_use, messages: messages, schema: RESPONSE_SCHEMA)
    return response if response[:error]

    # Return the extracted options
    options = response[:message].is_a?(Hash) ? (response[:message]['options'] || response[:message][:options]) : []
    { options: options }
  end

  private

  def messages
    content_array = []
    
    if prompt.present?
      content_array << { type: "text", text: "Text hint/prompt from user: #{prompt}" }
    end

    if url.present?
      begin
        crawler = Captain::Tools::SimplePageCrawlService.new(url)
        content_array << { type: "text", text: "Website Content:\n#{crawler.fetch}" }
      rescue => e
        Rails.logger.error "[Captain] Failed to crawl URL for color generation: #{e.message}"
        content_array << { type: "text", text: "Website URL: #{url}" }
      end
    end

    if image.present?
      # image is expected to be a base64 data URI format string
      content_array << { type: "image_url", image_url: { url: image } }
    end

    if content_array.empty?
      content_array << { type: "text", text: "Generate a color palette for a modern brand." }
    end

    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: content_array }
    ]
  end

  def system_prompt
    <<~PROMPT
      You are an expert UI/UX designer. Your task is to generate exactly 3 distinct, beautiful, and highly accessible color palettes based on the user's provided website context, image, or text hint.

      CRITICAL CONTRAST & ACCESSIBILITY REQUIREMENTS:
      You MUST calculate and verify the contrast ratios of all options before outputting:
      1. The text color (:text) MUST have a WCAG 2.1 AA compliant contrast ratio of at least 4.5:1 against the background color (:background).
      2. The primary color (:primary) MUST have a contrast ratio of at least 3.0:1 against the background color (:background) for interactive UI elements.
      3. Ensure colors are harmonious, modern, and represent the brand inputs correctly while strictly adhering to these contrast rules.

      Provide a mix of vibrant, modern, and professional options.
    PROMPT
  end

  def event_name
    'brand_color_generator'
  end

  def llm_credential
    @llm_credential ||= system_llm_credential
  end

  def captain_tasks_enabled?
    true
  end

  # This is a one-off tool for branding settings run by account admins. 
  # We should probably count it towards usage, or maybe not if it's considered setup.
  # Let's not count it for now, similar to tagline generator.
  def counts_toward_usage?
    false
  end

  def model_to_use
    InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || GPT_MODEL
  end

  def build_follow_up_context?
    false
  end
end
