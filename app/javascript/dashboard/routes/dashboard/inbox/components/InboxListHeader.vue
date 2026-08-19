<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

import { RelayButton } from 'dashboard/components-next/relay';
import InboxDisplayMenu from './InboxDisplayMenu.vue';

const emit = defineEmits(['redirect', 'filter']);

const { t } = useI18n();

const showInboxDisplayMenu = ref(false);

const openInboxDisplayMenu = () => {
  showInboxDisplayMenu.value = !showInboxDisplayMenu.value;
};

const onFilterChange = option => {
  emit('filter', option);
  showInboxDisplayMenu.value = false;
  emit('redirect');
};
</script>

<template>
  <div
    class="flex items-center justify-between w-full gap-1 h-14 border-b border-border/60 px-4 shrink-0 bg-card"
  >
    <div class="flex items-center min-w-0 flex-1">
      <h1 class="text-base font-semibold text-foreground truncate min-w-0">
        {{ t('INBOX.LIST.TITLE') }}
      </h1>
    </div>
    <div class="relative flex items-center gap-2">
      <div class="relative">
        <RelayButton
          variant="outline"
          size="sm"
          class="h-8 text-xs gap-1 py-1"
          @click="openInboxDisplayMenu"
        >
          {{ t('INBOX.LIST.DISPLAY_DROPDOWN') }}
          <span class="i-lucide-chevron-down size-3" />
        </RelayButton>
        <InboxDisplayMenu
          v-if="showInboxDisplayMenu"
          v-on-clickaway="openInboxDisplayMenu"
          class="absolute mt-1.5 top-full ltr:right-0 rtl:left-0 z-50"
          @filter="onFilterChange"
        />
      </div>
    </div>
  </div>
</template>
