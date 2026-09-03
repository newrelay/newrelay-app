import ApiClient from './ApiClient';

class CommentAutomationResponseControlsAPI extends ApiClient {
  constructor() {
    super('comment_automation/response_controls', { accountScoped: true });
  }
}

export default new CommentAutomationResponseControlsAPI();
