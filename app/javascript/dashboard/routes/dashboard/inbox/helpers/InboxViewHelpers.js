export const NOTIFICATION_TYPES_MAPPING = {
  CONVERSATION_MENTION: ['i-lucide-at-sign', 'text-primary'],
  CONVERSATION_ASSIGNMENT: ['i-lucide-chevrons-right', 'text-primary'],
  CONVERSATION_CREATION: ['i-lucide-mail-plus', 'text-primary'],
  PARTICIPATING_CONVERSATION_NEW_MESSAGE: [
    'i-lucide-message-square-plus',
    'text-primary',
  ],
  ASSIGNED_CONVERSATION_NEW_MESSAGE: [
    'i-lucide-message-square-plus',
    'text-primary',
  ],
  SLA_MISSED_FIRST_RESPONSE: ['i-lucide-heart-crack', 'text-destructive'],
  SLA_MISSED_NEXT_RESPONSE: ['i-lucide-heart-crack', 'text-destructive'],
  SLA_MISSED_RESOLUTION: ['i-lucide-heart-crack', 'text-destructive'],
};
