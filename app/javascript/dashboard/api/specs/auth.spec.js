import axios from 'axios';
import authAPI from '../auth';

global.axios = axios;
vi.mock('axios');

describe('#authAPI', () => {
  describe('#updateAccessTokenScopes', () => {
    it('sends a PUT request with the scopes wrapped under profile', () => {
      authAPI.updateAccessTokenScopes({
        scopes: ['list_inboxes', 'add_label'],
      });
      expect(axios.put).toHaveBeenCalledWith('/api/v1/profile', {
        profile: { scopes: ['list_inboxes', 'add_label'] },
      });
    });
  });
});
