# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class RemoveLabelTool < Mcp::BaseTool
    tool_name 'remove_label'
    description 'Remove one or more labels from a conversation, keeping any others it has.'

    arguments do
      required(:account_id).filled(:integer).description('The Chatwoot account ID.')
      required(:conversation_id).filled(:integer).description('The conversation display ID.')
      required(:labels).value(:array).each(:string).description('Label titles to remove.')
    end

    # account_id: unused here -- tenancy scoping already happened in BaseTool before perform runs.
    # ** absorbs any other unknown/extra args a client sends instead of raising ArgumentError.
    def perform(account_id:, conversation_id:, labels:, **) # rubocop:disable Lint/UnusedMethodArgument
      conversation = current_account.conversations.find_by(display_id: conversation_id)
      raise ToolError, "Conversation #{conversation_id} not found" if conversation.nil? || !can_access_conversation?(conversation)

      conversation.update_labels(conversation.label_list - labels)
      { labels: conversation.label_list }
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
