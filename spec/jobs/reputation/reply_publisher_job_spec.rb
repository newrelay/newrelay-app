require 'rails_helper'

RSpec.describe Reputation::ReplyPublisherJob, type: :job do
  let(:account) { create(:account) }
  let(:integration) { create(:reputation_integration, account: account, provider: 'google') }
  let(:review) { create(:reputation_review, account: account, reputation_integration: integration, status: 'pending') }
  let(:reply) { Reputation::ReviewReply.create!(account: account, reputation_review: review, body: 'Thanks for the feedback!') }
  let(:adapter) { instance_double(Reputation::Providers::Google, publish_reply: true) }

  before do
    allow(Reputation::Providers).to receive(:adapter_for).and_return(adapter)
  end

  it 'refreshes the google token before publishing' do
    expect_any_instance_of(Reputation::Integration).to receive(:refresh_token!) # rubocop:disable RSpec/AnyInstance

    described_class.perform_now(reply.id)
  end

  it 'publishes the reply body through the provider adapter for the review' do
    described_class.perform_now(reply.id)

    expect(adapter).to have_received(:publish_reply).with(an_instance_of(Reputation::Review), 'Thanks for the feedback!')
  end

  it 'marks the reply published and the review replied' do
    described_class.perform_now(reply.id)

    expect(reply.reload).to be_published
    expect(reply.published_at).to be_present
    expect(review.reload).to be_replied
  end

  it 'does not refresh the token for a non-google provider' do
    facebook_integration = create(:reputation_integration, account: account, provider: 'facebook')
    facebook_review = create(:reputation_review, account: account, reputation_integration: facebook_integration)
    facebook_reply = Reputation::ReviewReply.create!(account: account, reputation_review: facebook_review, body: 'Thanks!')

    expect_any_instance_of(Reputation::Integration).not_to receive(:refresh_token!) # rubocop:disable RSpec/AnyInstance

    described_class.perform_now(facebook_reply.id)
  end
end
