/* global axios */
import ApiClient from './ApiClient';

class DealAPI extends ApiClient {
  constructor() {
    super('deals', { accountScoped: true });
  }

  get(params = {}) {
    return axios.get(this.url, { params });
  }

  create(data) {
    return axios.post(this.url, { deal: data });
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, { deal: data });
  }
}

export default new DealAPI();
