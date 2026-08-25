/* global axios */
import ApiClient from './ApiClient';

class CampaignAnalyticsAPI extends ApiClient {
  constructor() {
    super('campaign_analytics', { accountScoped: true });
  }

  get(params = {}) {
    return axios.get(this.url, { params });
  }
}

export default new CampaignAnalyticsAPI();
