<script setup>
import { computed } from 'vue';
import ContactPanel from 'dashboard/routes/dashboard/conversation/ContactPanel.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useWindowSize } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import wootConstants from 'dashboard/constants/globals';

defineProps({
  currentChat: {
    required: true,
    type: Object,
  },
});

const { updateUISettings, isContactSidebarOpen } = useUISettings();
const { width: windowWidth } = useWindowSize();

const activeTab = computed(() => {
  if (isContactSidebarOpen.value) {
    return 0;
  }
  return null;
});

const isSmallScreen = computed(
  () => windowWidth.value < wootConstants.SMALL_SCREEN_BREAKPOINT
);

const closeContactPanel = () => {
  if (isSmallScreen.value && isContactSidebarOpen.value) {
    updateUISettings({
      is_contact_sidebar_open: false,
      is_copilot_panel_open: false,
    });
  }
};
</script>

<template>
  <div
    v-on-click-outside="[
      () => closeContactPanel(),
      {
        ignore: [
          'dialog.ProseMirror-prompt-backdrop',
          '[data-popover-content]',
          '[data-popover-backdrop]',
        ],
      },
    ]"
    class="fixed top-0 z-40 flex h-full w-full max-w-sm flex-col overflow-hidden bg-sidebar dark:bg-muted/10 transition-all duration-300 ease-in-out ltr:right-0 rtl:left-0 md:static md:w-[300px] md:min-w-[300px] lg:w-[320px] lg:min-w-[320px] 2xl:w-[320px] 2xl:min-w-[320px] ltr:border-l rtl:border-r border-border"
    :class="[
      {
        'md:flex': activeTab === 0,
        'md:hidden': activeTab !== 0,
      },
    ]"
  >
    <div class="flex flex-1 overflow-auto bg-contact-panel">
      <ContactPanel
        v-show="activeTab === 0"
        :conversation-id="currentChat.id"
        :inbox-id="currentChat.inbox_id"
      />
    </div>
  </div>
</template>
