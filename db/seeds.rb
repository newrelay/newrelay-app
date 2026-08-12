# loading installation configs
GlobalConfig.clear_cache
ConfigLoader.new.process

## Seeds productions
if Rails.env.production?
  # Setup Onboarding flow
  Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true)
end

## Seeds for Local Development
unless Rails.env.production?

  # Enables creating additional accounts from dashboard
  installation_config = InstallationConfig.find_by(name: 'CREATE_NEW_ACCOUNT_FROM_DASHBOARD')
  installation_config.value = true
  installation_config.save!
  GlobalConfig.clear_cache

  # Pushes STRIPE_HOBBY_PRICE_ID / STRIPE_STANDARD_PRICE_ID / STRIPE_BUSINESS_PRICE_ID
  # (if set in .env) into CHATWOOT_CLOUD_PLANS, so plan checkout works out of the box
  # after a fresh db:seed without manually re-entering them in Super Admin.
  Seeders::StripePlanPriceSeeder.new.perform!

  account = Account.create!(
    name: 'Acme Inc'
  )

  secondary_account = Account.create!(
    name: 'Acme Org'
  )

  user = User.new(name: 'John', email: 'john@acme.inc', password: 'Password1!', type: 'SuperAdmin')
  user.skip_confirmation!
  user.save!

  AccountUser.create!(
    account_id: account.id,
    user_id: user.id,
    role: :administrator
  )

  AccountUser.create!(
    account_id: secondary_account.id,
    user_id: user.id,
    role: :administrator
  )

  web_widget = Channel::WebWidget.create!(account: account, website_url: 'https://acme.inc')

  inbox = Inbox.create!(channel: web_widget, account: account, name: 'Acme Support')
  InboxMember.create!(user: user, inbox: inbox)

  contact_inbox = ContactInboxWithContactBuilder.new(
    source_id: user.id,
    inbox: inbox,
    hmac_verified: true,
    contact_attributes: { name: 'jane', email: 'jane@example.com', phone_number: '+2320000' }
  ).perform

  conversation = Conversation.create!(
    account: account,
    inbox: inbox,
    status: :open,
    assignee: user,
    contact: contact_inbox.contact,
    contact_inbox: contact_inbox,
    additional_attributes: {}
  )

  # sample email collect
  Seeders::MessageSeeder.create_sample_email_collect_message conversation

  Message.create!(content: 'Hello', account: account, inbox: inbox, conversation: conversation, sender: contact_inbox.contact,
                  message_type: :incoming)

  # sample location message
  #
  location_message = Message.new(content: 'location', account: account, inbox: inbox, sender: contact_inbox.contact, conversation: conversation,
                                 message_type: :incoming)
  location_message.attachments.new(
    account_id: account.id,
    file_type: 'location',
    coordinates_lat: 37.7893768,
    coordinates_long: -122.3895553,
    fallback_title: 'Bay Bridge, San Francisco, CA, USA'
  )
  location_message.save!

  # sample card
  Seeders::MessageSeeder.create_sample_cards_message conversation
  # input select
  Seeders::MessageSeeder.create_sample_input_select_message conversation
  # form
  Seeders::MessageSeeder.create_sample_form_message conversation
  # articles
  Seeders::MessageSeeder.create_sample_articles_message conversation
  # csat
  Seeders::MessageSeeder.create_sample_csat_collect_message conversation

  CannedResponse.create!(account: account, short_code: 'start', content: 'Hello welcome to chatwoot.')

  # Seed Dyte Integration Hook for local video calling testing
  unless Integrations::Hook.exists?(account_id: account.id, app_id: 'dyte')
    Integrations::Hook.create!(
      account_id: account.id,
      app_id: 'dyte',
      settings: { organization_id: 'mock_dyte_org', api_key: 'mock_dyte_key' },
      status: :enabled
    )
  end

  # Seed Exotel Integration Hook for local voice AI testing
  unless Integrations::Hook.exists?(account_id: account.id, app_id: 'exotel')
    Integrations::Hook.create!(
      account_id: account.id,
      app_id: 'exotel',
      settings: {
        account_sid: 'mock_exotel_sid',
        api_key: 'mock_exotel_key',
        api_token: 'mock_exotel_token',
        subdomain: 'mock_exotel_subdomain',
        virtual_number: '+919999999999'
      },
      status: :enabled
    )
  end

  # Seed ElevenLabs Integration Hook for local text-to-speech testing
  unless Integrations::Hook.exists?(account_id: account.id, app_id: 'elevenlabs')
    Integrations::Hook.create!(
      account_id: account.id,
      app_id: 'elevenlabs',
      settings: {
        api_key: 'mock_elevenlabs_key',
        voice_id: '21m00Tcm4TlvDq8ikWAM'
      },
      status: :enabled
    )
  end

  # Seed Exotel Voice Agent Inbox
  unless account.inboxes.exists?(name: 'Exotel Voice Agent')
    api_channel = Channel::Api.create!(account: account)
    exotel_inbox = account.inboxes.create!(name: 'Exotel Voice Agent', channel: api_channel)
    InboxMember.create!(user: user, inbox: exotel_inbox) if user
  end

  # Seed Bulk Action Audit Logs for Contacts → Bulk Actions UI testing
  if account.bulk_action_audits.none?
    [
      {
        action_label: 'Add Tag "VIP" to leads',
        operation_type: 'add_tag',
        status: :completed,
        statistics: { total: 100, success: 95, failed: 5 },
        completed_at: 10.minutes.ago,
        created_at: 15.minutes.ago
      },
      {
        action_label: 'Remove Tag "Lead" from old contacts',
        operation_type: 'remove_tag',
        status: :processing,
        statistics: { total: 50, success: 23, failed: 0 },
        created_at: 1.minute.ago
      },
      {
        action_label: 'Delete inactive spam contacts',
        operation_type: 'delete',
        status: :failed,
        statistics: { total: 120, success: 0, failed: 120 },
        completed_at: 2.hours.ago,
        created_at: 2.hours.ago
      },
      {
        action_label: 'Send SMS campaign to nurture list',
        operation_type: 'send_sms',
        status: :completed,
        statistics: { total: 80, success: 80, failed: 0 },
        completed_at: 45.minutes.ago,
        created_at: 1.hour.ago
      },
      {
        action_label: 'Send welcome email to new contacts',
        operation_type: 'send_email',
        status: :processing,
        statistics: { total: 200, success: 112, failed: 3 },
        created_at: 5.minutes.ago
      },
      {
        action_label: 'Add Tag "Newsletter" (queued)',
        operation_type: 'add_tag',
        status: :pending,
        statistics: { total: 40, success: 0, failed: 0 },
        created_at: 30.seconds.ago
      }
    ].each do |attrs|
      BulkActionAudit.create!(attrs.merge(user_id: user.id, account_id: account.id))
    end
  end
end
