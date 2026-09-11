require 'ruby_llm'
require 'openssl'

module Llm::Config
  DEFAULT_MODEL = 'gpt-4.1-mini'.freeze
  OPENAI_API_BASE = 'https://api.openai.com/v1'.freeze

  class << self
    def initialized?
      @initialized ||= false
    end

    def initialize!
      return if @initialized

      if Rails.env.development? || Rails.env.test?
        OpenSSL::SSL.send(:remove_const, :VERIFY_PEER)
        OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE)
      end

      configure_ruby_llm
      @initialized = true
    end

    def reset!
      @initialized = false
    end

    def with_api_key(api_key, api_base: nil)
      initialize!
      key = api_key.to_s.strip
      resolved_base = resolve_api_base(key, api_base)

      context = RubyLLM.context do |config|
        apply_provider_config(config, key: key, api_base: resolved_base)
      end

      yield context
    end

    def resolve_api_base(api_key, api_base)
      key = api_key.to_s.strip
      base = normalize_api_base(api_base)

      if openrouter_host?(base) && openai_secret?(key)
        Rails.logger.warn(
          '[llm] CAPTAIN_OPEN_AI_API_KEY looks like an OpenAI key, but CAPTAIN_OPEN_AI_ENDPOINT is OpenRouter. ' \
          'Routing to https://api.openai.com/v1 so AI Summary can use the OpenAI key.'
        )
        return OPENAI_API_BASE
      end

      return base if base.present?

      OPENAI_API_BASE
    end

    private

    def configure_ruby_llm
      RubyLLM.configure do |config|
        key = system_api_key.to_s.strip
        apply_provider_config(config, key: key, api_base: resolve_api_base(key, openai_endpoint))
        config.model_registry_file = Rails.root.join('config/llm_models.json').to_s
        config.logger = Rails.logger
      end
    end

    def apply_provider_config(config, key:, api_base:)
      config.openai_api_key = key.presence
      config.openai_api_base = api_base

      if openrouter_host?(api_base) && key.present?
        config.openrouter_api_key = key
        config.openrouter_api_base = api_base
      else
        config.openrouter_api_key = nil
        config.openrouter_api_base = nil
      end
    end

    def normalize_api_base(api_base)
      endpoint = api_base.to_s.strip.presence
      return nil if endpoint.blank?

      endpoint = endpoint.chomp('/')
      if openrouter_host?(endpoint)
        return endpoint if endpoint.end_with?('/v1')

        return "#{endpoint.sub(%r{/api$}, '')}/api/v1"
      end

      endpoint.end_with?('/v1') ? endpoint : "#{endpoint}/v1"
    end

    def openrouter_host?(url)
      url.to_s.include?('openrouter.ai')
    end

    def openai_secret?(key)
      stripped = key.to_s.strip
      stripped.start_with?('sk-') && !stripped.start_with?('sk-or-')
    end

    def system_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    end

    def openai_endpoint
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    end
  end
end
