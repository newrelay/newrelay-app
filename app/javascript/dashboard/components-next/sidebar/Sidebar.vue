<script setup>
import { h, ref, computed, onMounted, watch } from 'vue';
import { provideSidebarContext, useSidebarResize } from './provider';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useSidebarKeyboardShortcuts } from './useSidebarKeyboardShortcuts';
import { vOnClickOutside } from '@vueuse/components';
import {
  FEATURE_FLAGS,
  isReputationDemoSurfacesEnabled,
} from 'dashboard/featureFlags';
import { useWindowSize, useEventListener } from '@vueuse/core';

import Auth from 'dashboard/api/auth';
import ChannelLeaf from './ChannelLeaf.vue';
import ChannelIcon from 'next/icon/ChannelIcon.vue';
import SidebarChangelogCard from './SidebarChangelogCard.vue';
import SidebarChangelogButton from './SidebarChangelogButton.vue';
import SidebarGroup from './SidebarGroup.vue';
import { SETTINGS_ROUTE_NAMES } from 'dashboard/routes/dashboard/settings/settings.navigation';
import { useBranding } from 'shared/composables/useBranding';
import { useStealthMode } from 'dashboard/composables/useStealthMode';

const props = defineProps({
  isMobileSidebarOpen: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'closeKeyShortcutModal',
  'openKeyShortcutModal',
  'closeMobileSidebar',
]);

const { accountScopedRoute, isOnChatwootCloud } = useAccount();
const currentRole = useMapGetter('getCurrentRole');
const currentCustomRoleId = useMapGetter('getCurrentCustomRoleId');
const store = useStore();
const { t } = useI18n();
const { replaceInstallationName } = useBranding();
const { isStealthMode } = useStealthMode();

const isACustomBrandedInstance = useMapGetter(
  'globalConfig/isACustomBrandedInstance'
);
const isRTL = useMapGetter('accounts/isRTL');
const brandName = computed(() =>
  isStealthMode.value
    ? t('SIDEBAR.STEALTH_BRAND_NAME')
    : replaceInstallationName(t('SIDEBAR.BRAND_NAME'))
);
const brandSubtitle = computed(() => t('SIDEBAR.ENTERPRISE_EDITION'));
const WHITE_RELAY_LOGO = '/white-relay-logo.svg';

const { width: windowWidth } = useWindowSize();
const isMobile = computed(() => windowWidth.value < 768);

const accountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const hasConversationUnreadCounts = computed(() => {
  return isFeatureEnabledonAccount.value(
    accountId.value,
    FEATURE_FLAGS.CONVERSATION_UNREAD_COUNTS
  );
});

const showReputationDemoSurfaces = computed(() =>
  isReputationDemoSurfacesEnabled(
    accountId.value,
    isFeatureEnabledonAccount.value
  )
);

const fetchConversationUnreadCounts = ([currentAccountId, isEnabled]) => {
  if (!currentAccountId) return;

  if (!isEnabled) {
    store.dispatch('conversationUnreadCounts/clear');
    return;
  }

  store.dispatch('conversationUnreadCounts/get');
};

const toggleShortcutModalFn = show => {
  if (show) {
    emit('openKeyShortcutModal');
  } else {
    emit('closeKeyShortcutModal');
  }
};

useSidebarKeyboardShortcuts(toggleShortcutModalFn);

const expandedItem = ref(null);

// Accordion toggle (user click). Use expandItem for route-driven open.
const setExpandedItem = name => {
  expandedItem.value = expandedItem.value === name ? null : name;
};

const expandItem = name => {
  expandedItem.value = name;
};

const {
  sidebarWidth,
  isCollapsed,
  setSidebarWidth,
  saveWidth,
  snapToCollapsed,
  snapToExpanded,
  COLLAPSED_THRESHOLD,
} = useSidebarResize();

// On mobile, sidebar is always expanded (flyout mode)
const isEffectivelyCollapsed = computed(
  () => !isMobile.value && isCollapsed.value
);

// Resize handle logic
const isResizing = ref(false);
const startX = ref(0);
const startWidth = ref(0);

