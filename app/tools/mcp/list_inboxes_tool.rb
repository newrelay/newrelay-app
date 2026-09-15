# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class ListInboxesTool < Mcp::BaseTool
    tool_name 'list_inboxes'
    description 'List inboxes in a Chatwoot account.'

    arguments do
      required(:account_id).filled(:integer).description('The Chatwoot account ID.')
    end

    # account_id: unused here -- tenancy scoping already happened in BaseTool before perform runs.
    # ** absorbs any other unknown/extra args a client sends instead of raising ArgumentError.
    def perform(account_id:, **) # rubocop:disable Lint/UnusedMethodArgument
      current_user.assigned_inboxes.map { |inbox| { id: inbox.id, name: inbox.name, channel_type: inbox.channel_type } }
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
