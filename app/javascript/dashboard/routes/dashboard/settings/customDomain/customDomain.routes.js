import { frontendURL } from '../../../../helper/URLHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import Index from './Index.vue';
import SettingsWrapper from '../SettingsWrapper.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/custom-domain'),
      meta: {
        permissions: ['administrator'],
        featureFlag: FEATURE_FLAGS.CUSTOM_DOMAIN,
      },
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'custom_domain_settings_index',
          component: Index,
          meta: {
            permissions: ['administrator'],
            featureFlag: FEATURE_FLAGS.CUSTOM_DOMAIN,
          },
        },
      ],
    },
  ],
};