provideSidebarContext({
  expandedItem,
  setExpandedItem,
  expandItem,
  isCollapsed: isEffectivelyCollapsed,
  sidebarWidth,
  isResizing,
});

// Get clientX from mouse or touch event
const getClientX = event =>
  event.touches ? event.touches[0].clientX : event.clientX;

const onResizeStart = event => {
  isResizing.value = true;
  startX.value = getClientX(event);
  startWidth.value = sidebarWidth.value;
  Object.assign(document.body.style, {
    cursor: 'col-resize',
    userSelect: 'none',
  });
  // Prevent default to avoid scrolling on touch
  event.preventDefault();
};

const onResizeMove = event => {
  if (!isResizing.value) return;

  const delta = isRTL.value
    ? startX.value - getClientX(event)
    : getClientX(event) - startX.value;
  setSidebarWidth(startWidth.value + delta);
};

const onResizeEnd = () => {
  if (!isResizing.value) return;

  isResizing.value = false;
  Object.assign(document.body.style, { cursor: '', userSelect: '' });

  // Snap to collapsed state if below threshold
  if (sidebarWidth.value < COLLAPSED_THRESHOLD) {
    snapToCollapsed();
  } else {
    saveWidth();
  }
};

const onResizeHandleDoubleClick = () => {
  if (isCollapsed.value) snapToExpanded();
  else snapToCollapsed();
};

const toggleSidebarCollapse = () => {
  if (isCollapsed.value) snapToExpanded();
  else snapToCollapsed();
};

defineExpose({ toggleSidebarCollapse });

// Support both mouse and touch events
useEventListener(document, 'mousemove', onResizeMove);
useEventListener(document, 'mouseup', onResizeEnd);
useEventListener(document, 'touchmove', onResizeMove, { passive: false });
useEventListener(document, 'touchend', onResizeEnd);

const inboxes = useMapGetter('inboxes/getInboxes');
const labels = useMapGetter('labels/getLabelsOnSidebar');
const teamUnreadCounts = useMapGetter(
  'conversationUnreadCounts/getTeamUnreadCounts'
);
const inboxUnreadCounts = useMapGetter(
  'conversationUnreadCounts/getInboxUnreadCounts'
);
const labelUnreadCounts = useMapGetter(
  'conversationUnreadCounts/getLabelUnreadCounts'
);
const teams = useMapGetter('teams/getMyTeams');
const conversationCustomViews = useMapGetter(
  'customViews/getConversationCustomViews'
);
const inboxNotificationCount = useMapGetter('notifications/getUnreadCount');

onMounted(() => {
  store.dispatch('labels/get');
  store.dispatch('inboxes/get');
  store.dispatch('notifications/unReadCount');
  store.dispatch('teams/get');
  store.dispatch('attributes/get');
  store.dispatch('customViews/get', 'conversation');
  store.dispatch('customViews/get', 'contact');
});

watch([accountId, hasConversationUnreadCounts], fetchConversationUnreadCounts, {
  immediate: true,
});

const normalizeUnreadCount = count => {
  const unreadCount = Number(count);
  return Number.isFinite(unreadCount) && unreadCount > 0 ? unreadCount : 0;
};

const sortByUnreadCount = (items, labelKey, unreadCountKey) =>
  items.slice().sort((a, b) => {
    const unreadCountDiff =
      normalizeUnreadCount(unreadCountKey(b)) -
      normalizeUnreadCount(unreadCountKey(a));

    if (unreadCountDiff !== 0) return unreadCountDiff;

    return labelKey(a).localeCompare(labelKey(b));
  });

const sortedTeams = computed(() =>
  sortByUnreadCount(
    teams.value,
    team => team.name,
    team => teamUnreadCounts.value[String(team.id)] || 0
  )
);

const sortedInboxes = computed(() =>
  sortByUnreadCount(
    inboxes.value,
    inbox => inbox.name,
    inbox => inboxUnreadCounts.value[String(inbox.id)] || 0
  )
);

const sortedLabels = computed(() =>
  sortByUnreadCount(
    labels.value,
    label => label.title,
    label => labelUnreadCounts.value[String(label.id)] || 0
  )
);

