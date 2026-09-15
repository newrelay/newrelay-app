# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class AddLabelTool < Mcp::BaseTool
    tool_name 'add_label'
    description 'Add one or more labels to a conversation, keeping any labels it already has.'

    arguments do
      required(:account_id).filled(:integer).description('The Chatwoot account ID.')
      required(:conversation_id).filled(:integer).description('The conversation display ID.')
      required(:labels).value(:array).each(:string).description('Label titles to add.')
    end

    # account_id: unused here -- tenancy scoping already happened in BaseTool before perform runs.
    # ** absorbs any other unknown/extra args a client sends instead of raising ArgumentError.
    def perform(account_id:, conversation_id:, labels:, **) # rubocop:disable Lint/UnusedMethodArgument
      conversation = current_account.conversations.find_by(display_id: conversation_id)
      raise ToolError, "Conversation #{conversation_id} not found" if conversation.nil? || !can_access_conversation?(conversation)

      known_labels = current_account.labels.pluck(:title)
      normalized_labels = labels.map(&:downcase)
      unknown_labels = normalized_labels - known_labels
      raise ToolError, "Unknown labels: #{unknown_labels.join(', ')}. Use list_labels to see the account's valid labels." if unknown_labels.any?

      conversation.add_labels(normalized_labels)
      { labels: conversation.label_list }
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
