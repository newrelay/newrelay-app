require 'rails_helper'

RSpec.describe Reputation::AiDraftService do
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:mock_response) { instance_double(RubyLLM::Message, content: "  Thanks for the feedback, we'll fix this.  ") }
  let(:review) { double(provider: 'google', rating: 2, body: 'Service was slow') } # rubocop:disable RSpec/VerifiedDoubles

  before do
    allow(RubyLLM).to receive(:chat).and_return(mock_chat)
    allow(mock_chat).to receive(:with_temperature).and_return(mock_chat)
    allow(mock_chat).to receive(:ask).and_return(mock_response)
  end

  describe '#generate' do
    it 'returns the stripped LLM reply' do
      result = described_class.new(review: review).generate

      expect(result).to eq("Thanks for the feedback, we'll fix this.")
    end

    it 'includes the review platform, rating, and body in the prompt' do
      described_class.new(review: review).generate

      expect(mock_chat).to have_received(:ask) do |prompt|
        expect(prompt).to include('Platform: google')
        expect(prompt).to include('Rating: 2/5')
        expect(prompt).to include('Service was slow')
      end
    end

    it 'falls back to a placeholder when the review has no body' do
      empty_review = double(provider: 'facebook', rating: 1, body: nil) # rubocop:disable RSpec/VerifiedDoubles

      described_class.new(review: empty_review).generate

      expect(mock_chat).to have_received(:ask).with(a_string_including('(No text provided)'))
    end
  end
end
