<script>
import { defineAsyncComponent, ref, computed, watch } from 'vue';

import NextSidebar from 'next/sidebar/Sidebar.vue';
import RelayHeader from 'dashboard/components-next/relay/layout/RelayHeader.vue';
import WootKeyShortcutModal from 'dashboard/components/widgets/modal/WootKeyShortcutModal.vue';
import AddAccountModal from 'dashboard/components/app/AddAccountModal.vue';
import UpgradePage from 'dashboard/routes/dashboard/upgrade/UpgradePage.vue';

import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAccount } from 'dashboard/composables/useAccount';
import { useWindowSize } from '@vueuse/core';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import wootConstants from 'dashboard/constants/globals';

const CommandBar = defineAsyncComponent(
  () => import('./commands/commandbar.vue')
);

const FloatingCallWidget = defineAsyncComponent(
  () => import('dashboard/components-next/call/FloatingCallWidget.vue')
);

import CopilotLauncher from 'dashboard/components-next/copilot/CopilotLauncher.vue';
import CopilotContainer from 'dashboard/components/copilot/CopilotContainer.vue';

import MobileSidebarLauncher from 'dashboard/components-next/sidebar/MobileSidebarLauncher.vue';
import { useCallsStore } from 'dashboard/stores/calls';

export default {
  components: {
    NextSidebar,
    RelayHeader,
    CommandBar,
    WootKeyShortcutModal,
    AddAccountModal,
    UpgradePage,
    CopilotLauncher,
    CopilotContainer,
    FloatingCallWidget,
    MobileSidebarLauncher,
  },
  setup() {
    const upgradePageRef = ref(null);
    const { uiSettings, updateUISettings } = useUISettings();
    const { accountId } = useAccount();
    const { width: windowWidth } = useWindowSize();
    const callsStore = useCallsStore();
    const getAccount = useMapGetter('accounts/getAccount');
    const globalConfig = useMapGetter('globalConfig/get');
    const { t } = useI18n();

    const activeLayout = computed(() => {
      if (!accountId.value) return 'classic';
      const account = getAccount.value(accountId.value);
      return account?.custom_attributes?.brand_colors?.layout || 'classic';
    });

    const activeBrandName = computed(() => {
      if (!accountId.value) return '';
      const account = getAccount.value(accountId.value);
      return (
        account?.brand_name ||
        account?.custom_attributes?.brand_colors?.brand_name ||
        ''
      );
    });

    watch(
      activeBrandName,
      newName => {
        if (newName) {
          document.title = newName;
        } else {
          document.title = globalConfig.value?.installationName || 'newrelay';
        }
      },
      { immediate: true }
    );

    return {
      uiSettings,
      updateUISettings,
      accountId,
      upgradePageRef,
      windowWidth,
      activeLayout,
      activeBrandName,
      globalConfig,
      t,
      hasActiveCall: computed(() => callsStore.hasActiveCall),
      hasIncomingCall: computed(() => callsStore.hasIncomingCall),
    };
  },
  data() {
    return {
      showAccountModal: false,
      showCreateAccountModal: false,
      showShortcutModal: false,
      isMobileSidebarOpen: false,
    };
  },
  computed: {
    isSmallScreen() {
      return this.windowWidth < wootConstants.SMALL_SCREEN_BREAKPOINT;
    },
    showUpgradePage() {
      return this.upgradePageRef?.shouldShowUpgradePage;
    },
    bypassUpgradePage() {
      return [
        'billing_settings_index',
        'settings_inbox_list',
        'general_settings_index',
        'agent_list',
      ].includes(this.$route.name);
    },
    previouslyUsedDisplayType() {
      const {
        previously_used_conversation_display_type: conversationDisplayType,
      } = this.uiSettings;
      return conversationDisplayType;
    },
    headerTitle() {
      const routeName = this.$route.name || '';
      if (String(routeName).startsWith('captain')) {
        return this.t('SIDEBAR.CAPTAIN');
      }
      if (['inbox_view', 'inbox_view_conversation'].includes(routeName)) {
        return this.t('INBOX.LIST.TITLE');
      }
      if (
        [
          'home',
          'inbox_conversation',
          'conversation_mentions',
          'conversation_participating',
          'conversation_unattended',
          'folder_conversations',
          'team_conversations',
          'inbox_dashboard',
          'label_conversations',
        ].includes(routeName)
      ) {
        return this.t('SIDEBAR.CUSTOMER_ENGAGEMENT');
      }
      if (
        String(routeName).includes('contact') ||
        String(routeName).includes('compan')
      ) {
        return this.t('SIDEBAR.CRM_AND_SALES');
      }
      if (String(routeName).includes('campaign')) {
        return this.t('SIDEBAR.MARKETING');
      }
      if (
        String(routeName).includes('report') ||
        String(routeName).includes('csat')
      ) {
        return this.t('SIDEBAR.ANALYTICS');
      }
      if (
        String(routeName).includes('portal') ||
        String(routeName).includes('help')
      ) {
        return this.t('SIDEBAR.KNOWLEDGE_BASE');
      }
      if (String(routeName).includes('reputation')) {
        return this.t('SIDEBAR.REPUTATION');
      }
      if (
        String(routeName).includes('settings') ||
        String(routeName).includes('agent_list')
      ) {
        return this.t('SIDEBAR.SETTINGS');
      }
      return (
        this.activeBrandName ||
        this.globalConfig?.installationName ||
        'newrelay'
      );
    },
  },
  watch: {
    isSmallScreen: {
      handler() {
        const { LAYOUT_TYPES } = wootConstants;
        if (window.innerWidth <= wootConstants.SMALL_SCREEN_BREAKPOINT) {
          this.updateUISettings({
            conversation_display_type: LAYOUT_TYPES.EXPANDED,
          });
        } else {
          this.updateUISettings({
            conversation_display_type: this.previouslyUsedDisplayType,
          });
        }
      },
      immediate: true,
    },
  },
  methods: {
    toggleMobileSidebar() {
      this.isMobileSidebarOpen = !this.isMobileSidebarOpen;
    },
    closeMobileSidebar() {
      this.isMobileSidebarOpen = false;
    },
    toggleSidebarCollapse() {
      this.$refs.sidebar?.toggleSidebarCollapse?.();
    },
    openCreateAccountModal() {
      this.showAccountModal = false;
      this.showCreateAccountModal = true;
    },
    closeCreateAccountModal() {
      this.showCreateAccountModal = false;
    },
    toggleAccountModal() {
      this.showAccountModal = !this.showAccountModal;
    },
    toggleKeyShortcutModal() {
      this.showShortcutModal = true;
    },
    closeKeyShortcutModal() {
      this.showShortcutModal = false;
    },
    openSearch() {
      this.$router.push({ name: 'search' });
    },
  },
};
</script>

