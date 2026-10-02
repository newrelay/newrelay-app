/* global axios */
import ApiClient from './ApiClient';

class ElevenlabsVoices extends ApiClient {
  constructor() {
    super('elevenlabs_voices', { accountScoped: true });
  }

  createVoice(formData) {
    return axios.post(this.url, formData);
  }
}

export default new ElevenlabsVoices();
