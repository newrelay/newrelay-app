require 'rails_helper'

RSpec.describe 'Exotel Integration Webhook API', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  
  before do
    # Seed required hooks
    create(:integrations_hook, :dyte, account: account)
    create(:integrations_hook, app_id: 'exotel', settings: {
      account_sid: 'mock_sid',
      api_key: 'mock_key',
      api_token: 'mock_token',
      subdomain: 'mock_subdomain',
      virtual_number: '+919999999999'
    }, account: account)
    create(:integrations_hook, app_id: 'elevenlabs', settings: { api_key: 'mock_key' }, account: account)
  end

  describe 'POST /api/v1/accounts/:account_id/integrations/exotel/incoming_call' do
    it 'creates a conversation and returns a valid XML response with greeting' do
      post "/api/v1/accounts/#{account.id}/integrations/exotel/incoming_call", params: {
        CallSid: 'call_123',
        From: '+918888888888',
        To: '+919999999999'
      }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/xml')
      expect(response.body).to include('<Response>')
      expect(response.body).to include('<Play>')
      expect(response.body).to include('<Record')

      # Check conversation created
      conversation = account.conversations.where("additional_attributes ->> 'call_sid' = ?", 'call_123').first
      expect(conversation).to_not be_nil
      expect(conversation.messages.count).to eq(1)
      expect(conversation.messages.first.content).to include('Welcome to Daksh')
    end

    it 'returns a bad request error if required parameters are missing' do
      post "/api/v1/accounts/#{account.id}/integrations/exotel/incoming_call", params: {}

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)['error']).to eq('Missing required CallSid or From parameters')
    end
  end

  describe 'POST /api/v1/accounts/:account_id/integrations/exotel/speech_callback' do
    it 'adds user message, runs AI response, and loops back with new Exotel XML instructions' do
      # Pre-create the conversation
      post "/api/v1/accounts/#{account.id}/integrations/exotel/incoming_call", params: {
        CallSid: 'call_123',
        From: '+918888888888',
        To: '+919999999999'
      }

      post "/api/v1/accounts/#{account.id}/integrations/exotel/speech_callback", params: {
        CallSid: 'call_123',
        From: '+918888888888',
        To: '+919999999999',
        Transcription: 'Tell me about Daksh AI features.'
      }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/xml')
      expect(response.body).to include('<Response>')
      expect(response.body).to include('<Play>')

      # Verify messages logged
      conversation = account.conversations.where("additional_attributes ->> 'call_sid' = ?", 'call_123').first
      expect(conversation.messages.pluck(:content)).to include('Tell me about Daksh AI features.')
      expect(conversation.messages.pluck(:content)).to include('Daksh AI is an advanced CRM platform featuring task boards, contacts management, corporate registries, and voice AI integrations.')
    end
  end
end
