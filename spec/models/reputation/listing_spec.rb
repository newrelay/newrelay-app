require 'rails_helper'

RSpec.describe Reputation::Listing, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:reputation_integrations).dependent(:nullify) }
    it { is_expected.to have_many(:reputation_reviews).through(:reputation_integrations) }
    it { is_expected.to have_many(:listing_members).dependent(:destroy) }
    it { is_expected.to have_many(:members).through(:listing_members) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
  end
end
