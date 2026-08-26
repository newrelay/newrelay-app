export const NOTIFICATION_TYPES = [
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_CREATED',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.CONVERSATION_CREATED',
    value: 'conversation_creation',
    icon: 'i-lucide-message-square-plus',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_ASSIGNED',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.CONVERSATION_ASSIGNED',
    value: 'conversation_assignment',
    icon: 'i-lucide-user',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_MENTION',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.CONVERSATION_MENTION',
    value: 'conversation_mention',
    icon: 'i-lucide-at-sign',
  },
  {
    label:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.ASSIGNED_CONVERSATION_NEW_MESSAGE',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.ASSIGNED_CONVERSATION_NEW_MESSAGE',
    value: 'assigned_conversation_new_message',
    icon: 'i-lucide-message-circle',
  },
  {
    label:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.PARTICIPATING_CONVERSATION_NEW_MESSAGE',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.PARTICIPATING_CONVERSATION_NEW_MESSAGE',
    value: 'participating_conversation_new_message',
    icon: 'i-lucide-messages-square',
  },
  {
    label:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.SLA_MISSED_FIRST_RESPONSE',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.SLA_MISSED_FIRST_RESPONSE',
    value: 'sla_missed_first_response',
    icon: 'i-lucide-timer',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.SLA_MISSED_NEXT_RESPONSE',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.SLA_MISSED_NEXT_RESPONSE',
    value: 'sla_missed_next_response',
    icon: 'i-lucide-clock',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.SLA_MISSED_RESOLUTION',
    description:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.DESCRIPTIONS.SLA_MISSED_RESOLUTION',
    value: 'sla_missed_resolution',
    icon: 'i-lucide-alert-triangle',
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
