# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class GetConversationTool < Mcp::BaseTool
    tool_name 'get_conversation'
    description 'Get full detail for one conversation by its display ID.'

    arguments do
      required(:account_id).filled(:integer).description('The Chatwoot account ID.')
      required(:conversation_id).filled(:integer).description('The conversation display ID, as shown in the Chatwoot UI/URL.')
    end

    # account_id: unused here -- tenancy scoping already happened in BaseTool before perform runs.
    # ** absorbs any other unknown/extra args a client sends instead of raising ArgumentError.
    def perform(account_id:, conversation_id:, **) # rubocop:disable Lint/UnusedMethodArgument
      conversation = current_account.conversations.find_by(display_id: conversation_id)
      raise ToolError, "Conversation #{conversation_id} not found" if conversation.nil? || !can_access_conversation?(conversation)

      {
        id: conversation.display_id,
        status: conversation.status,
        priority: conversation.priority,
        inbox_id: conversation.inbox_id,
        contact: conversation.contact && { id: conversation.contact.id, name: conversation.contact.name, email: conversation.contact.email },
        assignee: conversation.assignee&.name,
        team: conversation.team&.name,
        labels: conversation.label_list,
        created_at: conversation.created_at,
        last_activity_at: conversation.last_activity_at
      }
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
