require 'rails_helper'

RSpec.describe CustomRole, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:account_users).dependent(:nullify) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }

    it 'allows reputation_manage' do
      role = build(:custom_role, permissions: ['reputation_manage'])
      expect(role).to be_valid
    end

    it 'allows marketing_manage' do
      role = build(:custom_role, permissions: ['marketing_manage'])
      expect(role).to be_valid
    end
  end
end
