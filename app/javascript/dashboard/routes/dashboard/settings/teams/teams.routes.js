import { frontendURL } from '../../../../helper/URLHelper';
import { FEATURE_FLAGS } from '../../../../featureFlags';

import TeamsIndex from './Index.vue';
import CreateStepWrap from './Create/Index.vue';
import EditStepWrap from './Edit/Index.vue';
import CreateTeam from './Create/CreateTeam.vue';
import EditTeam from './Edit/EditTeam.vue';
import AddAgents from './Create/AddAgents.vue';
import EditAgents from './Edit/EditAgents.vue';
import FinishSetup from './FinishSetup.vue';
import SettingsWrapper from '../SettingsWrapper.vue';

const TEAM_FLOW_ROUTES = [
  'settings_teams_new',
  'settings_teams_add_agents',
  'settings_teams_finish',
  'settings_teams_edit',
  'settings_teams_edit_members',
  'settings_teams_edit_finish',
];

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/teams'),
      component: SettingsWrapper,
      props: route => ({
        fullWidth: TEAM_FLOW_ROUTES.includes(route.name),
        keepAlive: !TEAM_FLOW_ROUTES.includes(route.name),
      }),
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'settings_teams_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'settings_teams_list',
          component: TeamsIndex,
          meta: {
            featureFlag: FEATURE_FLAGS.TEAM_MANAGEMENT,
            permissions: ['administrator'],
          },
        },
        {
          path: 'new',
          component: CreateStepWrap,
          children: [
            {
              path: '',
              name: 'settings_teams_new',
              component: CreateTeam,
              meta: {
                featureFlag: FEATURE_FLAGS.TEAM_MANAGEMENT,
                permissions: ['administrator'],
              },
            },
            {
              path: ':teamId/finish',
              name: 'settings_teams_finish',
              component: FinishSetup,
              meta: {
                featureFlag: FEATURE_FLAGS.TEAM_MANAGEMENT,
                permissions: ['administrator'],
              },
            },
            {
              path: ':teamId/agents',
              name: 'settings_teams_add_agents',
              meta: {
                featureFlag: FEATURE_FLAGS.TEAM_MANAGEMENT,
                permissions: ['administrator'],
              },
              component: AddAgents,
            },
          ],
        },
        {
          path: ':teamId/edit',
          component: EditStepWrap,
          children: [
            {
              path: '',
              name: 'settings_teams_edit',
              component: EditTeam,
              meta: {
                featureFlag: FEATURE_FLAGS.TEAM_MANAGEMENT,
                permissions: ['administrator'],
              },
            },
            {
              path: 'agents',
              name: 'settings_teams_edit_members',
              component: EditAgents,
              meta: {
                featureFlag: FEATURE_FLAGS.TEAM_MANAGEMENT,
                permissions: ['administrator'],
              },
            },
            {
              path: 'finish',
              name: 'settings_teams_edit_finish',
              meta: {
                featureFlag: FEATURE_FLAGS.TEAM_MANAGEMENT,
                permissions: ['administrator'],
              },
              component: FinishSetup,
            },
          ],
        },
      ],
    },
  ],
};