const closeMobileSidebar = () => {
  if (!props.isMobileSidebarOpen) return;
  emit('closeMobileSidebar');
};

const primaryMenuItems = computed(() => {
  return [
    {
      name: 'Customer Engagement',
      label: t('SIDEBAR.CUSTOMER_ENGAGEMENT'),
      icon: 'i-lucide-message-circle',
      children: [
        {
          name: 'Inbox',
          label: t('SIDEBAR.INBOX'),
          to: accountScopedRoute('inbox_view'),
          activeOn: ['inbox_view', 'inbox_view_conversation'],
          badgeCount: inboxNotificationCount.value,
        },
        {
          name: 'Conversations',
          label: t('SIDEBAR.CONVERSATIONS'),
          collapsible: true,
          children: [
            {
              name: 'All',
              label: t('SIDEBAR.ALL_CONVERSATION'),
              activeOn: ['home', 'inbox_conversation'],
              to: accountScopedRoute('home'),
            },
            {
              name: 'Mentions',
              label: t('SIDEBAR.MENTIONED_CONVERSATIONS'),
              activeOn: ['conversation_through_mentions'],
              to: accountScopedRoute('conversation_mentions'),
            },
            {
              name: 'Participating',
              label: t('SIDEBAR.PARTICIPATING_CONVERSATIONS'),
              activeOn: ['conversation_through_participating'],
              to: accountScopedRoute('conversation_participating'),
            },
            {
              name: 'Unattended',
              activeOn: ['conversation_through_unattended'],
              label: t('SIDEBAR.UNATTENDED_CONVERSATIONS'),
              to: accountScopedRoute('conversation_unattended'),
            },
            {
              name: 'Folders',
              label: t('SIDEBAR.CUSTOM_VIEWS_FOLDER'),
              icon: 'i-lucide-folder',
              activeOn: ['conversations_through_folders'],
              children: conversationCustomViews.value.map(view => ({
                name: `${view.name}-${view.id}`,
                label: view.name,
                to: accountScopedRoute('folder_conversations', { id: view.id }),
              })),
            },
            {
              name: 'Teams',
              label: t('SIDEBAR.TEAMS'),
              collapsible: true,
              activeOn: ['conversations_through_team'],
              children: sortedTeams.value.map(team => ({
                name: `${team.name}-${team.id}`,
                label: team.name,
                badgeCount: teamUnreadCounts.value[String(team.id)] || 0,
                to: accountScopedRoute('team_conversations', {
                  teamId: team.id,
                }),
              })),
            },
            {
              name: 'Channels',
              label: t('SIDEBAR.CHANNELS'),
              collapsible: true,
              activeOn: ['conversation_through_inbox'],
              children: sortedInboxes.value.map(inbox => ({
                name: `${inbox.name}-${inbox.id}`,
                label: inbox.name,
                badgeCount: inboxUnreadCounts.value[String(inbox.id)] || 0,
                icon: h(ChannelIcon, { inbox, class: 'size-[16px]' }),
                to: accountScopedRoute('inbox_dashboard', {
                  inbox_id: inbox.id,
                }),
                component: leafProps =>
                  h(ChannelLeaf, {
                    label: leafProps.label,
                    active: leafProps.active,
                    inbox,
                    badgeCount: leafProps.badgeCount,
                  }),
              })),
            },
            {
              name: 'Labels',
              label: t('SIDEBAR.LABELS'),
              collapsible: true,
              activeOn: ['conversations_through_label'],
              children: sortedLabels.value.map(label => ({
                name: `${label.title}-${label.id}`,
                label: label.title,
                badgeCount: labelUnreadCounts.value[String(label.id)] || 0,
                icon: h('span', {
                  class: `size-[8px] rounded-sm`,
                  style: { backgroundColor: label.color },
                }),
                to: accountScopedRoute('label_conversations', {
                  label: label.title,
                }),
              })),
            },
          ],
        },
      ],
    },
    {
      name: 'CRM & Sales',
      label: t('SIDEBAR.CRM_AND_SALES'),
      icon: 'i-lucide-users',
      children: [
        {
          name: 'Contacts',
          label: t('SIDEBAR.CONTACTS'),
          to: accountScopedRoute(
            'contacts_dashboard_index',
            {},
            { page: 1, search: undefined }
          ),
          activeOn: [
            'contacts_dashboard_index',
            'contacts_dashboard_active',
            'contacts_dashboard_segments_index',
            'contacts_dashboard_labels_index',
            'contacts_dashboard_bulk_actions',
            'contacts_dashboard_tasks',
            'contacts_dashboard_companies',
            'contacts_edit',
            'contacts_edit_segment',
            'contacts_edit_label',
          ],
        },
        {
          name: 'Companies',
          label: t('SIDEBAR.COMPANIES'),
          to: accountScopedRoute('companies_dashboard_index'),
          activeOn: ['companies_dashboard_index', 'companies_dashboard_show'],
        },
      ],
    },
    {
      name: 'Marketing',
      label: t('SIDEBAR.MARKETING'),
      icon: 'i-lucide-megaphone',
      children: [
        {
          name: 'Campaigns',
          label: t('SIDEBAR.CAMPAIGNS'),
          collapsible: true,
          defaultOpen: true,
          children: [
            {
              name: 'Live chat',
              label: t('SIDEBAR.LIVE_CHAT'),
              to: accountScopedRoute('campaigns_livechat_index'),
            },
            {
              name: 'SMS',
              label: t('SIDEBAR.SMS'),
              to: accountScopedRoute('campaigns_sms_index'),
            },
            {
              name: 'WhatsApp',
              label: t('SIDEBAR.WHATSAPP'),
              to: accountScopedRoute('campaigns_whatsapp_index'),
            },
          ],
        },
      ],
    },
    {
      name: 'Captain',
      icon: 'i-lucide-brain-circuit',
      label: t('SIDEBAR.CAPTAIN'),
      activeOn: ['captain_assistants_create_index'],
      children: [
        {
          name: 'FAQs',
          label: t('SIDEBAR.CAPTAIN_RESPONSES'),
          activeOn: [
            'captain_assistants_responses_index',
            'captain_assistants_responses_pending',
          ],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_responses_index',
          }),
        },
        {
          name: 'Documents',
          label: t('SIDEBAR.CAPTAIN_DOCUMENTS'),
          activeOn: ['captain_assistants_documents_index'],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_documents_index',
          }),
        },
        {
          name: 'Scenarios',
          label: t('SIDEBAR.CAPTAIN_SCENARIOS'),
          activeOn: ['captain_assistants_scenarios_index'],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_scenarios_index',
          }),
        },
        {
          name: 'Playground',
          label: t('SIDEBAR.CAPTAIN_PLAYGROUND'),
          activeOn: ['captain_assistants_playground_index'],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_playground_index',
          }),
        },
        {
          name: 'Inboxes',
          label: t('SIDEBAR.CAPTAIN_INBOXES'),
          activeOn: ['captain_assistants_inboxes_index'],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_inboxes_index',
          }),
        },
        {
          name: 'Tools',
          label: t('SIDEBAR.CAPTAIN_TOOLS'),
          activeOn: ['captain_tools_index'],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_tools_index',
          }),
        },
        {
          name: 'Settings',
          label: t('SIDEBAR.CAPTAIN_SETTINGS'),
          activeOn: [
            'captain_assistants_settings_index',
            'captain_assistants_guidelines_index',
            'captain_assistants_guardrails_index',
          ],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_settings_index',
          }),
        },
      ],
    },
    {
      name: 'Reputation',
      icon: 'i-lucide-star',
      confidential: true,
      label: t('SIDEBAR.REPUTATION'),
      children: [
        {
          name: 'Reputation Overview',
          label: t('SIDEBAR.REPUTATION_OVERVIEW'),
          to: accountScopedRoute('reputation_overview'),
          activeOn: ['reputation_overview'],
        },
        {
          name: 'Reputation Reviews',
          label: t('SIDEBAR.REPUTATION_REVIEWS'),
          to: accountScopedRoute('reputation_reviews'),
          activeOn: ['reputation_reviews'],
        },
        {
          name: 'Reputation Requests',
          label: t('SIDEBAR.REPUTATION_REQUESTS'),
          to: accountScopedRoute('reputation_requests'),
          activeOn: ['reputation_requests'],
        },
        {
          name: 'Reputation Configuration',
          label: t('SIDEBAR.REPUTATION_CONFIGURATION'),
          to: accountScopedRoute('reputation_configuration'),
          activeOn: ['reputation_configuration'],
        },
        {
          name: 'Reputation Integrations',
          label: t('SIDEBAR.REPUTATION_INTEGRATIONS'),
          to: accountScopedRoute('reputation_integrations'),
          activeOn: ['reputation_integrations'],
        },
        {
          name: 'Reputation Video',
          label: t('SIDEBAR.REPUTATION_VIDEO'),
          to: accountScopedRoute('reputation_video_testimonials'),
          activeOn: ['reputation_video_testimonials'],
        },
        ...(showReputationDemoSurfaces.value
          ? [
              {
                name: 'Reputation Listings',
                label: t('SIDEBAR.REPUTATION_LISTINGS'),
                to: accountScopedRoute('reputation_listings'),
                activeOn: ['reputation_listings'],
              },
            ]
          : []),
      ],
    },
    {
      name: 'Autoresponder',
      icon: 'i-lucide-zap',
      confidential: true,
      label: t('SIDEBAR.AUTORESPONDER'),
      children: [
        {
          name: 'Autoresponder Overview',
          label: t('SIDEBAR.AUTORESPONDER_OVERVIEW'),
          to: accountScopedRoute('autoresponder_overview'),
          activeOn: ['autoresponder_overview'],
        },
        {
          name: 'Autoresponder Automations',
          label: t('SIDEBAR.AUTORESPONDER_AUTOMATIONS'),
          to: accountScopedRoute('autoresponder_automations'),
          activeOn: ['autoresponder_automations'],
        },
        {
          name: 'Autoresponder Response Controls',
          label: t('SIDEBAR.AUTORESPONDER_RESPONSE_CONTROLS'),
          to: accountScopedRoute('autoresponder_response_controls'),
          activeOn: ['autoresponder_response_controls'],
        },
        {
          name: 'Autoresponder Accounts Access',
          label: t('SIDEBAR.AUTORESPONDER_ACCOUNTS_ACCESS'),
          to: accountScopedRoute('autoresponder_accounts_access'),
          activeOn: ['autoresponder_accounts_access'],
        },
        {
          name: 'Autoresponder Templates',
          label: t('SIDEBAR.AUTORESPONDER_TEMPLATES'),
          to: accountScopedRoute('autoresponder_templates'),
          activeOn: ['autoresponder_templates'],
        },
        {
          name: 'Autoresponder Activity',
          label: t('SIDEBAR.AUTORESPONDER_ACTIVITY'),
          to: accountScopedRoute('autoresponder_activity'),
          activeOn: ['autoresponder_activity'],
        },
        ...(window.newrelayConfig?.commentAutomationMock
          ? [
              {
                name: 'Autoresponder Mock Instagram',
                label: t('SIDEBAR.AUTORESPONDER_MOCK_INSTAGRAM'),
                to: accountScopedRoute('autoresponder_mock_instagram'),
                activeOn: ['autoresponder_mock_instagram'],
              },
            ]
          : []),
        {
          name: 'Autoresponder Settings',
          label: t('SIDEBAR.AUTORESPONDER_SETTINGS'),
          to: accountScopedRoute('autoresponder_settings'),
          activeOn: ['autoresponder_settings'],
        },
      ],
    },
    {
      name: 'Analytics',
      label: t('SIDEBAR.ANALYTICS'),
      icon: 'i-lucide-chart-bar',
      children: [
        {
          name: 'Reports',
          label: t('SIDEBAR.REPORTS'),
          to: accountScopedRoute('account_overview_reports'),
          activeOn: [
            'conversation_reports',
            'agent_reports_index',
            'agent_reports_show',
            'label_reports_index',
            'label_reports_show',
            'inbox_reports_index',
            'inbox_reports_show',
            'team_reports_index',
            'team_reports_show',
            'csat_reports',
            'sla_reports',
            'bot_reports',
          ],
        },
        {
          name: 'Dashboards',
          label: t('SIDEBAR.DASHBOARDS'),
          disabled: true,
          comingSoon: true,
        },
        {
          name: 'Revenue Analytics',
          label: t('SIDEBAR.REVENUE_ANALYTICS'),
          disabled: true,
          comingSoon: true,
        },
        {
          name: 'Campaign Analytics',
          label: t('SIDEBAR.CAMPAIGN_ANALYTICS'),
          to: accountScopedRoute('campaign_analytics_index'),
          activeOn: ['campaign_analytics_index'],
        },
      ],
    },
    {
      name: 'Portals',
      label: t('SIDEBAR.KNOWLEDGE_BASE'),
      icon: 'i-lucide-help-circle',
      children: [
        {
          name: 'Articles',
          label: t('SIDEBAR.HELP_CENTER.ARTICLES'),
          activeOn: [
            'portals_articles_index',
            'portals_articles_new',
            'portals_articles_edit',
          ],
          to: accountScopedRoute('portals_index', {
            navigationPath: 'portals_articles_index',
          }),
        },
        {
          name: 'Categories',
          label: t('SIDEBAR.HELP_CENTER.CATEGORIES'),
          activeOn: [
            'portals_categories_index',
            'portals_categories_articles_index',
            'portals_categories_articles_new',
            'portals_categories_articles_edit',
          ],
          to: accountScopedRoute('portals_index', {
            navigationPath: 'portals_categories_index',
          }),
        },
        {
          name: 'Locales',
          label: t('SIDEBAR.HELP_CENTER.LOCALES'),
          activeOn: ['portals_locales_index'],
          to: accountScopedRoute('portals_index', {
            navigationPath: 'portals_locales_index',
          }),
        },
        {
          // Distinct from footer account Settings (name: 'Settings')
          name: 'Portal Settings',
          label: t('SIDEBAR.HELP_CENTER.SETTINGS'),
          activeOn: ['portals_settings_index'],
          to: accountScopedRoute('portals_index', {
            navigationPath: 'portals_settings_index',
          }),
        },
      ],
    },
  ];
});

