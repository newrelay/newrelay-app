# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class ListLabelsTool < Mcp::BaseTool
    tool_name 'list_labels'
    description "List labels available in a #{Mcp::BaseTool.brand_name} account."

    arguments do
      required(:account_id).filled(:integer).description("The #{Mcp::BaseTool.brand_name} account ID.")
    end

    # account_id: unused here -- tenancy scoping already happened in BaseTool before perform runs.
    # ** absorbs any other unknown/extra args a client sends instead of raising ArgumentError.
    def perform(account_id:, **) # rubocop:disable Lint/UnusedMethodArgument
      current_account.labels.map { |label| { id: label.id, title: label.title, color: label.color, description: label.description } }
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
