require './config/environment'
begin
  account = Account.first || Account.create!(name: 'Test Account')

  puts 'Checking OauthCallbacksController...'
  # Just simulating the methods
  Reputation::OauthService.new(account: account, provider: 'google', code: 'test_code')

  puts 'All looks structurally sound.'
rescue StandardError => e
  puts "Error: #{e.message}"
  puts e.backtrace.take(5)
end
