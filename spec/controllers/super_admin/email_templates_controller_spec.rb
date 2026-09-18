require 'rails_helper'

RSpec.describe 'Super Admin Email Templates', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/email_templates' do
    it 'returns unauthorized for guests' do
      get '/super_admin/email_templates'
      expect(response).to have_http_status(:redirect)
    end

    it 'lists catalog templates for a super admin' do
      sign_in(super_admin, scope: :super_admin)
      get '/super_admin/email_templates'

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Email Templates')
      expect(response.body).to include('Conversation Creation')
      expect(response.body).to include('File default')
    end
  end

  describe 'GET /super_admin/email_templates/:key' do
    it 'shows a template body' do
      sign_in(super_admin, scope: :super_admin)
      get '/super_admin/email_templates/layouts--mailer--base'

      expect(response).to have_http_status(:success)
      expect(response.body).to include('layouts/mailer/base.liquid')
    end
  end

  describe 'PATCH /super_admin/email_templates/:key' do
    it 'saves an installation override for a liquid template' do
      sign_in(super_admin, scope: :super_admin)

      patch '/super_admin/email_templates/layouts--mailer--base', params: { email_template: { body: '<p>Override</p>' } }

      expect(response).to redirect_to('/super_admin/email_templates/layouts--mailer--base')
      expect(EmailTemplate.find_by(name: 'base', account_id: nil).body).to eq('<p>Override</p>')
    end

    it 'does not override erb templates' do
      sign_in(super_admin, scope: :super_admin)

      patch '/super_admin/email_templates/devise--mailer--confirmation_instructions',
            params: { email_template: { body: '<p>Nope</p>' } }

      expect(response).to redirect_to('/super_admin/email_templates/devise--mailer--confirmation_instructions')
      expect(EmailTemplate.where(name: 'confirmation_instructions')).to be_empty
    end
  end
end
