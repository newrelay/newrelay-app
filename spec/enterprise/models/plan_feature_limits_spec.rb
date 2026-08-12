require 'rails_helper'

RSpec.describe 'Plan Feature Limits & Enforcement', type: :model do
  let!(:account) { create(:account) }

  before do
    PlanFeatureLimit.destroy_all
    # Seed standard matrices for the tests
    %w[hobby standard business enterprise].each do |plan_key|
      PlanFeatureLimit.create!(plan_key: plan_key, feature_key: 'seats', enabled: true, limit_value: plan_key == 'hobby' ? 1 : (plan_key == 'standard' ? 5 : nil))
      PlanFeatureLimit.create!(plan_key: plan_key, feature_key: 'contacts', enabled: true, limit_value: plan_key == 'hobby' ? 2 : (plan_key == 'standard' ? 10 : nil))
      PlanFeatureLimit.create!(plan_key: plan_key, feature_key: 'conversations', enabled: true, limit_value: plan_key == 'hobby' ? 2 : nil)
      PlanFeatureLimit.create!(plan_key: plan_key, feature_key: 't3_subaccounts', enabled: true, limit_value: plan_key == 'hobby' ? 0 : (plan_key == 'standard' ? 3 : (plan_key == 'business' ? 25 : nil)))
      PlanFeatureLimit.create!(plan_key: plan_key, feature_key: 'automations', enabled: true, limit_value: plan_key == 'hobby' ? 3 : (plan_key == 'standard' ? 15 : nil))
      PlanFeatureLimit.create!(plan_key: plan_key, feature_key: 'white_labeling', enabled: plan_key.in?(%w[business enterprise]))
    end
  end

  describe 'ReconcilePlanFeaturesService' do
    context 'when plan is Hobby' do
      before do
        account.update!(custom_attributes: { 'plan_name' => 'Hobby' })
        Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform
      end

      it 'applies correct Hobby feature limits to the account' do
        expect(account.limits['agents']).to eq(1)
        expect(account.limits['contacts']).to eq(2)
        expect(account.limits['conversations']).to eq(2)
        expect(account.limits['t3_subaccounts']).to eq(0)
        expect(account.limits['automations']).to eq(3)
        expect(account.feature_enabled?('white_labeling')).to be(false)
      end
    end

    context 'when plan is Business' do
      before do
        account.update!(custom_attributes: { 'plan_name' => 'Business' })
        Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform
      end

      it 'applies Business limits (nil limits mean unlimited)' do
        expect(account.limits['agents']).to be_nil
        expect(account.limits['contacts']).to be_nil
        expect(account.limits['conversations']).to be_nil
        expect(account.limits['t3_subaccounts']).to eq(25)
        expect(account.feature_enabled?('white_labeling')).to be(true)
      end
    end

    context 'when plan is Enterprise with active contract overrides' do
      let!(:user) { create(:user, account: account, role: 'administrator') }
      let!(:contract) do
        EnterpriseContract.create!(
          account: account,
          negotiated_price: 1500.0,
          currency: 'USD',
          billing_interval: 'annual',
          collection_method: 'send_invoice',
          contract_start_date: 1.day.ago.to_date,
          contract_end_date: 1.year.from_now.to_date,
          negotiated_limit_overrides: { 'seats' => 8, 'contacts' => 500 },
          negotiated_by_user: user
        )
      end

      before do
        account.update!(custom_attributes: { 'plan_name' => 'Enterprise' })
        Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform
      end

      it 'applies contract limit overrides and baseline enterprise features' do
        expect(account.limits['agents']).to eq(8)
        expect(account.limits['contacts']).to eq(500)
        expect(account.limits['conversations']).to be_nil # from baseline
        expect(account.feature_enabled?('white_labeling')).to be(true)
      end
    end
  end

  describe 'Limit Enforcement validations' do
    describe 'Seats (seats/agents) limit' do
      before do
        account.update!(limits: { 'agents' => 1 })
      end

      it 'allows creating agent when count is below limit' do
        expect(account.users.count).to eq(0)
        user = AgentBuilder.new(email: 'newagent@test.com', name: 'Agent', inviter: create(:user), account: account).perform
        expect(user.persisted?).to be(true)
      end

      it 'raises error when trying to create agent exceeding limit' do
        # Create first agent to reach limit
        AgentBuilder.new(email: 'agent1@test.com', name: 'Agent 1', inviter: create(:user), account: account).perform
        expect(account.users.count).to eq(1)

        # Attempt to create second agent
        expect {
          AgentBuilder.new(email: 'agent2@test.com', name: 'Agent 2', inviter: create(:user), account: account).perform
        }.to raise_error(Concerns::EnforcesAccountLimit::LimitExceededError)
      end
    end

    describe 'Contacts limit' do
      before do
        account.update!(limits: { 'contacts' => 1 })
      end

      it 'allows creating contact within limit' do
        contact = Contact.create(account: account, name: 'Contact 1', email: 'c1@test.com')
        expect(contact.persisted?).to be(true)
      end

      it 'adds validation error on create when exceeding contacts limit' do
        Contact.create!(account: account, name: 'Contact 1', email: 'c1@test.com')

        contact2 = Contact.create(account: account, name: 'Contact 2', email: 'c2@test.com')
        expect(contact2.persisted?).to be(false)
        expect(contact2.errors[:base]).to include('Contact limit of 1 has been reached for this account')
      end
    end

    describe 'Conversations limit' do
      before do
        account.update!(limits: { 'conversations' => 1 })
      end

      it 'allows creating conversation within limit' do
        inbox = create(:inbox, account: account)
        contact = create(:contact, account: account)
        contact_inbox = create(:contact_inbox, contact: contact, inbox: inbox)
        conv = Conversation.create(account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
        expect(conv.persisted?).to be(true)
      end

      it 'adds validation error on create when exceeding monthly conversations limit' do
        inbox = create(:inbox, account: account)
        contact = create(:contact, account: account)
        contact_inbox = create(:contact_inbox, contact: contact, inbox: inbox)

        Conversation.create!(account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)

        conv2 = Conversation.create(account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
        expect(conv2.persisted?).to be(false)
        expect(conv2.errors[:base]).to include('Monthly conversation limit of 1 has been reached for this account')
      end
    end

    describe 'Automations limit' do
      before do
        account.update!(limits: { 'automations' => 1 })
      end

      it 'allows creating automation rule within limit' do
        rule = AutomationRule.create(account: account, name: 'Rule 1', event_name: 'conversation_created', conditions: [], actions: [])
        expect(rule.persisted?).to be(true)
      end

      it 'adds validation error when exceeding automations limit' do
        AutomationRule.create!(account: account, name: 'Rule 1', event_name: 'conversation_created', conditions: [], actions: [])

        rule2 = AutomationRule.create(account: account, name: 'Rule 2', event_name: 'conversation_created', conditions: [], actions: [])
        expect(rule2.persisted?).to be(false)
        expect(rule2.errors[:base]).to include('Automation rule limit of 1 has been reached for this account')
      end
    end

    describe 'Reseller & sub-accounts validations' do
      let!(:parent) { create(:account, is_reseller: true, limits: { 't3_subaccounts' => 1 }) }

      it 'allows adding child to parent within parent limits' do
        child = Account.create(name: 'Child 1', parent: parent)
        expect(child.persisted?).to be(true)
        expect(child.parent_id).to eq(parent.id)
      end

      it 'adds validation error when child count exceeds parent limits' do
        Account.create!(name: 'Child 1', parent: parent)

        child2 = Account.create(name: 'Child 2', parent: parent)
        expect(child2.persisted?).to be(false)
        expect(child2.errors[:parent_id]).to include("exceeds the reseller parent's sub-account limit of 1")
      end

      it 'prevents setting is_reseller to true if limits on t3_subaccounts is 0 (Hobby)' do
        hobby_account = create(:account, limits: { 't3_subaccounts' => 0 })
        hobby_account.is_reseller = true
        expect(hobby_account.save).to be(false)
        expect(hobby_account.errors[:is_reseller]).to include('is not allowed on this plan tier')
      end
    end
  end
end
