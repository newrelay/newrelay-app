// Mock API Handlers for Standalone Frontend Development

export const mockProfile = {
  id: 1,
  name: "John Doe",
  email: "john.doe@example.com",
  account_id: 1,
  role: "administrator",
  avatar_url: "https://avatar.iran.liara.run/public/32",
  accounts: [
    {
      id: 1,
      name: "DakshAI Workspace",
      role: "administrator",
      status: "active",
      locale: "en"
    }
  ]
};

export const mockAccount = {
  id: 1,
  name: "DakshAI Workspace",
  role: "administrator",
  status: "active",
  locale: "en",
  custom_attributes: {}
};

export const mockInboxes = [
  {
    id: 1,
    name: "Website Widget",
    channel_type: "Channel::WebWidget",
    avatar_url: ""
  },
  {
    id: 2,
    name: "WhatsApp Support",
    channel_type: "Channel::Whatsapp",
    avatar_url: ""
  },
  {
    id: 3,
    name: "Support Email",
    channel_type: "Channel::Email",
    avatar_url: ""
  }
];

export const mockAgents = [
  {
    id: 1,
    name: "John Doe",
    email: "john.doe@example.com",
    role: "administrator",
    availability_status: "online"
  },
  {
    id: 2,
    name: "Sarah Smith",
    email: "sarah.smith@example.com",
    role: "agent",
    availability_status: "online"
  }
];

export const mockLabels = [
  { id: 1, title: "urgent", color: "#EF4444", show_on_sidebar: true },
  { id: 2, title: "billing", color: "#3B82F6", show_on_sidebar: true },
  { id: 3, title: "feature_request", color: "#10B981", show_on_sidebar: true }
];

export const mockConversations = {
  meta: {
    mine_count: 5,
    unassigned_count: 2,
    all_count: 7,
    assigned_count: 5
  },
  payload: [
    {
      id: 1,
      account_id: 1,
      inbox_id: 1,
      status: "open",
      priority: "urgent",
      unread_count: 1,
      agent_last_seen_at: 1723500000,
      user_last_seen_at: 1723500500,
      timestamp: 1723500500,
      created_at: 1723500000,
      meta: {
        sender: {
          id: 101,
          name: "Alice Johnson",
          email: "alice@example.com",
          thumbnail: "https://avatar.iran.liara.run/public/65"
        },
        assignee: {
          id: 1,
          name: "John Doe",
          email: "john.doe@example.com"
        },
        channel: "Channel::WebWidget"
      },
      messages: [
        {
          id: 1001,
          content: "Hello! I need help with my account billing.",
          message_type: 0,
          created_at: 1723500000,
          sender: {
            id: 101,
            name: "Alice Johnson",
            thumbnail: "https://avatar.iran.liara.run/public/65"
          }
        },
        {
          id: 1002,
          content: "Hi Alice! I'd be happy to assist you with your billing inquiry.",
          message_type: 1,
          created_at: 1723500500,
          sender: {
            id: 1,
            name: "John Doe"
          }
        }
      ]
    },
    {
      id: 2,
      account_id: 1,
      inbox_id: 2,
      status: "open",
      priority: null,
      unread_count: 0,
      timestamp: 1723490000,
      created_at: 1723490000,
      meta: {
        sender: {
          id: 102,
          name: "Bob Williams",
          email: "bob@example.com",
          thumbnail: "https://avatar.iran.liara.run/public/44"
        },
        assignee: null,
        channel: "Channel::Whatsapp"
      },
      messages: [
        {
          id: 2001,
          content: "Is support available over WhatsApp right now?",
          message_type: 0,
          created_at: 1723490000,
          sender: {
            id: 102,
            name: "Bob Williams",
            thumbnail: "https://avatar.iran.liara.run/public/44"
          }
        }
      ]
    }
  ]
};

export const handleMockRequest = (reqUrl, method) => {
  const url = new URL(reqUrl, "http://localhost");
  const path = url.pathname;

  // Profile & Auth
  if (path.includes("/api/v1/profile") || path.includes("/auth/validate_token")) {
    return { status: 200, data: { payload: { data: mockProfile }, data: mockProfile } };
  }

  if (path.includes("/auth/sign_in")) {
    return { status: 200, data: { payload: { data: mockProfile }, data: mockProfile } };
  }

  // Accounts list or single account details
  if (path.match(/\/api\/v1\/accounts\/?$/) || path.match(/\/api\/v1\/accounts\/\d+\/?$/)) {
    return { status: 200, data: [mockAccount] };
  }

  // Conversations list
  if (path.includes("/api/v1/accounts/") && path.includes("/conversations")) {
    if (method === "GET") {
      return { status: 200, data: mockConversations };
    }
  }

  // Inboxes
  if (path.includes("/api/v1/accounts/") && path.includes("/inboxes")) {
    return { status: 200, data: { payload: mockInboxes } };
  }

  // Agents
  if (path.includes("/api/v1/accounts/") && path.includes("/agents")) {
    return { status: 200, data: mockAgents };
  }

  // Labels
  if (path.includes("/api/v1/accounts/") && path.includes("/labels")) {
    return { status: 200, data: { payload: mockLabels } };
  }

  // Teams
  if (path.includes("/api/v1/accounts/") && path.includes("/teams")) {
    return { status: 200, data: [] };
  }

  // Custom attributes, canned responses, campaigns, webhooks, automation rules, etc.
  if (
    path.includes("/custom_attribute_definitions") ||
    path.includes("/canned_responses") ||
    path.includes("/campaigns") ||
    path.includes("/webhooks") ||
    path.includes("/automation_rules") ||
    path.includes("/macros") ||
    path.includes("/integrations") ||
    path.includes("/contacts")
  ) {
    return { status: 200, data: { payload: [] } };
  }

  // Generic fallback for any unhandled /api request in mock mode
  if (path.startsWith("/api")) {
    return { status: 200, data: { payload: [], data: [] } };
  }

  return null;
};
