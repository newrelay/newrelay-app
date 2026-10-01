require 'rails_helper'

RSpec.describe NumberProvisioning::DummyExotel do
  it 'is off in test unless the env flag is set, and never on in production' do
    expect(described_class.enabled?).to be(false)

    with_modified_env('NUMBER_PROVISIONING_EXOTEL_DUMMY' => 'true') do
      expect(described_class.enabled?).to be(true)
    end

    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
    with_modified_env('NUMBER_PROVISIONING_EXOTEL_DUMMY' => 'true') do
      expect(described_class.enabled?).to be(false)
    end
  end
end

RSpec.describe NumberProvisioning::ExotelProvider do
  subject(:provider) { described_class.new(account: create(:account)) }

  it 'searches and activates a number without calling Exotel when the dummy is on' do
    with_modified_env('NUMBER_PROVISIONING_EXOTEL_DUMMY' => 'true') do
      store = {}
      allow(Redis::Alfred).to receive(:get) { |key| store[key] }
      allow(Redis::Alfred).to receive(:set) { |key, value| store[key] = value }
      expect(HTTParty).not_to receive(:get)
      expect(HTTParty).not_to receive(:post)

      numbers = provider.search(country_code: 'IN', type: 'Mobile')
      expect(numbers.first[:phone_number]).to eq('+919100000001')
      expect(numbers.first[:monthly_price_cents]).to eq(99_900)
      expect(numbers.first[:capabilities]).to eq(['voice'])

      placed = provider.order(phone_number: '+919100000001')
      expect(placed['id']).to eq('dummy-exotel-919100000001')
      expect(provider.status(provider_order_id: placed['id'])['status']).to eq('requirements_pending')
      NumberProvisioning::DummyExotel.mark_documents_submitted(placed['id'])
      expect(provider.status(provider_order_id: placed['id'])['status']).to eq('active')
      expect(provider.release(phone_number: '+919100000001', provider_order_id: placed['id'])).to be(true)
    end
  end
end
