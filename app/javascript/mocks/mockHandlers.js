// Mock API Handlers for Standalone Frontend Development
//
// Each dataset below feeds a real dashboard screen so the UI can be developed
// without a backend. Response SHAPES matter — they must match what the Vuex
// stores expect (array vs `{ payload }` vs nested `{ data: { data } }`).

// Every feature flag from config/features.yml, all enabled, so every
// feature-gated screen and route is reachable during UI development.
export const mockFeatures = {
  advanced_assignment: true,
  advanced_search: true,
  advanced_search_indexing: true,
  agent_bots: true,
  agent_management: true,
  api_access: true,
  assignment_v2: true,
  audit_logs: true,
  auto_resolve_conversations: true,
  automations: true,
  campaigns: true,
  canned_responses: true,
  captain_document_auto_sync: true,
  captain_integration: true,
  captain_integration_v2: true,
  captain_tasks: true,
  captain_v1_action_classifier: true,
  channel_email: true,
  channel_facebook: true,
  channel_instagram: true,
  channel_tiktok: true,
  channel_voice: true,
  channel_website: true,
  channel_whatsapp: true,
  chatwoot_v4: true,
  companies: true,
  contact_chatwoot_support_team: true,
  conversation_required_attributes: true,
  conversation_unread_counts: true,
  crm: true,
  crm_integration: true,
  crm_v2: true,
  csat_review_notes: true,
  custom_attributes: true,
  custom_domain: true,
  custom_reply_domain: true,
  custom_reply_email: true,
  custom_roles: true,
  custom_tools: true,
  disable_branding: true,
  email_continuity_on_api_channel: true,
  help_center: true,
  help_center_embedding_search: true,
  inbound_emails: true,
  inbox_management: true,
  inbox_view: true,
  insert_article_in_reply: true,
  integrations: true,
  ip_lookup: true,
  labels: true,
  linear_integration: true,
  macros: true,
  message_reply_to: true,
  notion_integration: true,
  quoted_email_reply: true,
  reply_mailer_migration: true,
  report_rollup: true,
  reports: true,
  reseller_dashboard: true,
  saml: true,
  search_with_gin: true,
  shopify_integration: true,
  sla: true,
  team_management: true,
  voice_recorder: true,
  whatsapp_campaign: true,
  whatsapp_embedded_signup: true,
  white_labeling: true,
};

// Usage limits shown on the billing screen. `allowed` set high so nothing
// reads as capped in the UI.
export const mockLimits = {
  agents: { consumed: 3, allowed: 100000 },
  non_web_inboxes: { consumed: 2, allowed: 100000 },
  conversation: { consumed: 4, allowed: 100000 },
  contacts: { consumed: 4, allowed: 100000 },
  automations: { consumed: 1, allowed: 100000 },
  t3_subaccounts: { consumed: 0, allowed: 100000 },
};

export const mockProfile = {
  id: 1,
  name: 'John Doe',
  email: 'john.doe@example.com',
  account_id: 1,
  role: 'administrator',
  confirmed: true,
  pubsub_token: 'mock-pubsub-token',
  avatar_url: '',
  ui_settings: { locale: 'en' },
  accounts: [
    {
      id: 1,
      name: 'DakshAI Workspace',
      role: 'administrator',
      status: 'active',
      locale: 'en',
      availability: 'online',
      auto_offline: false,
      permissions: [
        'administrator',
        'conversation_manage',
        'conversation_unassigned_manage',
        'conversation_participating_manage',
        'contact_manage',
        'report_manage',
        'knowledge_base_manage',
      ],
      features: mockFeatures,
      limits: mockLimits,
      custom_attributes: {},
    },
  ],
};

export const mockAccount = {
  id: 1,
  name: 'DakshAI Workspace',
  role: 'administrator',
  status: 'active',
  locale: 'en',
  created_at: '2026-01-01T00:00:00.000Z',
  custom_attributes: {},
  features: mockFeatures,
  limits: mockLimits,
};

export const mockInboxes = [
  {
    id: 1,
    name: 'Website Widget',
    channel_type: 'Channel::WebWidget',
    avatar_url: '',
    greeting_enabled: false,
    working_hours_enabled: false,
  },
  {
    id: 2,
    name: 'WhatsApp Support',
    channel_type: 'Channel::Whatsapp',
    avatar_url: '',
    phone_number: '+15551230000',
  },
  {
    id: 3,
    name: 'Support Email',
    channel_type: 'Channel::Email',
    avatar_url: '',
    email: 'support@dakshai.example.com',
  },
];

