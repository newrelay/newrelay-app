import ApiClient from './ApiClient';

class CommentAutomationTemplatesAPI extends ApiClient {
  constructor() {
    super('comment_automation/templates', { accountScoped: true });
  }
}

export default new CommentAutomationTemplatesAPI();
