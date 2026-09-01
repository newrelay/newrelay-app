import { INBOX_TYPES } from 'dashboard/helper/inbox';

export const CHANNEL_NAV_TYPES = [
  INBOX_TYPES.WHATSAPP,
  INBOX_TYPES.EMAIL,
  INBOX_TYPES.INSTAGRAM,
  INBOX_TYPES.WEB,
  INBOX_TYPES.SMS,
  INBOX_TYPES.TWILIO,
];

export const mineCountFromMeta = response => {
  const count = Number(response?.data?.meta?.mine_count);
  return Number.isFinite(count) ? Math.max(count, 0) : 0;
};

export const mineCountFromList = response => {
  const count = Number(response?.data?.data?.meta?.mine_count);
  return Number.isFinite(count) ? Math.max(count, 0) : 0;
};

export const unreadCountFromConversations = (conversations = []) =>
  conversations.filter(conversation => {
    const unread = conversation.unread_count || conversation.unreadCount;
    return Number(unread) > 0;
  }).length;

export const inboxesForChannelNav = (inboxes = []) =>
  inboxes.filter(inbox =>
    CHANNEL_NAV_TYPES.includes(inbox.channelType || inbox.channel_type)
  );

export const viewCountsFromTotals = ({
  all = 0,
  unread = 0,
  starred = 0,
  snoozed = 0,
  archived = 0,
} = {}) => ({
  all,
  unread,
  assigned: all,
  starred,
  snoozed,
  archived,
  spam: 0,
});

export const mergeInboxCounts = (inboxes, byInbox = {}) =>
  inboxes.map(inbox => ({
    ...inbox,
    count: Number(byInbox[inbox.id]) || 0,
  }));
