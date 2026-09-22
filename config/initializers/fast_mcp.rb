require Rails.root.join('lib/mcp/sync_rack_transport')
require Rails.root.join('app/tools/mcp/base_tool')
require Rails.root.join('app/tools/mcp/list_accounts_tool')
require Rails.root.join('app/tools/mcp/list_conversations_tool')
require Rails.root.join('app/tools/mcp/get_conversation_tool')
require Rails.root.join('app/tools/mcp/list_contacts_tool')
require Rails.root.join('app/tools/mcp/get_contact_tool')
require Rails.root.join('app/tools/mcp/list_inboxes_tool')
require Rails.root.join('app/tools/mcp/list_agents_tool')
require Rails.root.join('app/tools/mcp/list_teams_tool')
require Rails.root.join('app/tools/mcp/list_labels_tool')
require Rails.root.join('app/tools/mcp/add_private_note_tool')
require Rails.root.join('app/tools/mcp/add_label_tool')
require Rails.root.join('app/tools/mcp/remove_label_tool')
require Rails.root.join('app/tools/mcp/assign_conversation_tool')
require Rails.root.join('app/tools/mcp/set_priority_tool')
require Rails.root.join('app/tools/mcp/send_reply_tool')

mcp_server = FastMcp::Server.new(name: 'chatwoot-mcp', version: '1.0.0', logger: Rails.logger)
mcp_server.register_tools(
  Mcp::ListAccountsTool,
  Mcp::ListConversationsTool,
  Mcp::GetConversationTool,
  Mcp::ListContactsTool,
  Mcp::GetContactTool,
  Mcp::ListInboxesTool,
  Mcp::ListAgentsTool,
  Mcp::ListTeamsTool,
  Mcp::ListLabelsTool,
  Mcp::AddPrivateNoteTool,
  Mcp::AddLabelTool,
  Mcp::RemoveLabelTool,
  Mcp::AssignConversationTool,
  Mcp::SetPriorityTool,
  Mcp::SendReplyTool
)
FastMcp.server = mcp_server

Rails.application.middleware.use(
  Mcp::SyncRackTransport,
  mcp_server,
  path_prefix: '/mcp',
  logger: Rails.logger,
  # Same reasoning as allowed_origins below: this app runs RAILS_ENV=development on real,
  # remotely-reachable hosts (dev.newrelay.com), so Rails.env.local? can't distinguish
  # "actual local machine" from "deployed dev server" -- it blocked every real MCP client.
  localhost_only: false,
  # DNS-rebinding origin checks are a browser/cookie-auth mitigation; this endpoint is
  # Bearer-token authenticated (see Mcp::BaseTool#authenticate!), so a same-host allowlist
  # would 403 every real request (production host is never 'localhost') as well as every spec.
  allowed_origins: []
)
