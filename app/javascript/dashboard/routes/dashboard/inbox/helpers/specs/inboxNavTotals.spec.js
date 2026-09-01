import { INBOX_TYPES } from 'dashboard/helper/inbox';
import {
  mineCountFromMeta,
  mineCountFromList,
  unreadCountFromConversations,
  inboxesForChannelNav,
  viewCountsFromTotals,
  mergeInboxCounts,
} from '../inboxNavTotals';

describe('inboxNavTotals', () => {
  it('reads mine_count from the meta endpoint', () => {
    expect(mineCountFromMeta({ data: { meta: { mine_count: 12 } } })).toBe(12);
    expect(mineCountFromMeta({ data: { meta: { mine_count: 0 } } })).toBe(0);
    expect(mineCountFromMeta({})).toBe(0);
  });

  it('reads mine_count from the conversation list endpoint', () => {
    expect(
      mineCountFromList({ data: { data: { meta: { mine_count: 20 } } } })
    ).toBe(20);
  });

  it('counts unread conversations from either key shape', () => {
    expect(
      unreadCountFromConversations([
        { id: 1, unread_count: 2 },
        { id: 2, unreadCount: 0 },
        { id: 3, unread_count: 1 },
      ])
    ).toBe(2);
  });

  it('keeps All / Unread totals independent of the current status-tab list length', () => {
    const openTabLoadedRows = [{ id: 1 }, { id: 2 }];

    const counts = viewCountsFromTotals({
      all: 20,
      unread: 7,
      starred: 1,
      snoozed: 4,
      archived: 9,
    });

    expect(counts.all).toBe(20);
    expect(counts.unread).toBe(7);
    expect(counts.assigned).toBe(20);
    expect(counts.all).not.toBe(openTabLoadedRows.length);
    expect(counts.unread).not.toBe(openTabLoadedRows.length);
  });

  it('attaches all-status meta counts onto channel rows', () => {
    const inboxes = inboxesForChannelNav([
      { id: 1, name: 'WhatsApp', channelType: INBOX_TYPES.WHATSAPP },
      { id: 2, name: 'Other', channelType: INBOX_TYPES.API },
    ]);
    const channels = mergeInboxCounts(inboxes, { 1: 8 });

    expect(channels).toHaveLength(1);
    expect(channels[0].count).toBe(8);
  });
});
