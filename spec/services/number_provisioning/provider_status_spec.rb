require 'rails_helper'

RSpec.describe NumberProvisioning::TelnyxProvider do
  subject(:provider) { described_class.new(account: create(:account)) }

  def stub_status(data)
    response = instance_double(HTTParty::Response, success?: true, parsed_response: { 'data' => data })
    allow(HTTParty).to receive(:get).and_return(response)
  end

  it 'maps a successful number to active' do
    stub_status('status' => 'pending', 'phone_numbers' => [{ 'status' => 'success', 'requirements_status' => 'approved' }])

    expect(provider.status(provider_order_id: 'ord')['status']).to eq('active')
  end

  it 'maps requirement-info-pending to requirements_pending' do
    stub_status('phone_numbers' => [{ 'status' => 'pending', 'requirements_status' => 'requirement-info-pending' }])

    expect(provider.status(provider_order_id: 'ord')['status']).to eq('requirements_pending')
  end

  it 'maps failure to failed and pending to in progress' do
    stub_status('phone_numbers' => [{ 'status' => 'failure' }])
    expect(provider.status(provider_order_id: 'ord')['status']).to eq('failed')

    stub_status('phone_numbers' => [{ 'status' => 'pending' }])
    expect(provider.status(provider_order_id: 'ord')['status']).to eq('order_placed')
  end
end

RSpec.describe NumberProvisioning::ExotelProvider do
  subject(:provider) { described_class.new(account: create(:account)) }

  it 'logs the payload keys and does not report active' do
    response = instance_double(HTTParty::Response, success?: true, parsed_response: { 'sid' => 'PN1', 'phone_number' => '+9198' })
    allow(HTTParty).to receive(:get).and_return(response)

    expect(provider.status(provider_order_id: 'PN1')['status']).to eq('order_placed')
  end
end
