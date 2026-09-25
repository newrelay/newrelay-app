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
}

export default new NumberProvisioningOrdersAPI();
