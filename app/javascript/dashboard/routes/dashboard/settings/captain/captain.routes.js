import { frontendURL } from '../../../../helper/URLHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/relay-ai'),
      meta: {
        permissions: ['administrator'],
        featureFlag: FEATURE_FLAGS.CAPTAIN,
      },
      component: SettingsWrapper,
      props: {
        headerTitle: 'CAPTAIN_SETTINGS.TITLE',
        icon: 'i-lucide-brain-circuit',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'captain_settings_index',
          component: Index,
          meta: {
            permissions: ['administrator'],
            featureFlag: FEATURE_FLAGS.CAPTAIN,
            installationTypes: [
              INSTALLATION_TYPES.ENTERPRISE,
              INSTALLATION_TYPES.CLOUD,
            ],
          },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/settings/captain/:pathMatch(.*)*'),
      meta: {
        permissions: ['administrator'],
        featureFlag: FEATURE_FLAGS.CAPTAIN,
      },
      redirect: to => to.fullPath.replace(/\/captain(?=\/|$)/, '/relay-ai'),
    },
  ],
};
