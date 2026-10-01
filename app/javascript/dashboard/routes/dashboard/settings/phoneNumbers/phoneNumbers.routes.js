import { frontendURL } from '../../../../helper/URLHelper';

import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/phone-numbers'),
      name: 'phone_numbers_wrapper',
      meta: {
        permissions: ['administrator'],
      },
      redirect: to => {
        return { name: 'phone_numbers_list', params: to.params };
      },
    },
    {
      path: frontendURL('accounts/:accountId/phone-numbers/list'),
      name: 'phone_numbers_list',
      meta: {
        permissions: ['administrator'],
      },
      component: Index,
    },
    {
      path: frontendURL('accounts/:accountId/settings/phone-numbers'),
      redirect: to => ({ name: 'phone_numbers_list', params: to.params }),
    },
    {
      path: frontendURL('accounts/:accountId/settings/phone-numbers/list'),
      redirect: to => ({ name: 'phone_numbers_list', params: to.params }),
    },
  ],
};
