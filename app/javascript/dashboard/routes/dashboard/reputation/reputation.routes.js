import { frontendURL } from '../../../helper/URLHelper';
import ReputationLayout from './pages/ReputationLayout.vue';
import OverviewPage from './pages/OverviewPage.vue';
import ReviewsPage from './pages/ReviewsPage.vue';
import RequestsPage from './pages/RequestsPage.vue';
import WidgetsPage from './pages/WidgetsPage.vue';
import SettingsPage from './pages/SettingsPage.vue';
import VideoTestimonialsPage from './pages/VideoTestimonialsPage.vue';

const meta = { permissions: ['administrator', 'agent'] };

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
        component: OverviewPage,
        meta,
      },
      {
        path: 'reviews',
        name: 'reputation_reviews',
        component: ReviewsPage,
        meta,
      },
      {
        path: 'requests',
        name: 'reputation_requests',
        component: RequestsPage,
        meta,
      },
      {
        path: 'widgets',
        name: 'reputation_widgets',
        component: WidgetsPage,
        meta,
      },
      {
        path: 'video_testimonials',
        name: 'reputation_video_testimonials',
        component: VideoTestimonialsPage,
        meta,
      },
      {
        path: 'settings',
        name: 'reputation_settings',
        component: SettingsPage,
        meta: { ...meta, permissions: ['administrator'] },
      },
    ],
  },
];
