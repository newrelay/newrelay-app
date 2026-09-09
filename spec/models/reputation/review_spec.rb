require 'rails_helper'

RSpec.describe Reputation::Review, type: :model do
  let(:account) { create(:account) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:reputation_integration) }
    it { is_expected.to have_one(:reputation_review_reply).dependent(:destroy) }
  end

  describe 'validations' do
    subject { create(:reputation_review, account: account) }

    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:rating) }
    it { is_expected.to validate_inclusion_of(:rating).in_range(1..5) }
    it { is_expected.to validate_uniqueness_of(:external_id).scoped_to(:account_id, :provider) }
  end

  describe 'enums' do
    it {
      expect(subject).to define_enum_for(:provider).with_values(
        google: 'google', facebook: 'facebook', agoda: 'agoda', airbnb: 'airbnb', aliexpress: 'aliexpress',
        amazon: 'amazon', angi: 'angi', apple_app_store: 'apple_app_store', avvo: 'avvo', custom: 'custom'
      ).backed_by_column_of_type(:string)
    }

    it {
      expect(subject).to define_enum_for(:status).with_values(pending: 'pending', replied: 'replied',
                                                              ignored: 'ignored').backed_by_column_of_type(:string)
    }
  end
end