<template>
  <div
    data-relay
    class="font-geist flex h-full min-h-0 w-full flex-grow overflow-hidden bg-background text-foreground antialiased"
    :class="{
      'flex-row-reverse gap-4 bg-muted p-4': activeLayout === 'documentation',
    }"
  >
    <NextSidebar
      ref="sidebar"
      :is-mobile-sidebar-open="isMobileSidebarOpen"
      :class="{
        'overflow-hidden rounded-2xl border border-sidebar-border bg-sidebar shadow-md':
          activeLayout === 'documentation',
        '!border-l-0 ltr:!border-r-0 rtl:!border-l-0':
          activeLayout === 'documentation',
      }"
      @toggle-account-modal="toggleAccountModal"
      @open-key-shortcut-modal="toggleKeyShortcutModal"
      @close-key-shortcut-modal="closeKeyShortcutModal"
      @close-mobile-sidebar="closeMobileSidebar"
    />

    <div
      class="flex min-h-0 min-w-0 flex-1 flex-col"
      :class="{
        'overflow-hidden rounded-2xl border border-border bg-background shadow-md':
          activeLayout === 'documentation',
      }"
    >
      <RelayHeader
        :title="headerTitle"
        show-desktop-toggle
        @toggle-sidebar="toggleMobileSidebar"
        @toggle-collapse="toggleSidebarCollapse"
        @open-search="openSearch"
        @show-create-account-modal="openCreateAccountModal"
        @open-key-shortcut-modal="toggleKeyShortcutModal"
      />

      <main class="flex min-h-0 w-full flex-1 overflow-hidden bg-background">
        <UpgradePage
          v-show="showUpgradePage"
          ref="upgradePageRef"
          :bypass-upgrade-page="bypassUpgradePage"
        >
          <MobileSidebarLauncher
            :is-mobile-sidebar-open="isMobileSidebarOpen"
            @toggle="toggleMobileSidebar"
          />
        </UpgradePage>
        <template v-if="!showUpgradePage">
          <router-view />
          <CommandBar />
          <CopilotLauncher />
          <MobileSidebarLauncher
            :is-mobile-sidebar-open="isMobileSidebarOpen"
            @toggle="toggleMobileSidebar"
          />
          <CopilotContainer />
          <FloatingCallWidget v-if="hasActiveCall || hasIncomingCall" />
        </template>
        <AddAccountModal
          :show="showCreateAccountModal"
          @close-account-create-modal="closeCreateAccountModal"
        />
        <WootKeyShortcutModal
          v-model:show="showShortcutModal"
          @close="closeKeyShortcutModal"
          @clickaway="closeKeyShortcutModal"
        />
      </main>
    </div>
  </div>
</template>
