import { frontendURL } from '../../../helper/URLHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import ReputationLayout from './pages/ReputationLayout.vue';

const meta = { permissions: ['administrator', 'reputation_manage'] };

export const routes = [
  {
    path: frontendURL('accounts/:accountId/reputation'),
    component: ReputationLayout,
    children: [
      {
        path: '',
        redirect: to => ({ name: 'reputation_overview', params: to.params }),
      },
      {
        path: 'overview',
        name: 'reputation_overview',
        component: () => import('./pages/OverviewPage.vue'),
        meta,
      },
      {
        path: 'reviews',
        name: 'reputation_reviews',
        component: () => import('./pages/ReviewsPage.vue'),
        meta,
      },
      {
        path: 'requests',
        name: 'reputation_requests',
        component: () => import('./pages/RequestsPage.vue'),
        meta,
      },
      {
        path: 'widgets',
        name: 'reputation_widgets',
        component: () => import('./pages/WidgetsPage.vue'),
        meta,
      },
      {
        path: 'video_testimonials',
        name: 'reputation_video_testimonials',
        component: () => import('./pages/VideoTestimonialsPage.vue'),
        meta,
      },
      {
        path: 'configuration',
        name: 'reputation_configuration',
        component: () => import('./pages/ConfigurationPage.vue'),
        meta,
      },
      {
        path: 'integrations',
        name: 'reputation_integrations',
        component: () => import('./pages/IntegrationsPage.vue'),
        meta,
      },
      {
        path: 'listings',
        name: 'reputation_listings',
        component: () => import('./pages/ListingsPage.vue'),
        meta: { ...meta, featureFlag: FEATURE_FLAGS.REPUTATION_DEMO_SURFACES },
      },
      {
        path: 'listings/:listingId',
        name: 'reputation_listing_detail',
        component: () => import('./pages/ListingDetailPage.vue'),
        meta: { ...meta, featureFlag: FEATURE_FLAGS.REPUTATION_DEMO_SURFACES },
      },
      {
        path: 'feedback',
        name: 'reputation_feedback',
        component: () => import('./pages/FeedbackPage.vue'),
        meta: { ...meta, featureFlag: FEATURE_FLAGS.REPUTATION_DEMO_SURFACES },
      },
      {
        path: 'settings',
        name: 'reputation_settings',
        component: () => import('./pages/SettingsPage.vue'),
        meta: { ...meta, permissions: ['administrator'] },
      },
      {
        path: 'automation',
        name: 'reputation_automation',
        component: () => import('./pages/AutomationPage.vue'),
        meta: { ...meta, permissions: ['administrator'] },
      },
    ],
  },
];
