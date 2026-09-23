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
      expect(response.body).to include('Our mail')
      expect(response.body).to include('Custom brand mail')
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

  describe 'GET /super_admin/email_templates/:key/preview' do
    it 'renders a sample preview of a liquid template' do
      sign_in(super_admin, scope: :super_admin)
      get '/super_admin/email_templates/mailers--agent_notifications--conversation_notifications_mailer--conversation_creation/preview'

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Preview Conversation Creation')
      expect(response.body).to include('raw=1')
    end

    it 'renders raw html for the preview iframe' do
      sign_in(super_admin, scope: :super_admin)
      get '/super_admin/email_templates/mailers--agent_notifications--conversation_notifications_mailer--conversation_creation/preview',
          params: { raw: 1 }

      expect(response).to have_http_status(:success)
      expect(response.body).to include('email-container')
      expect(CGI.unescapeHTML(response.body)).to include('Alex Rivera')
      expect(CGI.unescapeHTML(response.body)).to include('Jordan Lee')
      expect(response.body).not_to include('Back to templates')
    end

    it 'renders a sample custom-brand preview' do
      sign_in(super_admin, scope: :super_admin)

      get '/super_admin/email_templates/mailers--agent_notifications--conversation_notifications_mailer--conversation_creation/preview',
          params: { audience: 'custom_brand', raw: 1 }

      expect(response).to have_http_status(:success)
      expect(CGI.unescapeHTML(response.body)).to include('Acme')
      expect(CGI.unescapeHTML(response.body)).to include('https://help.acme.test')
    end
  end

  describe 'PATCH /super_admin/email_templates/:key' do
    it 'saves an installation override for a liquid template' do
      sign_in(super_admin, scope: :super_admin)

      patch '/super_admin/email_templates/layouts--mailer--base', params: { email_template: { body: '<p>Override</p>' } }

      expect(response).to redirect_to('/super_admin/email_templates/layouts--mailer--base')
      expect(EmailTemplate.find_by(name: 'base', account_id: nil, white_label: false).body).to eq('<p>Override</p>')
    end

    it 'saves a shared custom-brand override' do
      sign_in(super_admin, scope: :super_admin)

      patch '/super_admin/email_templates/layouts--mailer--base',
            params: { audience: 'custom_brand', email_template: { body: '<p>Brand</p>' } }

      expect(response).to redirect_to('/super_admin/email_templates/layouts--mailer--base?audience=custom_brand')
      expect(EmailTemplate.find_by(name: 'base', account_id: nil, white_label: true).body).to eq('<p>Brand</p>')
      expect(EmailTemplate.find_by(name: 'base', account_id: nil, white_label: false)).to be_nil
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
