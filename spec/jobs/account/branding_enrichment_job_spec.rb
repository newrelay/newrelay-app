# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account::BrandingEnrichmentJob, type: :job do
  subject(:job) { described_class.new }

  let(:account) { create(:account, name: 'Original Name') }

  describe '#perform' do
    context 'with disposable email domain' do
      it 'skips branding enrichment' do
        allow(WebsiteBrandingService).to receive(:new)

        job.perform(account.id, 'test@yopmail.com')

        expect(WebsiteBrandingService).not_to have_received(:new)
        expect(account.reload.name).to eq('Original Name')
      end
    end

    context 'with free/generic email domain' do
      it 'skips branding enrichment' do
        allow(WebsiteBrandingService).to receive(:new)

        job.perform(account.id, 'test@gmail.com')

        expect(WebsiteBrandingService).not_to have_received(:new)
        expect(account.reload.name).to eq('Original Name')
      end
    end

    context 'with standard business email domain' do
      it 'triggers branding enrichment' do
        service_double = instance_double(WebsiteBrandingService)
        allow(WebsiteBrandingService).to receive(:new).with('test@mybusiness.com').and_return(service_double)
        allow(service_double).to receive(:perform).and_return({ title: 'My Business Corp' })

        job.perform(account.id, 'test@mybusiness.com')

        expect(account.reload.name).to eq('My Business Corp')
      end
    end
  end
end
