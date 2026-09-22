# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class ListAccountsTool < Mcp::BaseTool
    tool_name 'list_accounts'
    description "List the #{Mcp::BaseTool.brand_name} accounts the connected access token can use over MCP."

    def self.requires_account?
      false
    end

    def perform(**)
      current_user.accounts.select { |account| account.feature_enabled?('mcp_integration') }
                  .map { |account| { id: account.id, name: account.name } }
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
