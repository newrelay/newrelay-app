/* global axios */
import ApiClient from './ApiClient';

class PipelineAPI extends ApiClient {
  constructor() {
    super('pipelines', { accountScoped: true });
  }

  get(params = {}) {
    return axios.get(this.url, { params });
  }

  create(data) {
    return axios.post(this.url, { pipeline: data });
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, { pipeline: data });
  }
}

export default new PipelineAPI();