export const mockAgents = [
  {
    id: 1,
    name: 'John Doe',
    email: 'john.doe@example.com',
    role: 'administrator',
    confirmed: true,
    availability_status: 'online',
    available_name: 'John Doe',
    thumbnail: '',
  },
  {
    id: 2,
    name: 'Sarah Smith',
    email: 'sarah.smith@example.com',
    role: 'agent',
    confirmed: true,
    availability_status: 'online',
    available_name: 'Sarah Smith',
    thumbnail: '',
  },
  {
    id: 3,
    name: 'Miguel Torres',
    email: 'miguel.torres@example.com',
    role: 'agent',
    confirmed: true,
    availability_status: 'offline',
    available_name: 'Miguel Torres',
    thumbnail: '',
  },
];

export const mockLabels = [
  {
    id: 1,
    title: 'urgent',
    description: 'Needs quick action',
    color: '#EF4444',
    show_on_sidebar: true,
  },
  {
    id: 2,
    title: 'billing',
    description: 'Billing questions',
    color: '#3B82F6',
    show_on_sidebar: true,
  },
  {
    id: 3,
    title: 'feature_request',
    description: 'Product feedback',
    color: '#10B981',
    show_on_sidebar: true,
  },
  {
    id: 4,
    title: 'vip',
    description: 'VIP customers',
    color: '#8B5CF6',
    show_on_sidebar: true,
  },
];

export const mockTeams = [
  {
    id: 1,
    name: 'Sales',
    description: 'Handles pre-sales conversations',
    allow_auto_assign: true,
    account_id: 1,
    is_member: true,
  },
  {
    id: 2,
    name: 'Support',
    description: 'Customer support team',
    allow_auto_assign: true,
    account_id: 1,
    is_member: true,
  },
];

export const mockContacts = [
  {
    id: 101,
    name: 'Alice Johnson',
    email: 'alice@example.com',
    phone_number: '+15550001111',
    thumbnail: '',
    availability_status: 'offline',
    created_at: 1723000000,
    last_activity_at: 1723500500,
    additional_attributes: { company_name: 'Acme Inc', city: 'New York' },
    custom_attributes: {},
  },
  {
    id: 102,
    name: 'Bob Williams',
    email: 'bob@example.com',
    phone_number: '+15550002222',
    thumbnail: '',
    availability_status: 'offline',
    created_at: 1722000000,
    last_activity_at: 1723490000,
    additional_attributes: { company_name: 'Globex', city: 'London' },
    custom_attributes: {},
  },
  {
    id: 103,
    name: 'Carla Mendes',
    email: 'carla@example.com',
    phone_number: '+15550003333',
    thumbnail: '',
    availability_status: 'online',
    created_at: 1721000000,
    last_activity_at: 1723480000,
    additional_attributes: { company_name: 'Initech', city: 'Lisbon' },
    custom_attributes: {},
  },
  {
    id: 104,
    name: 'David Kim',
    email: 'david@example.com',
    phone_number: '+15550004444',
    thumbnail: '',
    availability_status: 'offline',
    created_at: 1720000000,
    last_activity_at: 1723470000,
    additional_attributes: { company_name: 'Hooli', city: 'Seoul' },
    custom_attributes: {},
  },
];

export const mockCannedResponses = [
  {
    id: 1,
    short_code: 'hello',
    content: 'Hi there! How can I help you today?',
  },
  {
    id: 2,
    short_code: 'thanks',
    content: 'Thanks for reaching out, we appreciate it!',
  },
  {
    id: 3,
    short_code: 'refund',
    content: 'I have started the refund process for you.',
  },
];

export const mockCustomAttributes = [
  {
    id: 1,
    attribute_display_name: 'Plan Tier',
    attribute_key: 'plan_tier',
    attribute_display_type: 'list',
    attribute_model: 'conversation_attribute',
    attribute_values: ['Free', 'Pro', 'Enterprise'],
    attribute_description: 'Customer subscription tier',
  },
  {
    id: 2,
    attribute_display_name: 'Order ID',
    attribute_key: 'order_id',
    attribute_display_type: 'text',
    attribute_model: 'conversation_attribute',
    attribute_values: [],
    attribute_description: 'Related order identifier',
  },
  {
    id: 3,
    attribute_display_name: 'Company Size',
    attribute_key: 'company_size',
    attribute_display_type: 'number',
    attribute_model: 'contact_attribute',
    attribute_values: [],
    attribute_description: 'Number of employees',
  },
];

