export const NOTIFICATION_TYPES = [
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.NEW_REVIEW',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.NEW_REVIEW',
    value: 'new_review',
    icon: 'i-lucide-star',
    defaultTitle: 'New review received',
    defaultDescription: 'Get notified when a new review is received.',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.REVIEW_REPLY',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.REVIEW_REPLY',
    value: 'review_reply',
    icon: 'i-lucide-message-circle',
    defaultTitle: 'Review reply',
    defaultDescription: 'When someone replies to your review.',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.LISTING_DISCONNECTED',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.LISTING_DISCONNECTED',
    value: 'listing_disconnected',
    icon: 'i-lucide-link-2',
    defaultTitle: 'Listing disconnected',
    defaultDescription: 'When a listing or social account gets disconnected.',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.SYNC_FAILED',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.SYNC_FAILED',
    value: 'sync_failed',
    icon: 'i-lucide-refresh-cw',
    defaultTitle: 'Sync failed',
    defaultDescription: 'When a sync with a platform fails.',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_ASSIGNED',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.CONVERSATION_ASSIGNED',
    value: 'conversation_assignment',
    icon: 'i-lucide-user',
    defaultTitle: 'Conversation assigned',
    defaultDescription: 'When a conversation is assigned to you or your team.',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CAMPAIGN_COMPLETED',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.CAMPAIGN_COMPLETED',
    value: 'campaign_completed',
    icon: 'i-lucide-check-circle-2',
    defaultTitle: 'Campaign completed',
    defaultDescription: 'When a campaign has finished executing.',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.WORKFLOW_FAILED',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.WORKFLOW_FAILED',
    value: 'workflow_failed',
    icon: 'i-lucide-alert-triangle',
    defaultTitle: 'Workflow failed',
    defaultDescription: 'When a workflow execution fails.',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.TEAM_MEMBER_ADDED',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.TEAM_MEMBER_ADDED',
    value: 'team_member_added',
    icon: 'i-lucide-users',
    defaultTitle: 'Team member added',
    defaultDescription: 'When a new member joins the workspace.',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_CREATED',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.CONVERSATION_CREATED',
    value: 'conversation_creation',
    icon: 'i-lucide-message-square-plus',
    defaultTitle: 'New conversation',
    defaultDescription: 'Get notified when a new conversation is created.',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_MENTION',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.CONVERSATION_MENTION',
    value: 'conversation_mention',
    icon: 'i-lucide-at-sign',
    defaultTitle: 'Conversation mention',
    defaultDescription: 'When you are mentioned in a conversation.',
  },
];

export const EVENT_TYPES = {
  ASSIGNED: 'assigned',
  NOTME: 'notme',
  UNASSIGNED: 'unassigned',
};

export const ALERT_EVENTS = [
  {
    value: EVENT_TYPES.ASSIGNED,
    label: 'assigned',
  },
  {
    value: EVENT_TYPES.UNASSIGNED,
    label: 'unassigned',
  },
  {
    value: EVENT_TYPES.NOTME,
    label: 'notme',
  },
];
