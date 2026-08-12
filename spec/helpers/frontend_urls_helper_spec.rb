require 'rails_helper'

describe FrontendUrlsHelper do
  describe '#frontend_url' do
    context 'without query params' do
      it 'creates path correctly' do
        expect(helper.frontend_url('dashboard')).to eq 'http://test.host/app/dashboard'
      end
    end

    context 'with query params' do
      it 'creates path correctly' do
        expect(helper.frontend_url('dashboard', p1: 'p1', p2: 'p2')).to eq 'http://test.host/app/dashboard?p1=p1&p2=p2'
      end
    end

    context 'with custom domain configured on the user account' do
      let(:account) { create(:account, custom_domain: 'support.mydomain.com') }
      let(:user) { create(:user, account: account) }

      before do
        assign(:resource, user)
      end

      it 'uses the custom domain as the host' do
        expect(helper.frontend_url('dashboard')).to eq 'http://support.mydomain.com/app/dashboard'
      end
    end

    context 'with custom domain configured on the user parent account' do
      let(:parent_account) { create(:account, custom_domain: 'parent.mydomain.com') }
      let(:sub_account) { create(:account, parent: parent_account) }
      let(:user) { create(:user, account: sub_account) }

      before do
        assign(:resource, user)
      end

      it 'uses the parent custom domain as the host' do
        expect(helper.frontend_url('dashboard')).to eq 'http://parent.mydomain.com/app/dashboard'
      end
    end

    context 'when CONFIRMATION_URL environment variable is set' do
      it 'uses the full custom confirmation URL override' do
        with_modified_env CONFIRMATION_URL: 'https://externalapp.com/confirm' do
          expect(helper.frontend_url('auth/confirmation', token: 'xyz')).to eq 'https://externalapp.com/confirm?token=xyz'
        end
      end

      it 'uses the relative custom confirmation path override' do
        with_modified_env CONFIRMATION_URL: '/custom/verify' do
          expect(helper.frontend_url('auth/confirmation', token: 'xyz')).to eq 'http://test.host/custom/verify?token=xyz'
        end
      end
    end

    context 'when RESET_PASSWORD_URL environment variable is set' do
      it 'uses the full custom reset password URL override' do
        with_modified_env RESET_PASSWORD_URL: 'https://externalapp.com/reset-pass' do
          expect(helper.frontend_url('auth/password/edit', token: 'abc')).to eq 'https://externalapp.com/reset-pass?token=abc'
        end
      end

      it 'uses the relative custom reset password path override' do
        with_modified_env RESET_PASSWORD_URL: '/custom/reset' do
          expect(helper.frontend_url('auth/password/edit', token: 'abc')).to eq 'http://test.host/custom/reset?token=abc'
        end
      end
    end
  end
end
