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
  reputation_demo_surfaces: true,
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
      name: 'NewRelay Workspace',
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
  name: 'NewRelay Workspace',
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
    email: 'support@newrelay.example.com',
  },
  {
    id: 4,
    name: 'Instagram Shop',
    channel_type: 'Channel::Instagram',
    avatar_url: '',
  },
  {
    id: 5,
    name: 'Facebook Page',
    channel_type: 'Channel::FacebookPage',
    avatar_url: '',
    page_id: '123456789',
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
    trigger_rules: { url: 'https://newrelay.example.com/pricing' },
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

const unixNow = () => Math.floor(Date.now() / 1000);
const hoursAgo = hours => unixNow() - hours * 3600;

const inboxSnapshot = inbox => ({
  id: inbox.id,
  name: inbox.name,
  channel_type: inbox.channel_type,
});

const mockInstagramInbox = inboxSnapshot(mockInboxes[3]);
const mockFacebookInbox = inboxSnapshot(mockInboxes[4]);
const mockWhatsappInbox = inboxSnapshot(mockInboxes[1]);

let nextCommentAutomationCampaignId = 5;
let nextCommentAutomationTriggerId = 50;
let nextCommentAutomationTemplateId = 5;

let mockCommentAutomationCampaigns = [
  {
    id: 1,
    name: 'Summer Sale Comment Auto-DM',
    post_id: 'ig-post-summer-sale',
    is_active: true,
    created_at: hoursAgo(24 * 12),
    updated_at: hoursAgo(6),
    inbox: mockInstagramInbox,
    trigger: {
      id: 11,
      keyword: 'PRICE',
      match_type: 'contains',
      public_replies: [
        'Thanks for asking — check your DMs for the offer!',
        'Sale details are in your inbox 🙌',
      ],
      dm_text_body: 'Here is 40% off this week: https://shop.example.com/sale',
    },
    responses_count: 48,
  },
  {
    id: 2,
    name: 'Product Launch Inquiries',
    post_id: 'ig-post-smartwatch',
    is_active: true,
    created_at: hoursAgo(24 * 8),
    updated_at: hoursAgo(20),
    inbox: mockInstagramInbox,
    trigger: {
      id: 12,
      keyword: 'INFO',
      match_type: 'exact',
      public_replies: ['Sent you the spec sheet via DM!'],
      dm_text_body:
        'Smartwatch Pro ships next week. Reply here with your size.',
    },
    responses_count: 31,
  },
  {
    id: 3,
    name: 'Giveaway Auto-Reply',
    post_id: 'fb-post-giveaway',
    is_active: false,
    created_at: hoursAgo(24 * 14),
    updated_at: hoursAgo(24 * 2),
    inbox: mockFacebookInbox,
    trigger: {
      id: 13,
      keyword: 'GIVEAWAY',
      match_type: 'contains',
      public_replies: ['You are entered — watch your messages!'],
      dm_text_body: 'Thanks for entering. Winner announced Friday.',
    },
    responses_count: 12,
  },
  {
    id: 4,
    name: 'WhatsApp Welcome Keyword',
    post_id: 'wa-post-welcome',
    is_active: true,
    created_at: hoursAgo(24 * 4),
    updated_at: hoursAgo(2),
    inbox: mockWhatsappInbox,
    trigger: {
      id: 14,
      keyword: 'HELLO',
      match_type: 'contains',
      public_replies: ['Welcome! We just sent you a DM.'],
      dm_text_body: 'Hi! How can we help you today?',
    },
    responses_count: 8,
  },
];

let mockCommentAutomationTemplates = [
  {
    id: 1,
    name: 'Lead Qualification DM',
    template_type: 'message',
    public_replies: ['Thanks — I sent details to your DMs!'],
    dm_text_body: 'Want the price list or a demo? Reply PRICE or DEMO.',
    favorite: true,
    usage_count: 2,
    created_at: hoursAgo(24 * 20),
    updated_at: hoursAgo(24 * 3),
  },
  {
    id: 2,
    name: 'Comment Acknowledgement',
    template_type: 'comment',
    public_replies: [
      'Thanks for the comment, sending you more info now.',
      'Appreciate you reaching out — check your DMs!',
    ],
    dm_text_body: 'Here is the info you asked for.',
    favorite: true,
    usage_count: 1,
    created_at: hoursAgo(24 * 10),
    updated_at: hoursAgo(24 * 1),
  },
  {
    id: 3,
    name: 'Product Info Reply',
    template_type: 'message',
    public_replies: ['Specs are in your inbox.'],
    dm_text_body: 'Battery life is 36 hours. Ships in 3–5 days.',
    favorite: false,
    usage_count: 0,
    created_at: hoursAgo(24 * 6),
    updated_at: hoursAgo(24 * 6),
  },
  {
    id: 4,
    name: 'Out of Stock',
    template_type: 'comment',
    public_replies: ['This drop sold out — DM for restock alerts.'],
    dm_text_body: 'Want a restock ping? Reply YES and we will notify you.',
    favorite: false,
    usage_count: 0,
    created_at: hoursAgo(24 * 2),
    updated_at: hoursAgo(24 * 2),
  },
];

let mockSocialAccounts = [
  {
    id: 'acc-1',
    name: 'Main',
    handle: '@newrelay',
    platform: 'Instagram',
    avatar:
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    status: 'Connected',
    automationsCount: 4,
    followersCount: '12,482 Followers',
    assignedTeam: 'Sales Team',
    accessLevel: 'Manager',
    lastSync: 'Just now',
    assignedMembers: [
      {
        id: 'u-1',
        name: 'John Smith',
        email: 'john@example.com',
        avatar: 'https://i.pravatar.cc/150?u=john',
        role: 'Manager',
      },
      {
        id: 'u-2',
        name: 'Sarah Miller',
        email: 'sarah@example.com',
        avatar: 'https://i.pravatar.cc/150?u=sarah',
        role: 'Operator',
      },
    ],
  },
  {
    id: 'acc-2',
    name: 'Support',
    handle: '@newrelay.support',
    platform: 'Instagram',
    avatar:
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    status: 'Connected',
    automationsCount: 7,
    followersCount: '5,821 Followers',
    assignedTeam: 'Support Team',
    accessLevel: 'Manager',
    lastSync: '5 mins ago',
    assignedMembers: [
      {
        id: 'u-3',
        name: 'Elena Rostova',
        email: 'elena@example.com',
        avatar: 'https://i.pravatar.cc/150?u=elena',
        role: 'Manager',
      },
    ],
  },
  {
    id: 'acc-3',
    name: 'Store',
    handle: '@newrelay.store',
    platform: 'Instagram',
    avatar:
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
    status: 'Connected',
    automationsCount: 3,
    followersCount: '8,150 Followers',
    assignedTeam: 'E-commerce Team',
    accessLevel: 'Operator',
    lastSync: '12 mins ago',
    assignedMembers: [
      {
        id: 'u-5',
        name: 'Michael Chang',
        email: 'michael@example.com',
        avatar: 'https://i.pravatar.cc/150?u=michael',
        role: 'Operator',
      },
    ],
  },
  {
    id: 'acc-4',
    name: 'Official Page',
    handle: 'fb.com/newrelay-official',
    platform: 'Facebook',
    avatar:
      'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    status: 'Connected',
    automationsCount: 5,
    followersCount: '24,300 Likes',
    assignedTeam: 'Marketing Team',
    accessLevel: 'Manager',
    lastSync: '1 hour ago',
    assignedMembers: [
      {
        id: 'u-1',
        name: 'John Smith',
        email: 'john@example.com',
        avatar: 'https://i.pravatar.cc/150?u=john',
        role: 'Manager',
      },
    ],
  },
];

const mockAutoresponderTeamMembers = [
  {
    id: 'u-1',
    name: 'John Smith',
    email: 'john@example.com',
    avatar: 'https://i.pravatar.cc/150?u=john',
  },
  {
    id: 'u-2',
    name: 'Sarah Miller',
    email: 'sarah@example.com',
    avatar: 'https://i.pravatar.cc/150?u=sarah',
  },
  {
    id: 'u-3',
    name: 'Elena Rostova',
    email: 'elena@example.com',
    avatar: 'https://i.pravatar.cc/150?u=elena',
  },
  {
    id: 'u-4',
    name: 'David Vance',
    email: 'david@example.com',
    avatar: 'https://i.pravatar.cc/150?u=david',
  },
  {
    id: 'u-5',
    name: 'Michael Chang',
    email: 'michael@example.com',
    avatar: 'https://i.pravatar.cc/150?u=michael',
  },
  {
    id: 'u-6',
    name: 'Aisha Robinson',
    email: 'aisha@example.com',
    avatar: 'https://i.pravatar.cc/150?u=aisha',
  },
];

const mockAutoresponderTeams = [
  'Sales Team',
  'Support Team',
  'Marketing Team',
  'E-commerce Team',
  'Customer Care',
];

let mockResponseControlPosts = [
  {
    id: 1,
    title: 'Summer Sale 2026 - Up to 40% Off',
    type: 'Post',
    publishedAt: 'Aug 28, 2026',
    thumbnail:
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=300&auto=format&fit=crop&q=80',
    comments: {
      enabled: true,
      overridden: false,
      automation: 'Summer Sale Comment Auto-DM',
    },
    dms: {
      enabled: true,
      overridden: false,
      automation: 'Lead Qualification Bot',
    },
    stats: { commentsSent: 342, dmsSent: 289 },
  },
  {
    id: 2,
    title: 'Product Launch: NextGen Smartwatch Pro',
    type: 'Reel',
    publishedAt: 'Aug 25, 2026',
    thumbnail:
      'https://images.unsplash.com/photo-1508057198894-247b23fe5ade?w=300&auto=format&fit=crop&q=80',
    comments: {
      enabled: false,
      overridden: true,
      automation: 'General Comment Acknowledgement',
    },
    dms: {
      enabled: true,
      overridden: false,
      automation: 'Product Inquiries Autoresponder',
    },
    stats: { commentsSent: 0, dmsSent: 412 },
  },
  {
    id: 3,
    title: 'Giveaway: Win AirPods Max & Store Credit',
    type: 'Carousel',
    publishedAt: 'Aug 20, 2026',
    thumbnail:
      'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=300&auto=format&fit=crop&q=80',
    comments: {
      enabled: true,
      overridden: true,
      automation: 'Giveaway Entry Validator',
    },
    dms: {
      enabled: false,
      overridden: true,
      automation: 'Standard Welcome Flow',
    },
    stats: { commentsSent: 1240, dmsSent: 0 },
  },
  {
    id: 4,
    title: 'Behind The Scenes: How We Design Our Interfaces',
    type: 'Story',
    publishedAt: 'Aug 18, 2026',
    thumbnail:
      'https://images.unsplash.com/photo-1581291518857-4e27b48ff24e?w=300&auto=format&fit=crop&q=80',
    comments: {
      enabled: true,
      overridden: false,
      automation: 'Story Reply Capture',
    },
    dms: {
      enabled: true,
      overridden: false,
      automation: 'Story Mentions Auto-Reply',
    },
    stats: { commentsSent: 88, dmsSent: 120 },
  },
  {
    id: 5,
    title: 'Customer Spotlight: How BrandX Scaled 500%',
    type: 'Post',
    publishedAt: 'Aug 12, 2026',
    thumbnail:
      'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=300&auto=format&fit=crop&q=80',
    comments: {
      enabled: true,
      overridden: false,
      automation: 'Case Study Request Reply',
    },
    dms: {
      enabled: true,
      overridden: false,
      automation: 'Enterprise Lead Route',
    },
    stats: { commentsSent: 215, dmsSent: 198 },
  },
];

let mockResponseControlDms = [
  {
    id: 'general_dm',
    name: 'General Inbound DMs',
    description: 'Auto-reply to incoming customer questions in Direct Messages',
    enabled: true,
    overridden: false,
    automation: 'Relay AI Smart Concierge',
    stats: '1,420 replies sent this month',
  },
  {
    id: 'new_followers',
    name: 'New Follower Welcome DM',
    description:
      'Send automated welcome message when a new user follows your profile',
    enabled: true,
    overridden: true,
    automation: 'New Follower Onboarding',
    stats: '680 DMs dispatched',
  },
  {
    id: 'story_mentions',
    name: 'Story Mentions & Tags',
    description:
      'Instantly respond in DM when someone mentions your account in their Story',
    enabled: true,
    overridden: false,
    automation: 'Story Mention Acknowledgement',
    stats: '312 DMs dispatched',
  },
  {
    id: 'message_requests',
    name: 'Hidden / Message Requests Filter',
    description:
      'Auto-screen and respond to pending message requests from non-followers',
    enabled: false,
    overridden: true,
    automation: 'Spam Prevention & Filter',
    stats: '0 replies (Paused)',
  },
];

let mockResponseControlDefaults = { comments: true, dms: true };

const mockResponseControlAutomations = [
  'Summer Sale Comment Auto-DM',
  'Lead Qualification Bot',
  'Giveaway Entry Validator',
  'Product Inquiries Autoresponder',
  'Relay AI Smart Concierge',
  'Story Mention Acknowledgement',
];

const mockCommentAutomationLogs = [
  {
    id: 1,
    comment_id: 'ig-comment-9011',
    commenter_id: 'ig-user-alice',
    status: 'engaged',
    sent_at: hoursAgo(2),
    created_at: hoursAgo(3),
    inbox: mockInstagramInbox,
    campaign: { id: 1, name: 'Summer Sale Comment Auto-DM' },
    trigger: { id: 11, keyword: 'PRICE' },
    contact: {
      id: 101,
      name: 'Alice Johnson',
      avatar_url: 'https://i.pravatar.cc/150?u=alice',
    },
  },
  {
    id: 2,
    comment_id: 'ig-comment-9012',
    commenter_id: 'ig-user-bob',
    status: 'dm_sent',
    sent_at: hoursAgo(8),
    created_at: hoursAgo(9),
    inbox: mockInstagramInbox,
    campaign: { id: 2, name: 'Product Launch Inquiries' },
    trigger: { id: 12, keyword: 'INFO' },
    contact: {
      id: 102,
      name: 'Bob Williams',
      avatar_url: 'https://i.pravatar.cc/150?u=bob',
    },
  },
  {
    id: 3,
    comment_id: 'ig-comment-9013',
    commenter_id: 'ig-user-carla',
    status: 'public_replied',
    sent_at: null,
    created_at: hoursAgo(14),
    inbox: mockInstagramInbox,
    campaign: { id: 1, name: 'Summer Sale Comment Auto-DM' },
    trigger: { id: 11, keyword: 'PRICE' },
    contact: {
      id: 103,
      name: 'Carla Mendes',
      avatar_url: 'https://i.pravatar.cc/150?u=carla',
    },
  },
  {
    id: 4,
    comment_id: 'fb-comment-4401',
    commenter_id: 'fb-user-david',
    status: 'dm_failed',
    sent_at: hoursAgo(26),
    created_at: hoursAgo(27),
    inbox: mockFacebookInbox,
    campaign: { id: 3, name: 'Giveaway Auto-Reply' },
    trigger: { id: 13, keyword: 'GIVEAWAY' },
    contact: {
      id: 104,
      name: 'David Kim',
      avatar_url: 'https://i.pravatar.cc/150?u=david',
    },
  },
  {
    id: 5,
    comment_id: 'wa-comment-1102',
    commenter_id: 'wa-user-unknown',
    status: 'pending',
    sent_at: null,
    created_at: hoursAgo(5),
    inbox: mockWhatsappInbox,
    campaign: { id: 4, name: 'WhatsApp Welcome Keyword' },
    trigger: { id: 14, keyword: 'HELLO' },
    contact: null,
  },
  {
    id: 6,
    comment_id: 'ig-comment-9014',
    commenter_id: 'ig-user-alice',
    status: 'engaged',
    sent_at: hoursAgo(30),
    created_at: hoursAgo(31),
    inbox: mockInstagramInbox,
    campaign: { id: 2, name: 'Product Launch Inquiries' },
    trigger: { id: 12, keyword: 'INFO' },
    contact: {
      id: 101,
      name: 'Alice Johnson',
      avatar_url: 'https://i.pravatar.cc/150?u=alice',
    },
  },
  {
    id: 7,
    comment_id: 'ig-comment-9015',
    commenter_id: 'ig-user-priya',
    status: 'dm_sent',
    sent_at: hoursAgo(48),
    created_at: hoursAgo(49),
    inbox: mockInstagramInbox,
    campaign: { id: 1, name: 'Summer Sale Comment Auto-DM' },
    trigger: { id: 11, keyword: 'PRICE' },
    contact: {
      id: 105,
      name: 'Priya Nair',
      avatar_url: 'https://i.pravatar.cc/150?u=priya',
    },
  },
  {
    id: 8,
    comment_id: 'fb-comment-4402',
    commenter_id: 'fb-user-miguel',
    status: 'engaged',
    sent_at: hoursAgo(72),
    created_at: hoursAgo(73),
    inbox: mockFacebookInbox,
    campaign: { id: 3, name: 'Giveaway Auto-Reply' },
    trigger: { id: 13, keyword: 'GIVEAWAY' },
    contact: {
      id: 3,
      name: 'Miguel Torres',
      avatar_url: 'https://i.pravatar.cc/150?u=miguel',
    },
  },
  {
    id: 9,
    comment_id: 'wa-comment-1103',
    commenter_id: 'wa-user-sarah',
    status: 'dm_sent',
    sent_at: hoursAgo(96),
    created_at: hoursAgo(97),
    inbox: mockWhatsappInbox,
    campaign: { id: 4, name: 'WhatsApp Welcome Keyword' },
    trigger: { id: 14, keyword: 'HELLO' },
    contact: {
      id: 2,
      name: 'Sarah Smith',
      avatar_url: 'https://i.pravatar.cc/150?u=sarah',
    },
  },
  {
    id: 10,
    comment_id: 'ig-comment-9016',
    commenter_id: 'ig-user-nina',
    status: 'public_replied',
    sent_at: null,
    created_at: hoursAgo(120),
    inbox: mockInstagramInbox,
    campaign: { id: 1, name: 'Summer Sale Comment Auto-DM' },
    trigger: { id: 11, keyword: 'PRICE' },
    contact: {
      id: 106,
      name: 'Nina Patel',
      avatar_url: 'https://i.pravatar.cc/150?u=nina',
    },
  },
  {
    id: 11,
    comment_id: 'ig-comment-9017',
    commenter_id: 'ig-user-liam',
    status: 'dm_failed',
    sent_at: hoursAgo(140),
    created_at: hoursAgo(141),
    inbox: mockInstagramInbox,
    campaign: { id: 2, name: 'Product Launch Inquiries' },
    trigger: { id: 12, keyword: 'INFO' },
    contact: null,
  },
  {
    id: 12,
    comment_id: 'ig-comment-9018',
    commenter_id: 'ig-user-tom',
    status: 'engaged',
    sent_at: hoursAgo(4),
    created_at: hoursAgo(5),
    inbox: mockInstagramInbox,
    campaign: { id: 1, name: 'Summer Sale Comment Auto-DM' },
    trigger: { id: 11, keyword: 'PRICE' },
    contact: {
      id: 107,
      name: 'Tom Becker',
      avatar_url: 'https://i.pravatar.cc/150?u=tom',
    },
  },
];

const commentAutomationItemId = (path, resource) => {
  const match = path.match(
    new RegExp(`/comment_automation/${resource}/(\\d+)`)
  );
  return match ? Number(match[1]) : null;
};

const isCommentAutomationCollection = (path, resource) =>
  new RegExp(`/comment_automation/${resource}/?$`).test(path);

const findMockInbox = id =>
  mockInboxes.find(inbox => inbox.id === Number(id)) || mockInboxes[3];

const handleCommentAutomationCampaigns = (path, method, body) => {
  const id = commentAutomationItemId(path, 'campaigns');

  if (id && (method === 'PATCH' || method === 'PUT')) {
    const campaign = mockCommentAutomationCampaigns.find(
      item => item.id === id
    );
    if (!campaign) return { status: 404, data: { error: 'Not found' } };
    Object.assign(campaign, body?.campaign || {});
    if (body?.trigger && campaign.trigger) {
      Object.assign(campaign.trigger, body.trigger);
    }
    campaign.updated_at = unixNow();
    return { status: 200, data: campaign };
  }

  if (id && method === 'DELETE') {
    mockCommentAutomationCampaigns = mockCommentAutomationCampaigns.filter(
      item => item.id !== id
    );
    return { status: 200, data: {} };
  }

  if (isCommentAutomationCollection(path, 'campaigns') && method === 'POST') {
    const attrs = body?.campaign || {};
    const triggerAttrs = body?.trigger || {};
    const inbox = inboxSnapshot(findMockInbox(attrs.inbox_id));
    const campaign = {
      id: nextCommentAutomationCampaignId,
      name: attrs.name || 'New automation',
      post_id: attrs.post_id || `mock-post-${nextCommentAutomationCampaignId}`,
      is_active: attrs.is_active !== false,
      created_at: unixNow(),
      updated_at: unixNow(),
      inbox,
      trigger: {
        id: nextCommentAutomationTriggerId,
        keyword: triggerAttrs.keyword || '',
        match_type: triggerAttrs.match_type || 'contains',
        public_replies: triggerAttrs.public_replies || [],
        dm_text_body: triggerAttrs.dm_text_body || '',
      },
      responses_count: 0,
    };
    nextCommentAutomationCampaignId += 1;
    nextCommentAutomationTriggerId += 1;
    mockCommentAutomationCampaigns.unshift(campaign);
    return { status: 200, data: campaign };
  }

  if (isCommentAutomationCollection(path, 'campaigns')) {
    return { status: 200, data: { payload: mockCommentAutomationCampaigns } };
  }

  return null;
};

const handleCommentAutomationTemplates = (path, method, body) => {
  const id = commentAutomationItemId(path, 'templates');

  if (id && (method === 'PATCH' || method === 'PUT')) {
    const template = mockCommentAutomationTemplates.find(
      item => item.id === id
    );
    if (!template) return { status: 404, data: { error: 'Not found' } };
    Object.assign(template, body?.template || {});
    template.updated_at = unixNow();
    return { status: 200, data: template };
  }

  if (id && method === 'DELETE') {
    mockCommentAutomationTemplates = mockCommentAutomationTemplates.filter(
      item => item.id !== id
    );
    return { status: 200, data: {} };
  }

  if (isCommentAutomationCollection(path, 'templates') && method === 'POST') {
    const attrs = body?.template || {};
    const template = {
      id: nextCommentAutomationTemplateId,
      name: attrs.name || 'New template',
      template_type: attrs.template_type || 'message',
      public_replies: attrs.public_replies || [],
      dm_text_body: attrs.dm_text_body || '',
      favorite: !!attrs.favorite,
      usage_count: 0,
      created_at: unixNow(),
      updated_at: unixNow(),
    };
    nextCommentAutomationTemplateId += 1;
    mockCommentAutomationTemplates.unshift(template);
    return { status: 200, data: template };
  }

  if (isCommentAutomationCollection(path, 'templates')) {
    return { status: 200, data: { payload: mockCommentAutomationTemplates } };
  }

  return null;
};

const commentAutomationResourceId = (path, resource) => {
  const match = path.match(
    new RegExp(`/comment_automation/${resource}/([^/?]+)`)
  );
  return match ? decodeURIComponent(match[1]) : null;
};

const handleCommentAutomationSocialAccounts = (path, method, body) => {
  if (path.includes('/social_accounts/sync') && method === 'POST') {
    mockSocialAccounts = mockSocialAccounts.map(account => ({
      ...account,
      lastSync: 'Just now',
    }));
    return { status: 200, data: { payload: mockSocialAccounts } };
  }

  const id = commentAutomationResourceId(path, 'social_accounts');
  if (id && (method === 'PATCH' || method === 'PUT')) {
    const account = mockSocialAccounts.find(item => String(item.id) === id);
    if (!account) return { status: 404, data: { error: 'Not found' } };
    Object.assign(account, body || {});
    return { status: 200, data: account };
  }

  if (
    isCommentAutomationCollection(path, 'social_accounts') &&
    method === 'POST'
  ) {
    const platform = body?.platform === 'Facebook' ? 'Facebook' : 'Instagram';
    const nextId = `acc-${mockSocialAccounts.length + 1}`;
    const account = {
      id: nextId,
      name: `New ${platform}`,
      handle:
        platform === 'Facebook' ? `fb.com/new-${nextId}` : `@new-${nextId}`,
      platform,
      avatar: `https://i.pravatar.cc/150?u=${nextId}`,
      status: 'Connected',
      automationsCount: 0,
      followersCount: platform === 'Facebook' ? '0 Likes' : '0 Followers',
      assignedTeam: 'Sales Team',
      accessLevel: 'Manager',
      lastSync: 'Just now',
      assignedMembers: [],
    };
    mockSocialAccounts.push(account);
    return { status: 201, data: account };
  }

  return {
    status: 200,
    data: {
      payload: mockSocialAccounts,
      meta: {
        teamMembers: mockAutoresponderTeamMembers,
        teams: mockAutoresponderTeams,
      },
    },
  };
};

const handleCommentAutomationResponseControls = (path, method, body) => {
  const id = commentAutomationResourceId(path, 'response_controls');

  if (id && (method === 'PATCH' || method === 'PUT')) {
    if (id === 'defaults') {
      Object.assign(mockResponseControlDefaults, body || {});
      return { status: 200, data: mockResponseControlDefaults };
    }

    const post = mockResponseControlPosts.find(item => String(item.id) === id);
    if (post) {
      if (body?.comments) Object.assign(post.comments, body.comments);
      if (body?.dms) Object.assign(post.dms, body.dms);
      return { status: 200, data: post };
    }

    const dm = mockResponseControlDms.find(item => String(item.id) === id);
    if (dm) {
      Object.assign(dm, body || {});
      return { status: 200, data: dm };
    }

    return { status: 404, data: { error: 'Not found' } };
  }

  if (isCommentAutomationCollection(path, 'response_controls')) {
    return {
      status: 200,
      data: {
        payload: {
          posts: mockResponseControlPosts,
          dms: mockResponseControlDms,
          defaults: mockResponseControlDefaults,
          automations: mockResponseControlAutomations,
        },
      },
    };
  }

  return {
    status: 200,
    data: {
      payload: {
        posts: mockResponseControlPosts,
        dms: mockResponseControlDms,
        defaults: mockResponseControlDefaults,
        automations: mockResponseControlAutomations,
      },
    },
  };
};

export const handleMockRequest = (reqUrl, method, body = null) => {
  const url = new URL(reqUrl, 'http://localhost');
  const path = url.pathname;

  // Autoresponder mock resources — check the raw URL too. Vite sometimes
  // passes req.url with a query string that pathname handling can miss.
  if (
    path.includes('/comment_automation/social_accounts') ||
    String(reqUrl).includes('/comment_automation/social_accounts')
  ) {
    const response = handleCommentAutomationSocialAccounts(path, method, body);
    if (response) return response;
  }
  if (
    path.includes('/comment_automation/response_controls') ||
    String(reqUrl).includes('/comment_automation/response_controls')
  ) {
    const response = handleCommentAutomationResponseControls(
      path,
      method,
      body
    );
    if (response) return response;
  }

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

  // Comment automation (Autoresponder) — must precede `/campaigns`
  if (path.includes('/comment_automation/campaigns')) {
    const response = handleCommentAutomationCampaigns(path, method, body);
    if (response) return response;
  }
  if (path.includes('/comment_automation/templates')) {
    const response = handleCommentAutomationTemplates(path, method, body);
    if (response) return response;
  }
  if (path.includes('/comment_automation/message_logs')) {
    return { status: 200, data: { payload: mockCommentAutomationLogs } };
  }

  // Marketing campaigns — store commits the raw array (`response.data`)
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
