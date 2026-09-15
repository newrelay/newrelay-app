# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class AssignConversationTool < Mcp::BaseTool
    tool_name 'assign_conversation'
    description 'Assign a conversation to an agent or a team. Provide exactly one of agent_id or team_id.'

    arguments do
      required(:account_id).filled(:integer).description('The Chatwoot account ID.')
      required(:conversation_id).filled(:integer).description('The conversation display ID.')
      optional(:agent_id).filled(:integer).description('User ID of the agent to assign. Mutually exclusive with team_id.')
      optional(:team_id).filled(:integer).description('Team ID to assign. Mutually exclusive with agent_id.')
    end

    # account_id: unused here -- tenancy scoping already happened in BaseTool before perform runs.
    # ** absorbs any other unknown/extra args a client sends instead of raising ArgumentError.
    def perform(account_id:, conversation_id:, agent_id: nil, team_id: nil, **) # rubocop:disable Lint/UnusedMethodArgument
      conversation = current_account.conversations.find_by(display_id: conversation_id)
      raise ToolError, "Conversation #{conversation_id} not found" if conversation.nil? || !can_access_conversation?(conversation)
      raise ToolError, 'Provide exactly one of agent_id or team_id' if agent_id.blank? == team_id.blank?

      agent_id ? assign_to_agent(conversation, agent_id) : assign_to_team(conversation, team_id)
    end

    private

    def assign_to_agent(conversation, agent_id)
      raise ToolError, "Agent #{agent_id} not found" unless current_account.users.exists?(id: agent_id)

      assignee = Conversations::AssignmentService.new(conversation: conversation, assignee_id: agent_id, assignee_type: 'User').perform
      { assignee: assignee&.name }
    end

    def assign_to_team(conversation, team_id)
      team = current_account.teams.find_by(id: team_id)
      raise ToolError, "Team #{team_id} not found" unless team

      conversation.update!(team: team)
      { team: team.name }
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
