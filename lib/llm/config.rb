require 'ruby_llm'
require 'openssl'

module Llm::Config
  DEFAULT_MODEL = 'gpt-4.1-mini'.freeze

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
      context = RubyLLM.context do |config|
        config.openai_api_key = api_key
        config.openai_api_base = api_base
        config.openrouter_api_key = api_key
        config.anthropic_api_key = api_key
        config.gemini_api_key = api_key
        config.deepseek_api_key = api_key

        if api_base.present? && !api_base.include?('api.openai.com')
          if api_base.include?('openrouter.ai')
            normalized_base = api_base.end_with?('/v1') ? api_base : "#{api_base.sub(/\/api$/, '')}/api/v1"
            config.openai_api_base = normalized_base
            config.openrouter_api_base = normalized_base
          else
            config.openai_api_base = api_base
            config.openrouter_api_base = api_base
          end
          config.anthropic_api_base = api_base
          config.gemini_api_base = api_base
          config.deepseek_api_base = api_base
        end
      end

      yield context
    end

    private

    def configure_ruby_llm
      RubyLLM.configure do |config|
        config.openai_api_key = system_api_key if system_api_key.present?
        config.openrouter_api_key = system_api_key if system_api_key.present?
        config.anthropic_api_key = system_api_key if system_api_key.present?
        config.gemini_api_key = system_api_key if system_api_key.present?
        config.deepseek_api_key = system_api_key if system_api_key.present?

        if openai_endpoint.present?
          endpoint = openai_endpoint.chomp('/')
          if endpoint.include?('openrouter.ai')
            normalized_endpoint = endpoint.end_with?('/v1') ? endpoint : "#{endpoint.sub(/\/api$/, '')}/api/v1"
            config.openai_api_base = normalized_endpoint
            config.openrouter_api_base = normalized_endpoint
          else
            config.openai_api_base = endpoint
            config.openrouter_api_base = endpoint
          end
          config.anthropic_api_base = endpoint
          config.gemini_api_base = endpoint
          config.deepseek_api_base = endpoint
        end

        config.model_registry_file = Rails.root.join('config/llm_models.json').to_s
        config.logger = Rails.logger
      end
    end

    def system_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    end

    def openai_endpoint
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    end
  end
end
