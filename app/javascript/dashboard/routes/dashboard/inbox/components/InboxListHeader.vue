<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

import { RelayButton } from 'dashboard/components-next/relay';
import InboxDisplayMenu from './InboxDisplayMenu.vue';
import InboxOptionMenu from './InboxOptionMenu.vue';

const emit = defineEmits(['redirect', 'filter', 'optionClick']);

const { t } = useI18n();

const showInboxDisplayMenu = ref(false);
const showInboxOptionMenu = ref(false);

const closeInboxDisplayMenu = () => {
  showInboxDisplayMenu.value = false;
};

const closeInboxOptionMenu = () => {
  showInboxOptionMenu.value = false;
};

const toggleInboxDisplayMenu = () => {
  showInboxOptionMenu.value = false;
  showInboxDisplayMenu.value = !showInboxDisplayMenu.value;
};

const toggleInboxOptionMenu = () => {
  showInboxDisplayMenu.value = false;
  showInboxOptionMenu.value = !showInboxOptionMenu.value;
};

const onFilterChange = option => {
  emit('filter', option);
  emit('redirect');
};

const onOptionClick = key => {
  closeInboxOptionMenu();
  emit('optionClick', key);
};
</script>

<template>
  <div
    class="flex items-center justify-between w-full gap-1 h-14 border-b border-border/60 px-4 shrink-0 bg-card"
  >
    <div class="flex items-center min-w-0 flex-1">
      <h1 class="text-[16px] font-[500] text-foreground truncate min-w-0">
        {{ t('INBOX.LIST.TITLE') }}
      </h1>
    </div>
    <div class="relative flex items-center gap-2">
      <div v-on-clickaway="closeInboxDisplayMenu" class="relative">
        <RelayButton
          variant="outline"
          size="sm"
          class="h-8 px-3 gap-1"
          @click="toggleInboxDisplayMenu"
        >
          {{ t('INBOX.LIST.DISPLAY_DROPDOWN') }}
          <span class="i-lucide-chevron-down size-3" />
        </RelayButton>
        <InboxDisplayMenu
          v-if="showInboxDisplayMenu"
          class="absolute mt-1.5 top-full ltr:right-0 rtl:left-0 z-50"
          @filter="onFilterChange"
        />
      </div>
      <div v-on-clickaway="closeInboxOptionMenu" class="relative">
        <RelayButton
          variant="outline"
          size="icon"
          class="size-8"
          :aria-label="t('INBOX.LIST.MORE_OPTIONS')"
          @click="toggleInboxOptionMenu"
        >
          <span
            class="i-lucide-sliders-horizontal size-3.5 text-muted-foreground"
          />
        </RelayButton>
        <InboxOptionMenu
          v-if="showInboxOptionMenu"
          class="absolute mt-1.5 top-full ltr:right-0 rtl:left-0 z-50"
          @option-click="onOptionClick"
        />
      </div>
    </div>
  </div>
</template>
