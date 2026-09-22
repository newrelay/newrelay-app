# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class GetContactTool < Mcp::BaseTool
    tool_name 'get_contact'
    description 'Get full detail for one contact by ID.'

    arguments do
      required(:account_id).filled(:integer).description("The #{Mcp::BaseTool.brand_name} account ID.")
      required(:contact_id).filled(:integer).description('The contact ID.')
    end

    # account_id: unused here -- tenancy scoping already happened in BaseTool before perform runs.
    # ** absorbs any other unknown/extra args a client sends instead of raising ArgumentError.
    def perform(account_id:, contact_id:, **) # rubocop:disable Lint/UnusedMethodArgument
      contact = current_account.contacts.find_by(id: contact_id)
      raise ToolError, "Contact #{contact_id} not found" unless contact

      {
        id: contact.id,
        name: contact.name,
        email: contact.email,
        phone_number: contact.phone_number,
        identifier: contact.identifier,
        labels: contact.label_list,
        last_activity_at: contact.last_activity_at
      }
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
