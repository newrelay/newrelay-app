import { frontendURL } from '../../../../helper/URLHelper';

import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/phone-numbers'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'phone_numbers_wrapper',
          meta: {
            permissions: ['administrator'],
          },
          redirect: to => {
            return { name: 'phone_numbers_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'phone_numbers_list',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};
