/* global axios */
import ApiClient from './ApiClient';

class NumberProvisioningOrdersAPI extends ApiClient {
  constructor() {
    super('number_provisioning/orders', { accountScoped: true });
  }

  search({ countryCode, type }) {
    return axios.get(`${this.url}/search`, {
      params: { country_code: countryCode, type },
    });
  }

  getConfig() {
    return axios.get(`${this.url}/provisioning_config`);
  }

  // Overrides ApiClient#create to attach an Idempotency-Key header so a
  // double-click, replay, or slow-request retry doesn't create two orders
  // for the same number (CEO review finding 4A).
  create(data, idempotencyKey) {
    return axios.post(this.url, data, {
      headers: { 'Idempotency-Key': idempotencyKey },
    });
  }
}

export default new NumberProvisioningOrdersAPI();
