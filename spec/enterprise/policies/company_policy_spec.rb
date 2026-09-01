require 'rails_helper'

RSpec.describe CompanyPolicy, type: :policy do
  subject(:company_policy) { described_class }

  let(:account) { create(:account) }
  let(:administrator) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account) }
  let(:company) { create(:company, account: account) }

  let(:administrator_context) { { user: administrator, account: account, account_user: account.account_users.first } }
  let(:agent_context) { { user: agent, account: account, account_user: account.account_users.first } }

  def context_for(permissions)
    user = create(:user)
    custom_role = create(:custom_role, account: account, permissions: permissions)
    account_user = create(:account_user, user: user, account: account, role: :agent, custom_role: custom_role)
    { user: user, account: account, account_user: account_user }
  end

  permissions :index?, :show?, :create?, :update? do
    context 'when administrator' do
      it { expect(company_policy).to permit(administrator_context, company) }
    end

    context 'when agent' do
      it { expect(company_policy).to permit(agent_context, company) }
    end

    context 'when company_manage' do
      it { expect(company_policy).to permit(context_for(['company_manage']), company) }
    end

    context 'when custom role without company_manage' do
      it { expect(company_policy).not_to permit(context_for(['contact_manage']), company) }
    end
  end

  permissions :destroy? do
    context 'when administrator' do
      it { expect(company_policy).to permit(administrator_context, company) }
    end

    context 'when agent' do
      it { expect(company_policy).not_to permit(agent_context, company) }
    end

    context 'when company_manage' do
      it { expect(company_policy).to permit(context_for(['company_manage']), company) }
    end

    context 'when custom role without company_manage' do
      it { expect(company_policy).not_to permit(context_for(['contact_manage']), company) }
    end
  end
end
