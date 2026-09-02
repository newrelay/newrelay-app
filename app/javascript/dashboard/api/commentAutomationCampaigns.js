import ApiClient from './ApiClient';

class CommentAutomationCampaignsAPI extends ApiClient {
  constructor() {
    super('comment_automation/campaigns', { accountScoped: true });
  }
}

export default new CommentAutomationCampaignsAPI();
