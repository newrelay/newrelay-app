const FEATURE_HELP_URLS = {
  agent_bots: 'https://newrelay.com/hc/agent-bots',
  agents: 'https://newrelay.com/hc/agents',
  audit_logs: 'https://newrelay.com/hc/audit-logs',
  campaigns: 'https://newrelay.com/hc/campaigns',
  canned_responses: 'https://newrelay.com/hc/canned',
  channel_email: 'https://newrelay.com/hc/email',
  channel_facebook: 'https://newrelay.com/hc/fb',
  custom_attributes: 'https://newrelay.com/hc/custom-attributes',
  dashboard_apps: 'https://newrelay.com/hc/dashboard-apps',
  help_center: 'https://newrelay.com/hc/help-center',
  inboxes: 'https://newrelay.com/hc/inboxes',
  integrations: 'https://newrelay.com/hc/integrations',
  labels: 'https://newrelay.com/hc/labels',
  macros: 'https://newrelay.com/hc/macros',
  reports: 'https://newrelay.com/hc/reports',
  sla: 'https://newrelay.com/hc/sla',
  team_management: 'https://newrelay.com/hc/teams',
  webhook: 'https://newrelay.com/hc/webhooks',
  billing: 'https://newrelay.com/pricing',
  saml: 'https://newrelay.com/hc/saml',
  captain_billing: 'https://newrelay.com/hc/captain_billing',
};

export function getHelpUrlForFeature(featureName) {
  return FEATURE_HELP_URLS[featureName];
}
