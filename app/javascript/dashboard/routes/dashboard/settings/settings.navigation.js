/**
 * Settings secondary navigation — mirrors new-ui SettingsView sections.
 * Route names / activeOn keep Chatwoot permissions + feature flags intact.
 */
export const SETTINGS_NAV_SECTIONS = [
  {
    key: 'general',
    labelKey: 'SIDEBAR.SETTINGS_SECTIONS.GENERAL',
    icon: 'i-lucide-building-2',
    items: [
      {
        key: 'workspace',
        labelKey: 'SIDEBAR.ACCOUNT_SETTINGS',
        routeName: 'general_settings_index',
      },
      {
        key: 'branding',
        labelKey: 'SIDEBAR.BRANDING',
        routeName: 'branding_settings_index',
      },
      {
        key: 'custom_domain',
        labelKey: 'SIDEBAR.CUSTOM_DOMAIN',
        routeName: 'custom_domain_settings_index',
      },
      {
        key: 'billing',
        labelKey: 'SIDEBAR.BILLING',
        routeName: 'billing_settings_index',
      },
    ],
  },
  {
    key: 'people',
    labelKey: 'SIDEBAR.SETTINGS_SECTIONS.PEOPLE',
    icon: 'i-lucide-users',
    items: [
      {
        key: 'agents',
        labelKey: 'SIDEBAR.AGENTS',
        routeName: 'agent_list',
      },
      {
        key: 'teams',
        labelKey: 'SIDEBAR.TEAMS',
        routeName: 'settings_teams_list',
        activeOn: [
          'settings_teams_list',
          'settings_teams_new',
          'settings_teams_finish',
          'settings_teams_add_agents',
          'settings_teams_show',
          'settings_teams_edit',
          'settings_teams_edit_members',
          'settings_teams_edit_finish',
        ],
      },
      {
        key: 'roles',
        labelKey: 'SIDEBAR.CUSTOM_ROLES',
        routeName: 'custom_roles_list',
      },
      {
        key: 'agent_assignment',
        labelKey: 'SIDEBAR.AGENT_ASSIGNMENT',
        routeName: 'assignment_policy_index',
        activeOn: [
          'assignment_policy_index',
          'agent_assignment_policy_index',
          'agent_assignment_policy_create',
          'agent_assignment_policy_edit',
          'agent_capacity_policy_index',
          'agent_capacity_policy_create',
          'agent_capacity_policy_edit',
        ],
        requiresAdvancedAssignment: true,
      },
    ],
  },
  {
    key: 'communication',
    labelKey: 'SIDEBAR.SETTINGS_SECTIONS.COMMUNICATION',
    icon: 'i-lucide-message-square',
    items: [
      {
        key: 'inboxes',
        labelKey: 'SIDEBAR.INBOXES',
        routeName: 'settings_inbox_list',
        activeOn: [
          'settings_inbox_list',
          'settings_inbox_show',
          'settings_inbox_new',
          'settings_inbox_finish',
          'settings_inboxes_page_channel',
          'settings_inboxes_add_agents',
        ],
      },
      {
        key: 'labels',
        labelKey: 'SIDEBAR.LABELS',
        routeName: 'labels_list',
      },
      {
        key: 'notifications',
        labelKey: 'SIDEBAR.NOTIFICATIONS',
        routeName: 'settings_notifications_index',
      },
    ],
  },
  {
    key: 'automation',
    labelKey: 'SIDEBAR.SETTINGS_SECTIONS.AUTOMATION',
    icon: 'i-lucide-bot',
    items: [
      {
        key: 'workflows',
        labelKey: 'SIDEBAR.CONVERSATION_WORKFLOW',
        routeName: 'conversation_workflow_index',
      },
      {
        key: 'bots',
        labelKey: 'SIDEBAR.AGENT_BOTS',
        routeName: 'agent_bots',
      },
      {
        key: 'macros',
        labelKey: 'SIDEBAR.MACROS',
        routeName: 'macros_wrapper',
        activeOn: ['macros_wrapper', 'macros_edit', 'macros_new'],
      },
      {
        key: 'canned',
        labelKey: 'SIDEBAR.CANNED_RESPONSES',
        routeName: 'canned_list',
      },
      {
        key: 'sla',
        labelKey: 'SIDEBAR.SLA',
        routeName: 'sla_list',
      },
    ],
  },
  {
    key: 'customer_data',
    labelKey: 'SIDEBAR.SETTINGS_SECTIONS.CUSTOMER_DATA',
    icon: 'i-lucide-database',
    items: [
      {
        key: 'custom_attributes',
        labelKey: 'SIDEBAR.CUSTOM_ATTRIBUTES',
        routeName: 'attributes_list',
      },
    ],
  },
  {
    key: 'integrations',
    labelKey: 'SIDEBAR.SETTINGS_SECTIONS.INTEGRATIONS',
    icon: 'i-lucide-plug',
    items: [
      {
        key: 'apps',
        labelKey: 'SIDEBAR.INTEGRATION_APPS',
        routeName: 'settings_applications',
        activeOn: [
          'settings_applications',
          'settings_applications_integration',
          'settings_integrations_dashboard_apps',
          'settings_integrations_slack',
          'settings_integrations_linear',
          'settings_integrations_notion',
          'settings_integrations_shopify',
        ],
      },
      {
        key: 'api_keys',
        labelKey: 'SIDEBAR.INTEGRATION_API_KEYS',
        routeName: 'settings_integrations_api_keys',
      },
      {
        key: 'webhooks',
        labelKey: 'SIDEBAR.INTEGRATION_WEBHOOKS',
        routeName: 'settings_integrations_webhook',
      },
    ],
  },
  {
    key: 'security',
    labelKey: 'SIDEBAR.SETTINGS_SECTIONS.SECURITY',
    icon: 'i-lucide-shield',
    items: [
      {
        key: 'security',
        labelKey: 'SIDEBAR.SECURITY',
        routeName: 'security_settings_index',
      },
      {
        key: 'audit_logs',
        labelKey: 'SIDEBAR.AUDIT_LOGS',
        routeName: 'auditlogs_list',
      },
    ],
  },
];

export const SETTINGS_ROUTE_NAMES = SETTINGS_NAV_SECTIONS.flatMap(section =>
  section.items.flatMap(item => [item.routeName, ...(item.activeOn || [])])
);