const navSections = computed(() => {
  const items = primaryMenuItems.value
    .filter(item => !isStealthMode.value || !item.confidential)
    .map(item => {
      if (isStealthMode.value && item.name === 'Captain') {
        return { ...item, label: t('SIDEBAR.STEALTH_AI_NAME') };
      }
      return item;
    });
  return [{ items }];
});

const settingsMenuItem = computed(() => {
  const isAdmin =
    currentRole.value === 'administrator' && currentCustomRoleId.value == null;
  return {
    name: 'Settings',
    label: t('SIDEBAR.SETTINGS'),
    icon: 'i-lucide-settings',
    to: accountScopedRoute(isAdmin ? 'general_settings_index' : 'canned_list'),
    activeOn: ['settings_home', ...SETTINGS_ROUTE_NAMES],
  };
});

const logoutMenuItem = computed(() => ({
  name: 'Logout',
  label: t('SIDEBAR_ITEMS.LOGOUT'),
  icon: 'i-lucide-log-out',
  danger: true,
  click: Auth.logout,
}));
</script>

<template>
  <aside
    v-on-click-outside="[
      closeMobileSidebar,
      {
        ignore: [
          '#mobile-sidebar-launcher',
          '[data-popover-content]',
          '[data-popover-backdrop]',
        ],
      },
    ]"
    class="group bg-sidebar text-sidebar-foreground flex h-full flex-col border-sidebar-border fixed top-0 z-40 w-60 pb-px text-sm ltr:left-0 ltr:border-r rtl:right-0 rtl:border-l md:relative md:z-auto md:w-auto md:flex-shrink-0 md:ltr:translate-x-0 md:rtl:translate-x-0"
    :class="[
      {
        'shadow-lg md:shadow-none': isMobileSidebarOpen,
        'ltr:-translate-x-full rtl:translate-x-full': !isMobileSidebarOpen,
        'transition-transform duration-200 ease-linear md:transition-[width]':
          !isResizing,
      },
    ]"
    :data-collapsed="isEffectivelyCollapsed ? 'true' : 'false'"
    :style="isMobile ? undefined : { width: `${sidebarWidth}px` }"
  >
    <!-- Header / brand -->
    <div class="flex flex-col gap-2 p-2 pb-6">
      <div
        class="flex h-12 w-full items-center gap-2 overflow-hidden rounded-md p-2 text-left text-sm transition-[width,height,padding]"
        :class="{
          'justify-center p-1.5': isEffectivelyCollapsed,
        }"
      >
        <div
          class="flex aspect-square size-8 shrink-0 items-center justify-center overflow-hidden rounded-lg bg-sidebar-primary p-1.5 text-sidebar-primary-foreground shadow-xs"
          :title="isEffectivelyCollapsed ? brandName : undefined"
        >
          <img
            v-if="!isStealthMode"
            :src="WHITE_RELAY_LOGO"
            :alt="brandName"
            class="size-full object-contain"
          />
          <span
            v-else
            class="i-lucide-layers size-5 text-sidebar-primary-foreground"
          />
        </div>
        <div
          v-if="!isEffectivelyCollapsed"
          class="grid min-w-0 flex-1 text-left text-sm leading-tight"
        >
          <span class="truncate font-semibold text-sidebar-foreground">
            {{ brandName }}
          </span>
          <span class="truncate text-xs font-normal text-muted-foreground/60">
            {{ brandSubtitle }}
          </span>
        </div>
      </div>
    </div>

    <!-- Content -->
    <nav class="flex min-h-0 flex-1 flex-col overflow-y-auto no-scrollbar">
      <div
        v-for="(section, index) in navSections"
        :key="section.label || 'main'"
        class="relative flex w-full min-w-0 flex-col p-2 pt-0"
        :class="{ 'mt-1': index > 0 }"
      >
        <p
          v-if="section.label && !isEffectivelyCollapsed"
          class="mb-2 px-2 text-xs font-medium text-muted-foreground"
        >
          {{ section.label }}
        </p>
        <ul
          class="m-0 flex w-full min-w-0 list-none flex-col gap-0.5"
          :class="{ 'items-center': isEffectivelyCollapsed }"
        >
          <SidebarGroup
            v-for="item in section.items"
            :key="item.name"
            v-bind="item"
          />
        </ul>
      </div>
    </nav>

    <!-- Footer -->
    <div class="relative mt-auto flex flex-col gap-2 p-2">
      <div
        class="pointer-events-none absolute inset-x-0 -top-8 h-8 bg-gradient-to-t from-sidebar to-transparent"
      />
      <SidebarChangelogCard
        v-if="
          isOnChatwootCloud &&
          !isACustomBrandedInstance &&
          !isEffectivelyCollapsed
        "
      />
      <SidebarChangelogButton
        v-if="
          isOnChatwootCloud &&
          !isACustomBrandedInstance &&
          isEffectivelyCollapsed
        "
      />
      <ul
        class="m-0 flex w-full min-w-0 list-none flex-col gap-1"
        :class="{ 'items-center': isEffectivelyCollapsed }"
      >
        <SidebarGroup v-bind="settingsMenuItem" />
        <SidebarGroup v-bind="logoutMenuItem" />
      </ul>
    </div>

    <!-- Resize Handle (desktop only) -->
    <div
      class="absolute top-0 z-40 hidden h-full w-1 cursor-col-resize group md:block ltr:right-0 rtl:left-0"
      @mousedown="onResizeStart"
      @touchstart="onResizeStart"
      @dblclick="onResizeHandleDoubleClick"
    >
      <div
        class="absolute top-0 h-full w-px bg-transparent transition-colors ltr:right-0 rtl:left-0"
        :class="{ 'bg-sidebar-primary': isResizing }"
      />
    </div>
  </aside>
</template>
