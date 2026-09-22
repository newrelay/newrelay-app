# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class SendReplyTool < Mcp::BaseTool
    tool_name 'send_reply'
    description 'Send a customer-visible reply on a conversation. The customer will see this message.'

    arguments do
      required(:account_id).filled(:integer).description("The #{Mcp::BaseTool.brand_name} account ID.")
      required(:conversation_id).filled(:integer).description('The conversation display ID.')
      required(:content).filled(:string).description('The reply text.')
    end

    # account_id: unused here -- tenancy scoping already happened in BaseTool before perform runs.
    # ** absorbs any other unknown/extra args a client sends instead of raising ArgumentError.
    def perform(account_id:, conversation_id:, content:, **) # rubocop:disable Lint/UnusedMethodArgument
      conversation = current_account.conversations.find_by(display_id: conversation_id)
      raise ToolError, "Conversation #{conversation_id} not found" if conversation.nil? || !can_access_conversation?(conversation)

      message = Messages::MessageBuilder.new(current_user, conversation, {
                                               content: content,
                                               private: false,
                                               message_type: 'outgoing',
                                               content_attributes: { mcp: true }
                                             }).perform

      { id: message.id, content: message.content, private: message.private, created_at: message.created_at }
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
