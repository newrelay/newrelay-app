require 'rails_helper'

RSpec.describe Reputation::Integration, type: :model do
  let(:account) { create(:account) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:listing).optional }
    it { is_expected.to have_many(:reputation_reviews).dependent(:destroy) }
  end

  describe 'validations' do
    subject { create(:reputation_integration, account: account) }

    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:location_id) }
    it { is_expected.to validate_uniqueness_of(:location_id).scoped_to(:account_id, :provider) }
  end

  describe 'enums' do
    it {
      expect(subject).to define_enum_for(:provider).with_values(
        google: 'google', facebook: 'facebook', agoda: 'agoda', airbnb: 'airbnb', aliexpress: 'aliexpress',
        amazon: 'amazon', angi: 'angi', apple_app_store: 'apple_app_store', avvo: 'avvo', custom: 'custom'
      ).backed_by_column_of_type(:string)
    }

    it { is_expected.to define_enum_for(:status).with_values(active: 'active', disconnected: 'disconnected').backed_by_column_of_type(:string) }
  end

  describe '#refresh_token!' do
    let(:integration) do
      create(:reputation_integration, account: account, provider: 'google', refresh_token: 'rtoken', token_expires_at: 1.minute.from_now)
    end

    it 'does not call the token endpoint for a non-google provider' do
      facebook_integration = create(:reputation_integration, account: account, provider: 'facebook',
                                                             refresh_token: 'rtoken', token_expires_at: 1.minute.from_now)

      expect(HTTParty).not_to receive(:post)
      facebook_integration.refresh_token!
    end

    it 'does not call the token endpoint when there is no refresh token' do
      integration.update_column(:refresh_token, nil)

      expect(HTTParty).not_to receive(:post)
      integration.refresh_token!
    end

    it 'does not call the token endpoint when the current token is not close to expiring' do
      integration.update!(token_expires_at: 1.hour.from_now)

      expect(HTTParty).not_to receive(:post)
      integration.refresh_token!
    end

    it 'updates the access token and expiry on a successful refresh' do
      stub_request(:post, 'https://oauth2.googleapis.com/token')
        .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                   body: { access_token: 'new-token', expires_in: 3600 }.to_json)

      integration.refresh_token!

      expect(integration.access_token).to eq('new-token')
      expect(integration.token_expires_at).to be_within(5.seconds).of(3600.seconds.from_now)
    end

    it 'disconnects the integration when Google reports an invalid_grant error' do
      stub_request(:post, 'https://oauth2.googleapis.com/token')
        .to_return(status: 400, headers: { 'Content-Type' => 'application/json' }, body: { error: 'invalid_grant' }.to_json)
      allow(Rails.logger).to receive(:error)

      integration.refresh_token!

      expect(integration.reload).to be_disconnected
    end

    it 'logs and leaves the integration active for other failures' do
      stub_request(:post, 'https://oauth2.googleapis.com/token').to_return(status: 500, body: 'boom')
      expect(Rails.logger).to receive(:error)

      integration.refresh_token!

      expect(integration.reload).to be_active
    end
  end
end
