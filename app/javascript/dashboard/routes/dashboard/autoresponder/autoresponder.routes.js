import { frontendURL } from '../../../helper/URLHelper';
import AutoresponderLayout from './pages/AutoresponderLayout.vue';

const meta = { permissions: ['administrator'] };

export const routes = [
  {
    path: frontendURL('accounts/:accountId/autoresponder'),
    component: AutoresponderLayout,
    children: [
      {
        path: '',
        redirect: to => ({ name: 'autoresponder_overview', params: to.params }),
      },
      {
        path: 'overview',
        name: 'autoresponder_overview',
        component: () => import('./pages/OverviewPage.vue'),
        meta,
      },
      {
        path: 'automations',
        name: 'autoresponder_automations',
        component: () => import('./pages/AutomationsPage.vue'),
        meta,
      },
      {
        path: 'response-controls',
        name: 'autoresponder_response_controls',
        component: () => import('./pages/ResponseControlsPage.vue'),
        meta,
      },
      {
        path: 'templates',
        name: 'autoresponder_templates',
        component: () => import('./pages/TemplatesPage.vue'),
        meta,
      },
      {
        path: 'activity',
        name: 'autoresponder_activity',
        component: () => import('./pages/ActivityPage.vue'),
        meta,
      },
      {
        path: 'settings',
        name: 'autoresponder_settings',
        component: () => import('./pages/SettingsPage.vue'),
        meta,
      },
    ],
  },
];
