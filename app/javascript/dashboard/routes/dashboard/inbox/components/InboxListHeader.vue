<script setup>
import { ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert, useTrack } from 'dashboard/composables';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import { RelayButton } from 'dashboard/components-next/relay';
import InboxOptionMenu from './InboxOptionMenu.vue';
import InboxDisplayMenu from './InboxDisplayMenu.vue';

const props = defineProps({
  isContextMenuOpen: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['redirect', 'filter']);

const store = useStore();
const { t } = useI18n();

const showInboxDisplayMenu = ref(false);
const showInboxOptionMenu = ref(false);

watch(
  () => props.isContextMenuOpen,
  val => {
    if (val) {
      showInboxDisplayMenu.value = false;
      showInboxOptionMenu.value = false;
    }
  }
);

const markAllRead = () => {
  useTrack(INBOX_EVENTS.MARK_ALL_NOTIFICATIONS_AS_READ);
  store.dispatch('notifications/readAll').then(() => {
    useAlert(t('INBOX.ALERTS.MARK_ALL_READ'));
  });
};

const deleteAll = () => {
  store.dispatch('notifications/deleteAll').then(() => {
    useAlert(t('INBOX.ALERTS.DELETE_ALL'));
  });
};

const deleteAllRead = () => {
  store.dispatch('notifications/deleteAllRead').then(() => {
    useAlert(t('INBOX.ALERTS.DELETE_ALL_READ'));
  });
};

const openInboxDisplayMenu = () => {
  showInboxDisplayMenu.value = !showInboxDisplayMenu.value;
};

const openInboxOptionsMenu = () => {
  showInboxOptionMenu.value = !showInboxOptionMenu.value;
};

const onInboxOptionMenuClick = key => {
  const actions = {
    mark_all_read: () => markAllRead(),
    delete_all: () => deleteAll(),
    delete_all_read: () => deleteAllRead(),
  };
  const action = actions[key];
  if (action) action();
  emit('redirect');
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
      <RelayButton
        variant="outline"
        size="icon"
        class="h-8 w-8 text-muted-foreground"
        @click="openInboxOptionsMenu"
      >
        <span class="i-lucide-sliders-horizontal size-4" />
      </RelayButton>
      <InboxOptionMenu
        v-if="showInboxOptionMenu"
        v-on-clickaway="openInboxOptionsMenu"
        class="absolute top-full mt-1.5 ltr:right-0 ltr:lg:right-[unset] rtl:left-0 rtl:lg:left-[unset] z-50"
        @option-click="onInboxOptionMenuClick"
      />
    </div>
  </div>
</template>
