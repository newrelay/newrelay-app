# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class BaseTool < FastMcp::Tool
    class ToolError < StandardError; end

    def call(**args)
      authenticate!
      Current.mcp = true
      require_account!(args[:account_id]) if self.class.requires_account?

      Mcp::BaseTool.success(perform(**args))
    rescue ToolError => e
      Mcp::BaseTool.failure(e.message)
    rescue StandardError => e
      ChatwootExceptionTracker.new(e, user: Current.user, account: Current.account).capture_exception
      Mcp::BaseTool.failure('Something went wrong')
    ensure
      Current.reset
    end

    def self.requires_account?
      true
    end

    def self.success(data)
      { content: [{ type: 'text', text: data.to_json }], isError: false }
    end

    def self.failure(message)
      { content: [{ type: 'text', text: message }], isError: true }
    end

    private

    attr_reader :current_user

    def current_account
      Current.account
    end

    def pundit_user
      { user: current_user, account: current_account, account_user: Current.account_user }
    end

    def can_access_conversation?(conversation)
      ConversationPolicy.new(pundit_user, conversation).show?
    end

    def authenticate!
      auth_header = headers['authorization']
      raise ToolError, 'Missing or invalid access token' if auth_header.blank?

      token = auth_header.delete_prefix('Bearer ')
      access_token = AccessToken.find_by(token: token)
      raise ToolError, 'Missing or invalid access token' unless access_token
      raise ToolError, 'Missing or invalid access token' unless access_token.owner.is_a?(User)

      @current_user = access_token.owner
      Current.user = @current_user
      # Deliberate -- a read-only auth check shouldn't run token validations or touch updated_at.
      access_token.update_column(:last_used_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
    end

    def require_account!(account_id)
      raise ToolError, 'account_id is required' if account_id.blank?

      account = current_user.accounts.find_by(id: account_id)
      raise ToolError, 'Account not found or not accessible' unless account
      raise ToolError, 'MCP access is not enabled for this account' unless account.feature_enabled?('mcp_integration')

      Current.account = account
      Current.account_user = account.account_users.find_by(user_id: current_user.id)
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
