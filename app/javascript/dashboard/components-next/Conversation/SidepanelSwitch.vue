<script setup>
import { RelayTooltip } from 'dashboard/components-next/relay';
import Button from 'dashboard/components-next/button/Button.vue';
import ButtonGroup from 'dashboard/components-next/buttonGroup/ButtonGroup.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { computed } from 'vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useMapGetter } from 'dashboard/composables/store';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

const { updateUISettings } = useUISettings();

const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const showCopilotTab = computed(() =>
  isFeatureEnabledonAccount.value(currentAccountId.value, FEATURE_FLAGS.CAPTAIN)
);

const { uiSettings } = useUISettings();
const isContactSidebarOpen = computed(
  () => uiSettings.value.is_contact_sidebar_open
);
const isCopilotPanelOpen = computed(
  () => uiSettings.value.is_copilot_panel_open
);

const toggleConversationSidebarToggle = () => {
  updateUISettings({
    is_contact_sidebar_open: !isContactSidebarOpen.value,
    is_copilot_panel_open: false,
  });
};

const handleConversationSidebarToggle = () => {
  updateUISettings({
    is_contact_sidebar_open: true,
    is_copilot_panel_open: false,
  });
};

const handleCopilotSidebarToggle = () => {
  updateUISettings({
    is_contact_sidebar_open: false,
    is_copilot_panel_open: true,
  });
};

const keyboardEvents = {
  'Alt+KeyO': {
    action: toggleConversationSidebarToggle,
  },
};
useKeyboardEvents(keyboardEvents);
</script>

<template>
  <ButtonGroup
    class="flex flex-col justify-center items-center absolute top-36 xl:top-24 ltr:right-2 rtl:left-2 bg-secondary/90 backdrop-blur-lg border border-border/50 rounded-full gap-1.5 p-1.5 shadow-sm transition-shadow duration-200 hover:shadow !z-20"
  >
    <RelayTooltip :content="$t('CONVERSATION.SIDEBAR.CONTACT')" side="top">
      <Button
        ghost
        slate
        sm
        class="!rounded-full transition-all duration-[250ms] ease-out active:!scale-95 active:!brightness-105 active:duration-75"
        :class="{ 'bg-accent active:shadow-sm': isContactSidebarOpen }"
        icon="i-ph-user-bold"
        @click="handleConversationSidebarToggle"
      />
    </RelayTooltip>
    <RelayTooltip :content="$t('CONVERSATION.SIDEBAR.COPILOT')">
      <Button
        v-if="showCopilotTab"
        ghost
        slate
        sm
        class="!rounded-full transition-all duration-[250ms] ease-out active:!scale-95 active:duration-75"
        :class="{
          'bg-accent !text-primary active:!brightness-105 active:shadow-sm':
            isCopilotPanelOpen,
        }"
        icon="i-lucide-brain-circuit"
        @click="handleCopilotSidebarToggle"
      />
    </RelayTooltip>
  </ButtonGroup>
</template>
