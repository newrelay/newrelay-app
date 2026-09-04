require 'rails_helper'

RSpec.describe Inboxes::SyncSocialAvatarService do
  before do
    stub_request(:post, /graph.facebook.com/)
  end

  let(:account) { create(:account) }

  it 'returns the attached avatar without fetching' do
    channel = create(:channel_instagram, account: account)
    inbox = channel.inbox
    inbox.avatar.attach(
      io: Rails.root.join('spec/assets/avatar.png').open,
      filename: 'avatar.png',
      content_type: 'image/png'
    )

    expect(HTTParty).not_to receive(:get)
    expect(described_class.new(inbox: inbox).perform).to eq(inbox.reload.avatar_url)
  end

  it 'skips mock Instagram channels' do
    channel = create(:channel_instagram, account: account, access_token: 'mock-abc')

    expect(HTTParty).not_to receive(:get)
    expect(described_class.new(inbox: channel.inbox).perform).to eq('')
  end

  it 'downloads the Instagram profile picture' do
    channel = create(:channel_instagram, account: account)
    stub_request(:get, %r{graph\.instagram\.com/.*/me})
      .to_return(
        status: 200,
        body: { profile_picture_url: 'https://cdn.example/ig.jpg' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    expect(Avatar::AvatarFromUrlJob).to receive(:perform_now).with(channel.inbox, 'https://cdn.example/ig.jpg')
    described_class.new(inbox: channel.inbox).perform
  end

  it 'downloads the Facebook page picture' do
    channel = create(:channel_facebook_page, account: account)
    stub_request(:get, %r{graph\.facebook\.com/#{channel.page_id}/picture})
      .to_return(
        status: 200,
        body: { data: { url: 'https://cdn.example/fb.jpg' } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    expect(Avatar::AvatarFromUrlJob).to receive(:perform_now).with(channel.inbox, 'https://cdn.example/fb.jpg')
    described_class.new(inbox: channel.inbox).perform
  end
end
