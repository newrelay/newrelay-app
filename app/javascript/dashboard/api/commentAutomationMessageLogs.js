import ApiClient from './ApiClient';

class CommentAutomationMessageLogsAPI extends ApiClient {
  constructor() {
    super('comment_automation/message_logs', { accountScoped: true });
  }
}

export default new CommentAutomationMessageLogsAPI();
