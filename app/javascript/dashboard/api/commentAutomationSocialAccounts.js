/* global axios */
import ApiClient from './ApiClient';

class CommentAutomationSocialAccountsAPI extends ApiClient {
  constructor() {
    super('comment_automation/social_accounts', { accountScoped: true });
  }

  sync() {
    return axios.post(`${this.url}/sync`);
  }
}

export default new CommentAutomationSocialAccountsAPI();
