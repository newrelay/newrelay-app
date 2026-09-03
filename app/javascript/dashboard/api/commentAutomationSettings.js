/* global axios */
import ApiClient from './ApiClient';

class CommentAutomationSettingsAPI extends ApiClient {
  constructor() {
    super('comment_automation/settings', { accountScoped: true });
  }

  save(payload) {
    return axios.patch(this.url, payload);
  }
}

export default new CommentAutomationSettingsAPI();
