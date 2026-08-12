require './config/environment'
account = Account.first
account.custom_attributes['plan_name'] = 'hobby'
account.save!
Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform

class MockAgentsController < Api::V1::Accounts::AgentsController
  def initialize(account)
    super()
    @account = account
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
  end

  def current_account
    @account
  end
  
  def action_name
    'create'
  end
end

ctrl = MockAgentsController.new(account)
begin
  ctrl.send(:enforce_account_limits!)
  puts "No limit hit!"
rescue => e
  puts "Error or rendered something: #{e.class} - #{e.message}"
end
puts "Response body: #{ctrl.response.body}" if ctrl.response.body.present?
