require 'rails_helper'

RSpec.describe Llm::Config do
  after { described_class.reset! }

  describe '.resolve_api_base' do
    it 'sends OpenAI secrets to OpenAI even when the endpoint is OpenRouter' do
      expect(
        described_class.resolve_api_base('sk-proj-example', 'https://openrouter.ai/api/v1')
      ).to eq('https://api.openai.com/v1')
    end

    it 'keeps OpenRouter secrets on OpenRouter' do
      expect(
        described_class.resolve_api_base('sk-or-v1-example', 'https://openrouter.ai/api')
      ).to eq('https://openrouter.ai/api/v1')
    end

    it 'uses the OpenAI host when no endpoint is set' do
      expect(described_class.resolve_api_base('sk-proj-example', nil)).to eq('https://api.openai.com/v1')
    end
  end

  describe '.with_api_key' do
    it 'does not mark OpenRouter as configured for an OpenAI secret' do
      described_class.with_api_key('sk-proj-example', api_base: 'https://openrouter.ai/api/v1') do |context|
        expect(context.config.openai_api_base).to eq('https://api.openai.com/v1')
        expect(context.config.openrouter_api_key).to be_blank
      end
    end

    it 'configures OpenRouter when the secret is an OpenRouter key' do
      described_class.with_api_key('sk-or-v1-example', api_base: 'https://openrouter.ai/api/v1') do |context|
        expect(context.config.openai_api_base).to eq('https://openrouter.ai/api/v1')
        expect(context.config.openrouter_api_key).to eq('sk-or-v1-example')
      end
    end
  end
end
