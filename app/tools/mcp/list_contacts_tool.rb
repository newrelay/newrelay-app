# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class ListContactsTool < Mcp::BaseTool
    tool_name 'list_contacts'
    description "Search contacts in a #{Mcp::BaseTool.brand_name} account by name, email, or phone number."

    RESULTS_LIMIT = 25

    arguments do
      required(:account_id).filled(:integer).description("The #{Mcp::BaseTool.brand_name} account ID.")
      optional(:search).filled(:string).description('Search term matched against name, email, and phone number.')
    end

    # account_id: unused here -- tenancy scoping already happened in BaseTool before perform runs.
    # ** absorbs any other unknown/extra args a client sends instead of raising ArgumentError.
    def perform(account_id:, search: nil, **) # rubocop:disable Lint/UnusedMethodArgument
      contacts = search.present? ? matching_contacts(search) : current_account.contacts
      contacts.order(last_activity_at: :desc).limit(RESULTS_LIMIT).map { |contact| contact_summary(contact) }
    end

    private

    def matching_contacts(search)
      current_account.contacts.where(
        'name ILIKE :search OR email ILIKE :search OR phone_number ILIKE :search',
        search: "%#{search}%"
      )
    end

    def contact_summary(contact)
      { id: contact.id, name: contact.name, email: contact.email, phone_number: contact.phone_number }
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
