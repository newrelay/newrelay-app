import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { usePolicy } from 'dashboard/composables/usePolicy';
import {
  ICON_ACCOUNT_SETTINGS,
  ICON_AGENT_REPORTS,
  ICON_CONTACT_DASHBOARD,
  ICON_CONVERSATION_DASHBOARD,
  ICON_INBOXES,
  ICON_INBOX_REPORTS,
  ICON_LABEL_REPORTS,
  ICON_NOTIFICATION,
  ICON_REPORTS_OVERVIEW,
  ICON_TEAM_REPORTS,
  ICON_USER_PROFILE,
  ICON_CONVERSATION_REPORTS,
} from 'dashboard/helper/commandbar/icons';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { SETTINGS_NAV_SECTIONS } from 'dashboard/routes/dashboard/settings/settings.navigation';

const GO_TO_COMMANDS = [
  {
    id: 'goto_conversation_dashboard',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CONVERSATION_DASHBOARD',
    section: 'COMMAND_BAR.SECTIONS.GENERAL',
    icon: ICON_CONVERSATION_DASHBOARD,
    path: accountId => `accounts/${accountId}/dashboard`,
    role: ['administrator', 'agent'],
  },
  {
    id: 'goto_contacts_dashboard',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CONTACTS_DASHBOARD',
    section: 'COMMAND_BAR.SECTIONS.GENERAL',
    featureFlag: FEATURE_FLAGS.CRM,
    icon: ICON_CONTACT_DASHBOARD,
    path: accountId => `accounts/${accountId}/contacts`,
    role: ['administrator', 'agent'],
  },
  {
    id: 'goto_search',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SEARCH',
    section: 'COMMAND_BAR.SECTIONS.GENERAL',
    icon: ICON_INBOXES,
    path: accountId => `accounts/${accountId}/search`,
    role: ['administrator', 'agent'],
  },
  {
    id: 'open_reports_overview',
    section: 'COMMAND_BAR.SECTIONS.REPORTS',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_REPORTS_OVERVIEW',
    featureFlag: FEATURE_FLAGS.REPORTS,
    icon: ICON_REPORTS_OVERVIEW,
    path: accountId => `accounts/${accountId}/reports/overview`,
    role: ['administrator'],
  },
  {
    id: 'open_conversation_reports',
    section: 'COMMAND_BAR.SECTIONS.REPORTS',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CONVERSATION_REPORTS',
    featureFlag: FEATURE_FLAGS.REPORTS,
    icon: ICON_CONVERSATION_REPORTS,
    path: accountId => `accounts/${accountId}/reports/conversation`,
    role: ['administrator'],
  },
  {
    id: 'open_agent_reports',
    section: 'COMMAND_BAR.SECTIONS.REPORTS',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_AGENT_REPORTS',
    featureFlag: FEATURE_FLAGS.REPORTS,
    icon: ICON_AGENT_REPORTS,
    path: accountId => `accounts/${accountId}/reports/agent`,
    role: ['administrator'],
  },
  {
    id: 'open_label_reports',
    section: 'COMMAND_BAR.SECTIONS.REPORTS',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_LABEL_REPORTS',
    featureFlag: FEATURE_FLAGS.REPORTS,
    icon: ICON_LABEL_REPORTS,
    path: accountId => `accounts/${accountId}/reports/label`,
    role: ['administrator'],
  },
  {
    id: 'open_inbox_reports',
    section: 'COMMAND_BAR.SECTIONS.REPORTS',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_INBOX_REPORTS',
    featureFlag: FEATURE_FLAGS.REPORTS,
    icon: ICON_INBOX_REPORTS,
    path: accountId => `accounts/${accountId}/reports/inboxes`,
    role: ['administrator'],
  },
  {
    id: 'open_team_reports',
    section: 'COMMAND_BAR.SECTIONS.REPORTS',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_TEAM_REPORTS',
    featureFlag: FEATURE_FLAGS.REPORTS,
    icon: ICON_TEAM_REPORTS,
    path: accountId => `accounts/${accountId}/reports/teams`,
    role: ['administrator'],
  },
  {
    id: 'open_profile_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_PROFILE',
    section: 'COMMAND_BAR.SECTIONS.SETTINGS',
    icon: ICON_USER_PROFILE,
    path: accountId => `accounts/${accountId}/profile/settings`,
    role: ['administrator', 'agent'],
  },
  {
    id: 'open_notifications',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_NOTIFICATIONS',
    section: 'COMMAND_BAR.SECTIONS.SETTINGS',
    icon: ICON_NOTIFICATION,
    path: accountId => `accounts/${accountId}/notifications`,
    role: ['administrator', 'agent'],
  },
];

export function useGoToCommandHotKeys() {
  const { t } = useI18n();
  const router = useRouter();
  const { isAdmin } = useAdmin();
  const { shouldShow } = usePolicy();

  const currentAccountId = useMapGetter('getCurrentAccountId');
  const isFeatureEnabledOnAccount = useMapGetter(
    'accounts/isFeatureEnabledonAccount'
  );

  const openRoute = url => {
    router.push(frontendURL(url));
  };

  const findRouteMeta = routeName => {
    const match = router.getRoutes().find(r => r.name === routeName);
    return match?.meta || {};
  };

  const isSettingsItemAllowed = item => {
    if (
      item.requiresAdvancedAssignment &&
      !isFeatureEnabledOnAccount.value(
        currentAccountId.value,
        FEATURE_FLAGS.ADVANCED_ASSIGNMENT
      )
    ) {
      return false;
    }
    const meta = findRouteMeta(item.routeName);
    return shouldShow(
      meta.featureFlag,
      meta.permissions,
      meta.installationTypes
    );
  };

  const settingsCommands = computed(() =>
    SETTINGS_NAV_SECTIONS.flatMap(section =>
      section.items.filter(isSettingsItemAllowed).map(item => ({
        id: `open_settings_${item.key}`,
        section: t('COMMAND_BAR.SECTIONS.SETTINGS'),
        title: t(item.labelKey),
        icon: ICON_ACCOUNT_SETTINGS,
        handler: () =>
          router.push({
            name: item.routeName,
            params: { accountId: currentAccountId.value },
          }),
      }))
    )
  );

  const goToCommandHotKeys = computed(() => {
    let commands = GO_TO_COMMANDS.filter(cmd => {
      if (cmd.featureFlag) {
        return isFeatureEnabledOnAccount.value(
          currentAccountId.value,
          cmd.featureFlag
        );
      }
      return true;
    });

    if (!isAdmin.value) {
      commands = commands.filter(command => command.role.includes('agent'));
    }

    const staticCommands = commands.map(command => ({
      id: command.id,
      section: t(command.section),
      title: t(command.title),
      icon: command.icon,
      handler: () => openRoute(command.path(currentAccountId.value)),
    }));

    return [...staticCommands, ...settingsCommands.value];
  });

  return {
    goToCommandHotKeys,
  };
}
