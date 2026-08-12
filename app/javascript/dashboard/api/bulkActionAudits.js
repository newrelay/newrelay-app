import ApiClient from './ApiClient';

class BulkActionAuditsAPI extends ApiClient {
  constructor() {
    super('bulk_action_audits', { accountScoped: true });
  }
}

export default new BulkActionAuditsAPI();