export const mockMacros = [
  {
    id: 1,
    name: 'Close & thank',
    visibility: 'global',
    account_id: 1,
    actions: [
      {
        action_name: 'send_message',
        action_params: ['Thanks, closing this now.'],
      },
      { action_name: 'change_status', action_params: ['resolved'] },
    ],
  },
  {
    id: 2,
    name: 'Escalate to Sales',
    visibility: 'global',
    account_id: 1,
    actions: [{ action_name: 'assign_team', action_params: [1] }],
  },
];

export const mockAutomationRules = [
  {
    id: 1,
    name: 'Auto-assign new WhatsApp chats',
    description: 'Assigns incoming WhatsApp conversations to Support',
    event_name: 'conversation_created',
    active: true,
    account_id: 1,
    conditions: [
      { attribute_key: 'inbox_id', filter_operator: 'equal_to', values: [2] },
    ],
    actions: [{ action_name: 'assign_team', action_params: [2] }],
  },
];

export const mockCampaigns = [
  {
    id: 1,
    title: 'Welcome new visitors',
    description: 'Trigger a greeting on the pricing page',
    campaign_type: 'ongoing',
    campaign_status: 'active',
    enabled: true,
    inbox: {
      id: 1,
      name: 'Website Widget',
      channel_type: 'Channel::WebWidget',
    },
    message: 'Hi! Looking for anything specific?',
    trigger_rules: { url: 'https://dakshai.example.com/pricing' },
    created_at: '2026-07-01T00:00:00.000Z',
  },
];

export const mockConversations = {
  meta: {
    mine_count: 3,
    unassigned_count: 1,
    all_count: 4,
    assigned_count: 3,
  },
  payload: [
    {
      id: 1,
      account_id: 1,
      inbox_id: 1,
      status: 'open',
      priority: 'urgent',
      unread_count: 1,
      agent_last_seen_at: 1723500000,
      user_last_seen_at: 1723500500,
      timestamp: 1723500500,
      created_at: 1723500000,
      labels: ['billing'],
      meta: {
        sender: {
          id: 101,
          name: 'Alice Johnson',
          email: 'alice@example.com',
          thumbnail: '',
        },
        assignee: {
          id: 1,
          name: 'John Doe',
          email: 'john.doe@example.com',
          thumbnail: '',
        },
        team: null,
        channel: 'Channel::WebWidget',
      },
      messages: [
        {
          id: 1001,
          content: 'Hello! I need help with my account billing.',
          message_type: 0,
          content_type: 'text',
          created_at: 1723500000,
          conversation_id: 1,
          sender: {
            id: 101,
            name: 'Alice Johnson',
            thumbnail: '',
          },
        },
        {
          id: 1002,
          content:
            "Hi Alice! I'd be happy to assist you with your billing inquiry.",
          message_type: 1,
          content_type: 'text',
          created_at: 1723500500,
          conversation_id: 1,
          sender: { id: 1, name: 'John Doe' },
        },
      ],
    },
    {
      id: 2,
      account_id: 1,
      inbox_id: 2,
      status: 'open',
      priority: null,
      unread_count: 0,
      timestamp: 1723490000,
      created_at: 1723490000,
      labels: [],
      meta: {
        sender: {
          id: 102,
          name: 'Bob Williams',
          email: 'bob@example.com',
          thumbnail: '',
        },
        assignee: null,
        team: null,
        channel: 'Channel::Whatsapp',
      },
      messages: [
        {
          id: 2001,
          content: 'Is support available over WhatsApp right now?',
          message_type: 0,
          content_type: 'text',
          created_at: 1723490000,
          conversation_id: 2,
          sender: {
            id: 102,
            name: 'Bob Williams',
            thumbnail: '',
          },
        },
      ],
    },
    {
      id: 3,
      account_id: 1,
      inbox_id: 3,
      status: 'open',
      priority: 'high',
      unread_count: 2,
      timestamp: 1723480000,
      created_at: 1723480000,
      labels: ['feature_request'],
      meta: {
        sender: {
          id: 103,
          name: 'Carla Mendes',
          email: 'carla@example.com',
          thumbnail: '',
        },
        assignee: {
          id: 2,
          name: 'Sarah Smith',
          email: 'sarah.smith@example.com',
          thumbnail: '',
        },
        team: { id: 2, name: 'Support' },
        channel: 'Channel::Email',
      },
      messages: [
        {
          id: 3001,
          content: 'Could you add dark mode to the dashboard?',
          message_type: 0,
          content_type: 'text',
          created_at: 1723480000,
          conversation_id: 3,
          sender: {
            id: 103,
            name: 'Carla Mendes',
            thumbnail: '',
          },
        },
      ],
    },
    {
      id: 4,
      account_id: 1,
      inbox_id: 1,
      status: 'resolved',
      priority: null,
      unread_count: 0,
      timestamp: 1723470000,
      created_at: 1723470000,
      labels: ['vip'],
      meta: {
        sender: {
          id: 104,
          name: 'David Kim',
          email: 'david@example.com',
          thumbnail: '',
        },
        assignee: {
          id: 1,
          name: 'John Doe',
          email: 'john.doe@example.com',
          thumbnail: '',
        },
        team: { id: 1, name: 'Sales' },
        channel: 'Channel::WebWidget',
      },
      messages: [
        {
          id: 4001,
          content: 'Thanks, everything works now!',
          message_type: 0,
          content_type: 'text',
          created_at: 1723470000,
          conversation_id: 4,
          sender: {
            id: 104,
            name: 'David Kim',
            thumbnail: '',
          },
        },
      ],
    },
  ],
};

