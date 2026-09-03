require 'rails_helper'

RSpec.describe CommentAutomation::PostMockCommentService do
  let(:account) { create(:account) }

  def perform(text: 'What is the PRICE?', name: 'You')
    described_class.new(account: account, text: text, name: name).perform
  end

  it 'raises when mock mode is off' do
    with_modified_env(COMMENT_AUTOMATION_PROVIDER: '') do
      expect { perform }.to raise_error(described_class::Error)
    end
  end

  context 'when COMMENT_AUTOMATION_PROVIDER=mock' do
    around do |example|
      with_modified_env(COMMENT_AUTOMATION_PROVIDER: 'mock') { example.run }
    end

    it 'raises when the mock channel is not connected' do
      expect { perform }.to raise_error(described_class::Error)
    end

    context 'with a connected mock channel' do
      before do
        CommentAutomation::ConnectMockChannelService.new(
          account: account,
          url: 'https://www.instagram.com/p/mock-summer-sale/',
          name: 'Instagram Shop'
        ).perform
      end

      it 'matches PRICE, posts a public reply, and marks the DM sent' do
        result = perform

        expect(result[:matched]).to be true
        expect(result[:comment]).to eq 'What is the PRICE?'
        expect(result[:public_reply]).to eq 'Thanks — check your DMs for the offer!'
        expect(result[:dm]).to include('40% off')
        expect(result[:status]).to eq 'dm_sent'
      end

      it 'returns matched false when the comment has no keyword' do
        result = perform(text: 'Nice photo!')

        expect(result[:matched]).to be false
        expect(result[:public_reply]).to be_nil
      end
    end
  end
end
