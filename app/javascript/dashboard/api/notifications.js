/* global axios */
import ApiClient from './ApiClient';

class NotificationsAPI extends ApiClient {
  constructor() {
    super('notifications', { accountScoped: true });
  }

  get({ page, status, type, sortOrder }) {
    const includesFilter = [status, type].filter(value => !!value);
    // Keep read/snoozed records so Inbox "All Messages" is not wiped after
    // opening a notification. Unread views filter client-side.
    if (!includesFilter.includes('read')) includesFilter.push('read');
    if (!includesFilter.includes('snoozed')) includesFilter.push('snoozed');

    return axios.get(this.url, {
      params: {
        page,
        sort_order: sortOrder,
        includes: includesFilter,
      },
    });
  }

  getNotifications(contactId) {
    return axios.get(`${this.url}/${contactId}/notifications`);
  }

  getUnreadCount() {
    return axios.get(`${this.url}/unread_count`);
  }

  read(primaryActorType, primaryActorId) {
    return axios.post(`${this.url}/read_all`, {
      primary_actor_type: primaryActorType,
      primary_actor_id: primaryActorId,
    });
  }

  unRead(id) {
    return axios.post(`${this.url}/${id}/unread`);
  }

  readAll() {
    return axios.post(`${this.url}/read_all`);
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  deleteAll({ type = 'all' }) {
    return axios.post(`${this.url}/destroy_all`, {
      type,
    });
  }

  snooze({ id, snoozedUntil = null }) {
    return axios.post(`${this.url}/${id}/snooze`, {
      snoozed_until: snoozedUntil,
    });
  }
}

export default new NotificationsAPI();
