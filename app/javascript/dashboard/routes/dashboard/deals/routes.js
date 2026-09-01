import { frontendURL } from '../../../helper/URLHelper';
import DealsIndex from './pages/DealsIndex.vue';
import PipelinesIndex from './pages/PipelinesIndex.vue';
import OpportunitiesIndex from './pages/OpportunitiesIndex.vue';

const commonMeta = {
  permissions: ['administrator', 'agent', 'crm_manage'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/deals'),
    component: DealsIndex,
    meta: commonMeta,
    children: [
      {
        path: '',
        name: 'deals_dashboard_index',
        component: DealsIndex,
        meta: commonMeta,
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/pipelines'),
    component: PipelinesIndex,
    meta: commonMeta,
    children: [
      {
        path: '',
        name: 'pipelines_dashboard_index',
        component: PipelinesIndex,
        meta: commonMeta,
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/opportunities'),
    component: OpportunitiesIndex,
    meta: commonMeta,
    children: [
      {
        path: '',
        name: 'opportunities_dashboard_index',
        component: OpportunitiesIndex,
        meta: commonMeta,
      },
    ],
  },
];