// Inbox / notification feed. Each item's `primary_actor` is a full
// conversation object (the InboxView finds the active item by
// `primary_actor.id`). Store reads `response.data.{ payload, meta }` and
// camelCases keys, so `read_at` → `readAt`, `primary_actor` → `primaryActor`.
export const mockNotifications = [
  {
    id: 1,
    notification_type: 'conversation_assignment',
    read_at: null,
    snoozed_until: null,
    last_activity_at: 1723500500,
    created_at: 1723500500,
    primary_actor_type: 'Conversation',
    primary_actor_id: 1,
    primary_actor: mockConversations.payload[0],
    push_message_title: 'A conversation was assigned to you',
  },
  {
    id: 2,
    notification_type: 'conversation_mention',
    read_at: null,
    snoozed_until: null,
    last_activity_at: 1723480000,
    created_at: 1723480000,
    primary_actor_type: 'Conversation',
    primary_actor_id: 3,
    primary_actor: mockConversations.payload[2],
    push_message_title: 'You were mentioned in a conversation',
  },
  {
    id: 3,
    notification_type: 'conversation_creation',
    read_at: 1723471000,
    snoozed_until: null,
    last_activity_at: 1723470000,
    created_at: 1723470000,
    primary_actor_type: 'Conversation',
    primary_actor_id: 2,
    primary_actor: mockConversations.payload[1],
    push_message_title: 'A new conversation was created',
  },
];

const mockNotificationsUnreadCount = mockNotifications.filter(
  n => !n.read_at
).length;

// Cache keys returned per model. CacheEnabledApiClient reads
// `data.cache_keys[modelName]`; any stable value forces a network refetch
// (local IndexedDB has no matching key), which is what we want in mock mode.
const mockCacheKeys = {
  label: 1,
  inbox: 1,
  team: 1,
  conversation: 1,
};

