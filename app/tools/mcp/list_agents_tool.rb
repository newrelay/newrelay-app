# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class ListAgentsTool < Mcp::BaseTool
    tool_name 'list_agents'
    description 'List agents in a Chatwoot account.'

    arguments do
      required(:account_id).filled(:integer).description('The Chatwoot account ID.')
    end

    # account_id: unused here -- tenancy scoping already happened in BaseTool before perform runs.
    # ** absorbs any other unknown/extra args a client sends instead of raising ArgumentError.
    def perform(account_id:, **) # rubocop:disable Lint/UnusedMethodArgument
      current_account.account_users.includes(:user).map do |account_user|
        {
          id: account_user.user.id,
          name: account_user.user.name,
          email: account_user.user.email,
          role: account_user.role
        }
      end
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
