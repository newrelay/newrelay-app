# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class SetPriorityTool < Mcp::BaseTool
    tool_name 'set_priority'
    description "Set a conversation's priority."

    VALID_PRIORITIES = %w[low medium high urgent none].freeze

    arguments do
      required(:account_id).filled(:integer).description('The Chatwoot account ID.')
      required(:conversation_id).filled(:integer).description('The conversation display ID.')
      required(:priority).filled(:string).description("One of 'low', 'medium', 'high', 'urgent', or 'none' to clear it.")
    end

    # account_id: unused here -- tenancy scoping already happened in BaseTool before perform runs.
    # ** absorbs any other unknown/extra args a client sends instead of raising ArgumentError.
    def perform(account_id:, conversation_id:, priority:, **) # rubocop:disable Lint/UnusedMethodArgument
      conversation = current_account.conversations.find_by(display_id: conversation_id)
      raise ToolError, "Conversation #{conversation_id} not found" if conversation.nil? || !can_access_conversation?(conversation)
      raise ToolError, "priority must be one of: #{VALID_PRIORITIES.join(', ')}" unless VALID_PRIORITIES.include?(priority)

      conversation.toggle_priority(priority == 'none' ? nil : priority)
      { priority: conversation.priority || 'none' }
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
