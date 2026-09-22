# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class SetStatusTool < Mcp::BaseTool
    tool_name 'set_status'
    description "Change a conversation's status (open, resolved, pending, or snoozed)."

    VALID_STATUSES = %w[open resolved pending snoozed].freeze

    arguments do
      required(:account_id).filled(:integer).description("The #{Mcp::BaseTool.brand_name} account ID.")
      required(:conversation_id).filled(:integer).description('The conversation display ID.')
      required(:status).filled(:string).description("One of 'open', 'resolved', 'pending', or 'snoozed'.")
      optional(:snoozed_until).maybe(:string).description("ISO 8601 timestamp to wake a snoozed conversation. Only used when status is 'snoozed'.")
    end

    # account_id: unused here -- tenancy scoping already happened in BaseTool before perform runs.
    # ** absorbs any other unknown/extra args a client sends instead of raising ArgumentError.
    def perform(account_id:, conversation_id:, status:, snoozed_until: nil, **) # rubocop:disable Lint/UnusedMethodArgument
      conversation = current_account.conversations.find_by(display_id: conversation_id)
      raise ToolError, "Conversation #{conversation_id} not found" if conversation.nil? || !can_access_conversation?(conversation)
      raise ToolError, "status must be one of: #{VALID_STATUSES.join(', ')}" unless VALID_STATUSES.include?(status)

      conversation.status = status
      conversation.snoozed_until = parse_snoozed_until(snoozed_until) if status == 'snoozed' && snoozed_until.present?
      raise ToolError, conversation.errors.full_messages.join(', ') unless conversation.save

      { status: conversation.status, snoozed_until: conversation.snoozed_until }
    end

    private

    def parse_snoozed_until(value)
      Time.zone.parse(value)
    rescue ArgumentError, TypeError
      raise ToolError, 'snoozed_until must be a valid ISO 8601 timestamp'
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
