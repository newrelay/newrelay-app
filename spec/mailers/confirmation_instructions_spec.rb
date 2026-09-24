# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Devise::Mailer' do
  describe 'notify' do
    let(:account) { create(:account) }
    let!(:confirmable_user) { create(:user, inviter: inviter_val, account: account) }
    let(:inviter_val) { nil }
    let(:mail) { Devise::Mailer.confirmation_instructions(confirmable_user.reload, nil, {}) }
    let(:mail_body) { CGI.unescapeHTML(mail.body.to_s) }

    before do
      # to verify the token in email
      confirmable_user.update!(confirmed_at: nil)
      confirmable_user.send(:generate_confirmation_token)
    end

    it 'has the correct header data' do
      expect(mail.reply_to).to contain_exactly('accounts@chatwoot.com')
      expect(mail.to).to contain_exactly(confirmable_user.email)
      expect(mail.subject).to eq('Confirmation Instructions')
    end

    it 'uses the user\'s name' do
      expect(mail.body.to_s).to include("Hi #{CGI.escapeHTML(confirmable_user.name)},")
      expect(mail_body).to include("Hi #{confirmable_user.name},")
    end

    context 'when the user name contains HTML' do
      before do
        confirmable_user.update!(name: 'Sony <script>alert(1)</script>')
      end

      it 'escapes the name in the rendered email body' do
        expect(mail.body.to_s).to include("Hi #{CGI.escapeHTML(confirmable_user.name)},")
        expect(mail.body.to_s).not_to include("Hi #{confirmable_user.name},")
      end
    end

    it 'shows the default confirmation state' do
      expect(mail_body).to include('Confirm your email to get started')
      expect(mail_body).to include('Welcome to Chatwoot. We just need to verify your email address before you can start using your account.')
      expect(mail_body).to include('Confirm my account')
      expect(mail_body).not_to include('Workspace invitation')
    end

    it 'includes the installation logo' do
      expect(mail.body.to_s).to include('/brand-assets/logo.svg')
    end

    context 'when the account has custom branding' do
      let(:logo_url) { 'https://cdn.acme.test/logo.png' }

      before do
        account.enable_features!(:white_labeling, :custom_domain)
        account.update!(
          brand_name: 'Acme Support',
          brand_logo_url: logo_url,
          custom_domain: 'app.acme.test'
        )
      end

      it 'uses the custom brand name, logo, and domain in the confirmation email' do
        expect(mail_body).to include('Welcome to Acme Support.')
        expect(mail.body.to_s).to include(logo_url)
        expect(mail.body.to_s).to include("http://app.acme.test/app/auth/confirmation?confirmation_token=#{confirmable_user.confirmation_token}")
        expect(mail.body.to_s).to include('href="http://app.acme.test"')
        expect(mail.body.to_s).to include('email_brand_icons/')
        expect(mail.body.to_s).to include('class="mascot-img"')
        expect(mail.body.to_s).not_to include('/email_icons/confirmation_instructions.png')
      end
    end

    context 'when signing up on a branded custom domain' do
      let(:logo_url) { 'https://cdn.acme.test/logo.png' }
      let(:host_account) { create(:account) }
      let(:mail) { Devise::Mailer.with(account: host_account).confirmation_instructions(confirmable_user.reload, nil, {}) }

      before do
        host_account.enable_features!(:white_labeling, :custom_domain)
        host_account.update!(
          brand_name: 'Acme Support',
          brand_logo_url: logo_url,
          custom_domain: 'app.acme.test'
        )
      end

      it 'uses the host account branding even though the new workspace is unbranded' do
        expect(mail_body).to include('Welcome to Acme Support.')
        expect(mail.body.to_s).to include(logo_url)
        expect(mail.body.to_s).to include("http://app.acme.test/app/auth/confirmation?confirmation_token=#{confirmable_user.confirmation_token}")
        expect(mail.body.to_s).to include('href="http://app.acme.test"')
      end
    end

    context 'when the user belongs to a T2 workspace under a branded T1 parent' do
      let(:logo_url) { 'https://cdn.acme.test/logo.png' }
      let(:parent_account) { create(:account, is_reseller: true) }
      let(:account) { create(:account, parent: parent_account) }
      let(:mail) { Devise::Mailer.with(account: account).confirmation_instructions(confirmable_user.reload, nil, {}) }

      before do
        parent_account.enable_features!(:white_labeling, :custom_domain)
        parent_account.update!(
          brand_name: 'Acme Support',
          brand_logo_url: logo_url,
          custom_domain: 'app.acme.test'
        )
      end

      it 'uses the T1 parent brand name, logo, and domain' do
        expect(mail_body).to include('Welcome to Acme Support.')
        expect(mail.body.to_s).to include(logo_url)
        expect(mail.body.to_s).to include("http://app.acme.test/app/auth/confirmation?confirmation_token=#{confirmable_user.confirmation_token}")
      end
    end

    context 'when the T2 workspace has its own custom domain' do
      let(:logo_url) { 'https://cdn.acme.test/logo.png' }
      let(:child_logo_url) { 'https://cdn.child.test/logo.png' }
      let(:parent_account) { create(:account, is_reseller: true, name: 'Acme') }
      let(:account) { create(:account, parent: parent_account, name: 'Child Workspace') }
      let(:mail) { Devise::Mailer.with(account: account).confirmation_instructions(confirmable_user.reload, nil, {}) }

      before do
        parent_account.enable_features!(:white_labeling, :custom_domain)
        parent_account.update!(
          brand_name: 'Acme Support',
          brand_logo_url: logo_url,
          custom_domain: 'app.acme.test'
        )
        account.enable_features!(:white_labeling, :custom_domain)
        account.update!(
          brand_name: 'Child Support',
          brand_logo_url: child_logo_url,
          custom_domain: 'app.child.test'
        )
      end

      it 'uses the T2 brand name, logo, domain, and From display name' do
        expect(mail_body).to include('Welcome to Child Support.')
        expect(mail_body).not_to include('Welcome to Acme Support.')
        expect(mail.body.to_s).to include(child_logo_url)
        expect(mail.body.to_s).not_to include(logo_url)
        expect(mail.body.to_s).to include("http://app.child.test/app/auth/confirmation?confirmation_token=#{confirmable_user.confirmation_token}")
        expect(mail.from).to eq([account.support_email])
        expect(mail[:from].display_names).to eq(['Child Support'])
      end
    end

    context 'when the T2 workspace has a custom domain but no brand name' do
      let(:parent_account) { create(:account, is_reseller: true, name: 'Acme') }
      let(:account) { create(:account, parent: parent_account, name: 'Child Workspace') }
      let(:mail) { Devise::Mailer.with(account: account).confirmation_instructions(confirmable_user.reload, nil, {}) }

      before do
        parent_account.enable_features!(:white_labeling, :custom_domain)
        parent_account.update!(brand_name: 'Acme Support', custom_domain: 'app.acme.test')
        account.enable_features!(:custom_domain)
        account.update!(custom_domain: 'app.child.test')
      end

      it 'uses the T2 workspace name instead of the platform brand' do
        expect(mail_body).to include('Welcome to Child Workspace.')
        expect(mail_body).not_to include('Welcome to Acme Support.')
        expect(mail.body.to_s).to include("http://app.child.test/app/auth/confirmation?confirmation_token=#{confirmable_user.confirmation_token}")
        expect(mail.from).to eq([account.support_email])
        expect(mail[:from].display_names).to eq(['Child Workspace'])
      end
    end

    context 'when the custom domain is verified for Resend sending' do
      let(:account) { create(:account, name: 'Child Workspace') }
      let(:mail) { Devise::Mailer.with(account: account).confirmation_instructions(confirmable_user.reload, nil, {}) }

      before do
        account.enable_features!(:custom_domain)
        account.update!(custom_domain: 'app.child.test')
        account.update!(
          ssl_settings: (account.ssl_settings || {}).merge(
            'resend_status' => 'verified',
            'resend_from_email' => 'noreply@app.child.test'
          )
        )
      end

      it 'sends from the custom domain address' do
        expect(mail.from).to eq(['noreply@app.child.test'])
        expect(mail[:from].display_names).to eq(['Child Workspace'])
      end
    end

    context 'when there is an inviter' do
      let(:inviter_val) { create(:user, :administrator, skip_confirmation: true, account: account) }

      it 'refers to the inviter and their account' do
        expect(mail_body).to include("You're invited to join #{account.name}")
        expect(mail_body).to include("#{inviter_val.name} invited you to join the #{account.name} workspace on Chatwoot.")
        expect(mail_body).to include('Accept invitation')
        expect(mail_body).not_to include('Confirm your email to get started')
      end

      it 'sends a password reset link' do
        expect(mail.body).to include('app/auth/password/edit?reset_password_token')
        expect(mail.body).not_to include('app/auth/confirmation')
      end
    end

    context 'when user updates the email' do
      before do
        confirmable_user.update!(email: 'user@example.com')
      end

      it 'sends a confirmation link' do
        confirmation_mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, nil, {})
        confirmation_body = CGI.unescapeHTML(confirmation_mail.body.to_s)

        expect(confirmation_body).to include('Confirm your new email address')
        expect(confirmation_body).to include('New email')
        expect(confirmation_mail.body).to include('app/auth/confirmation?confirmation_token')
        expect(confirmation_mail.body).not_to include('app/auth/password/edit')
        expect(confirmable_user.unconfirmed_email.blank?).to be false
      end
    end

    context 'when user is confirmed and updates the email' do
      before do
        confirmable_user.confirm
        confirmable_user.update!(email: 'user@example.com')
      end

      it 'sends a confirmation link' do
        confirmation_mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, nil, {})
        confirmation_body = CGI.unescapeHTML(confirmation_mail.body.to_s)

        expect(confirmation_body).to include('Confirm your new email address')
        expect(confirmation_mail.body).to include('app/auth/confirmation?confirmation_token')
        expect(confirmation_mail.body).not_to include('app/auth/password/edit')
        expect(confirmable_user.unconfirmed_email.blank?).to be false
      end
    end

    context 'when user already confirmed' do
      before do
        confirmable_user.confirm
        confirmable_user.account_users.last.destroy!
      end

      it 'send instructions with the link to login' do
        confirmation_mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, nil, {})
        confirmation_body = CGI.unescapeHTML(confirmation_mail.body.to_s)

        expect(confirmation_body).to include('Your account is ready')
        expect(confirmation_body).to include('Open my account')
        expect(confirmation_mail.body).to include('/auth/sign_in')
      end
    end
  end
end
