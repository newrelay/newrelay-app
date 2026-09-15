# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class ListConversationsTool < Mcp::BaseTool
    tool_name 'list_conversations'
    description 'Search and filter conversations in a Chatwoot account.'

    arguments do
      required(:account_id).filled(:integer).description('The Chatwoot account ID (see list_accounts).')
      optional(:status).filled(:string).description("Conversation status: 'open', 'resolved', 'pending', 'snoozed', or 'all'. Defaults to 'open'.")
      optional(:inbox_id).filled(:integer).description('Limit to conversations in this inbox.')
      optional(:assignee_type).filled(:string).description("'me', 'unassigned', or 'all'. Defaults to all of the agent's conversations.")
      optional(:q).filled(:string).description('Free-text search over message content.')
    end

    # q: matches ConversationFinder's own parameter name -- renaming here would just move the mismatch.
    # account_id: unused here -- tenancy scoping already happened in BaseTool before perform runs.
    # ** absorbs any other unknown/extra args a client sends instead of raising ArgumentError.
    # rubocop:disable Naming/MethodParameterName, Lint/UnusedMethodArgument, Metrics/ParameterLists
    def perform(account_id:, status: nil, inbox_id: nil, assignee_type: nil, q: nil, **)
      # rubocop:enable Naming/MethodParameterName, Lint/UnusedMethodArgument, Metrics/ParameterLists
      finder_params = { status: status, inbox_id: inbox_id, assignee_type: assignee_type, q: q }.compact
      result = ConversationFinder.new(current_user, finder_params).perform
      result[:conversations].map { |conversation| conversation_summary(conversation) }
    end

    private

    def conversation_summary(conversation)
      {
        id: conversation.display_id,
        status: conversation.status,
        priority: conversation.priority,
        inbox_id: conversation.inbox_id,
        contact_name: conversation.contact&.name,
        last_activity_at: conversation.last_activity_at
      }
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