export const handleMockRequest = (reqUrl, method) => {
  const url = new URL(reqUrl, 'http://localhost');
  const path = url.pathname;

  // Profile & Auth
  // validate_token wraps the user as `{ payload: { data: user } }`
  // (store reads response.data.payload.data).
  if (path.includes('/auth/validate_token')) {
    return { status: 200, data: { payload: { data: mockProfile } } };
  }

  // /api/v1/profile (GET + PUT for ui_settings, availability, avatar, etc.)
  // returns the user OBJECT directly — the store commits response.data as-is.
  if (path.includes('/api/v1/profile')) {
    return { status: 200, data: mockProfile };
  }

  if (path.includes('/auth/sign_in')) {
    return { status: 200, data: { data: mockProfile } };
  }

  // Cache keys (must precede the accounts matcher — needed by inboxes/labels)
  if (path.includes('/cache_keys')) {
    return { status: 200, data: { cache_keys: mockCacheKeys } };
  }

  // Accounts list
  if (path.match(/\/api\/v1\/accounts\/?$/)) {
    return { status: 200, data: [mockAccount] };
  }
  // Single account details
  if (path.match(/\/api\/v1\/accounts\/\d+\/?$/)) {
    return { status: 200, data: mockAccount };
  }

  // Custom views (custom_filters) — store maps over the raw array
  if (path.includes('/custom_filters')) {
    return { status: 200, data: [] };
  }

  // Conversation meta & unread counts
  if (path.includes('/conversations/meta')) {
    return { status: 200, data: mockConversations.meta };
  }
  if (path.includes('/conversations/unread_counts')) {
    return {
      status: 200,
      data: { mine_count: 3, unassigned_count: 1, all_count: 4 },
    };
  }

  // Conversations list — store reads `response.data.data.{meta,payload}`.
  // Return the list only for page 1; an empty payload on later pages tells the
  // list it has reached the end, otherwise "load more" loops forever.
  if (path.includes('/api/v1/accounts/') && path.includes('/conversations')) {
    if (method === 'GET') {
      const page = Number(url.searchParams.get('page') || 1);
      const payload = page > 1 ? [] : mockConversations.payload;
      return {
        status: 200,
        data: { data: { meta: mockConversations.meta, payload } },
      };
    }
    return { status: 200, data: mockConversations.payload[0] };
  }

  // Inboxes
  if (path.includes('/api/v1/accounts/') && path.includes('/inboxes')) {
    return { status: 200, data: { payload: mockInboxes } };
  }

  // Agents
  if (path.includes('/api/v1/accounts/') && path.includes('/agents')) {
    return { status: 200, data: mockAgents };
  }

  // Labels
  if (path.includes('/api/v1/accounts/') && path.includes('/labels')) {
    return { status: 200, data: { payload: mockLabels } };
  }

  // Teams (store SET_TEAMS iterates the raw array)
  if (path.includes('/teams')) {
    return { status: 200, data: mockTeams };
  }

  // Contacts — store reads `response.data.{payload,meta}`
  if (path.includes('/contacts')) {
    return {
      status: 200,
      data: {
        payload: mockContacts,
        meta: { count: mockContacts.length, current_page: 1 },
      },
    };
  }

  // Canned responses — store commits the raw array (`response.data`)
  if (path.includes('/canned_responses')) {
    return { status: 200, data: mockCannedResponses };
  }

  // Custom attribute definitions — store commits the raw array
  if (path.includes('/custom_attribute_definitions')) {
    return { status: 200, data: mockCustomAttributes };
  }

  // Macros — store reads `response.data.payload`
  if (path.includes('/macros')) {
    return { status: 200, data: { payload: mockMacros } };
  }

  // Automation rules — store reads `response.data.payload`
  if (path.includes('/automation_rules')) {
    return { status: 200, data: { payload: mockAutomationRules } };
  }

  // Campaigns — store commits the raw array (`response.data`)
  if (path.includes('/campaigns')) {
    return { status: 200, data: mockCampaigns };
  }

  // Notifications unread count — mutation stores the raw number
  if (path.includes('/notifications/unread_count')) {
    return { status: 200, data: mockNotificationsUnreadCount };
  }

  // Notifications list (Inbox view) — store reads the DOUBLE-nested
  // `response.data.data.{payload,meta}`. Empty payload on later pages so the
  // list stops paginating.
  if (path.includes('/notifications')) {
    const page = Number(url.searchParams.get('page') || 1);
    const payload = page > 1 ? [] : mockNotifications;
    return {
      status: 200,
      data: {
        data: {
          payload,
          meta: {
            count: mockNotifications.length,
            current_page: page,
            unread_count: mockNotificationsUnreadCount,
          },
        },
      },
    };
  }

  // Facebook Callbacks
  if (path.includes('/callbacks/facebook_pages')) {
    return {
      status: 200,
      data: {
        data: {
          user_access_token: 'mock-user-access-token',
          page_details: [
            {
              id: '123456789',
              name: 'Sample Facebook Page',
              access_token: 'mock-page-access-token',
              exists: false,
            },
          ],
        },
      },
    };
  }

  if (path.includes('/callbacks/register_facebook_page')) {
    return {
      status: 200,
      data: {
        id: 99,
        channel_id: 99,
        name: 'Sample Facebook Page',
        channel_type: 'Channel::FacebookPage',
        avatar_url: '',
        page_id: '123456789',
        enable_auto_assignment: true,
      },
    };
  }

  // Generic fallback for any unhandled /api request in mock mode
  if (path.startsWith('/api')) {
    return { status: 200, data: { payload: [], data: [] } };
  }

  return null;
};
