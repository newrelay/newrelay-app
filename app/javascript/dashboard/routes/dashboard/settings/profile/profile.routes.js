import { frontendURL } from '../../../../helper/URLHelper';
import { parseBoolean } from '@chatwoot/utils';

import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';
import MfaSettings from './MfaSettings.vue';
import McpPermissions from './McpPermissions.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/profile'),
      name: 'profile_settings',
      meta: {
        permissions: ['administrator', 'agent', 'custom_role'],
      },
      component: SettingsWrapper,
      props: {
        hideSideMenu: true,
        fullWidth: true,
      },
      children: [
        {
          path: '',
          redirect: to => ({
            name: 'profile_settings_index',
            params: to.params,
          }),
        },
        {
          path: 'settings',
          name: 'profile_settings_index',
          component: Index,
          meta: {
            permissions: ['administrator', 'agent', 'custom_role'],
          },
        },
        {
          path: 'mfa',
          name: 'profile_settings_mfa',
          component: MfaSettings,
          meta: {
            permissions: ['administrator', 'agent', 'custom_role'],
          },
          beforeEnter: (to, from, next) => {
            // Check if MFA is enabled globally
            if (!parseBoolean(window.newrelayConfig?.isMfaEnabled)) {
              // Redirect to profile settings if MFA is disabled
              next({ name: 'profile_settings_index' });
            } else {
              next();
            }
          },
        },
        {
          path: 'mcp',
          name: 'profile_settings_mcp',
          component: McpPermissions,
          meta: {
            permissions: ['administrator', 'agent', 'custom_role'],
          },
        },
      ],
    },
  ],
};
