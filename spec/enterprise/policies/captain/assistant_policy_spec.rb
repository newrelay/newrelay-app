# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::AssistantPolicy, type: :policy do
  subject(:assistant_policy) { described_class }

  let(:account) { create(:account) }
  let(:administrator) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:administrator_context) { { user: administrator, account: account, account_user: account.account_users.first } }
  let(:agent_context) { { user: agent, account: account, account_user: account.account_users.first } }

  def context_for(permissions)
    user = create(:user)
    custom_role = create(:custom_role, account: account, permissions: permissions)
    account_user = create(:account_user, user: user, account: account, role: :agent, custom_role: custom_role)
    { user: user, account: account, account_user: account_user }
  end

  permissions :index?, :show?, :playground?, :tools?, :create?, :update?, :destroy?, :sync? do
    context 'when administrator' do
      it { expect(assistant_policy).to permit(administrator_context, assistant) }
    end

    context 'when agent' do
      it { expect(assistant_policy).not_to permit(agent_context, assistant) }
    end

    context 'when captain_manage' do
      it { expect(assistant_policy).to permit(context_for(['captain_manage']), assistant) }
    end

    context 'when custom role without captain_manage' do
      it { expect(assistant_policy).not_to permit(context_for(['contact_manage']), assistant) }
    end
  end
end
