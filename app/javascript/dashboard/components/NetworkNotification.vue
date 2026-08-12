<script setup>
import { ref, computed, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useEmitter } from 'dashboard/composables/emitter';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  isAConversationRoute,
  isAInboxViewRoute,
  isNotificationRoute,
} from 'dashboard/helper/routeHelpers';
import { useEventListener } from '@vueuse/core';

const { t } = useI18n();
const route = useRoute();

const RECONNECTED_BANNER_TIMEOUT = 2000;

const showNotification = ref(!navigator.onLine);
const isDisconnected = ref(false);
const isReconnecting = ref(false);
const isReconnected = ref(false);
let reconnectTimeout = null;

const bannerText = computed(() => {
  if (isReconnecting.value) return t('NETWORK.NOTIFICATION.RECONNECTING');
  if (isReconnected.value) return t('NETWORK.NOTIFICATION.RECONNECT_SUCCESS');
  return t('NETWORK.NOTIFICATION.OFFLINE');
});

const canRefresh = computed(
  () => !isReconnecting.value && !isReconnected.value
);

const refreshPage = () => {
  window.location.reload();
};

const closeNotification = () => {
  showNotification.value = false;
  isReconnected.value = false;
  clearTimeout(reconnectTimeout);
};

const isInAnyOfTheRoutes = routeName => {
  return (
    isAConversationRoute(routeName, true) ||
    isAInboxViewRoute(routeName, true) ||
    isNotificationRoute(routeName, true)
  );
};

const updateWebsocketStatus = () => {
  isDisconnected.value = true;
  showNotification.value = true;
};

const handleReconnectionCompleted = () => {
  isDisconnected.value = false;
  isReconnecting.value = false;
  isReconnected.value = true;
  showNotification.value = true;
  reconnectTimeout = setTimeout(closeNotification, RECONNECTED_BANNER_TIMEOUT);
};

const handleReconnecting = () => {
  if (isInAnyOfTheRoutes(route.name)) {
    isReconnecting.value = true;
    isReconnected.value = false;
    showNotification.value = true;
  } else {
    handleReconnectionCompleted();
  }
};

const updateOnlineStatus = event => {
  if (event.type === 'offline') {
    showNotification.value = true;
  } else if (event.type === 'online' && !isDisconnected.value) {
    handleReconnectionCompleted();
  }
};

useEventListener('online', updateOnlineStatus);
useEventListener('offline', updateOnlineStatus);
useEmitter(BUS_EVENTS.WEBSOCKET_DISCONNECT, updateWebsocketStatus);
useEmitter(
  BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED,
  handleReconnectionCompleted
);
useEmitter(BUS_EVENTS.WEBSOCKET_RECONNECT, handleReconnecting);

onBeforeUnmount(() => {
  clearTimeout(reconnectTimeout);
});
</script>

<template>
  <transition
    enter-active-class="transition-all duration-500 ease-out"
    enter-from-class="opacity-0 translate-y-[60px] scale-95"
    enter-to-class="opacity-100 translate-y-0 scale-100"
    leave-active-class="transition-all duration-500 ease-in-out"
    leave-from-class="opacity-100 translate-y-0 scale-100"
    leave-to-class="opacity-0 translate-y-[60px] scale-95"
  >
    <div
      v-show="showNotification"
      class="fixed bottom-[50px] left-1/2 z-[100] -translate-x-1/2"
    >
      <div
        class="flex items-center justify-between gap-3 rounded-full border px-4 py-2.5 shadow-2xl backdrop-blur-md transition-all"
        :class="{
          'bg-destructive/10 text-destructive border-destructive/30':
            !isReconnecting && !isReconnected,
          'bg-muted/80 text-foreground border-border/50': isReconnecting,
          'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/30':
            isReconnected,
        }"
      >
        <div class="flex items-center gap-2.5">
          <span
            v-if="isReconnecting"
            class="i-lucide-loader-2 size-[16px] shrink-0 animate-spin"
          />
          <span
            v-else-if="isReconnected"
            class="i-lucide-wifi size-[16px] shrink-0"
          />
          <span v-else class="i-lucide-wifi-off size-[16px] shrink-0" />

          <span
            class="whitespace-nowrap text-[13.5px] font-semibold tracking-tight"
          >
            {{ bannerText }}
          </span>
        </div>

        <div class="ml-4 -mr-1 flex items-center gap-1">
          <button
            v-if="canRefresh"
            type="button"
            class="flex size-7 shrink-0 items-center justify-center rounded-full transition-colors hover:bg-destructive/20 hover:text-destructive"
            :title="$t('NETWORK.BUTTON.REFRESH')"
            @click="refreshPage"
          >
            <span class="i-lucide-refresh-cw size-[15px]" />
          </button>

          <button
            type="button"
            class="flex size-7 shrink-0 items-center justify-center rounded-full transition-colors hover:bg-foreground/10"
            @click="closeNotification"
          >
            <span class="i-lucide-x size-[15px]" />
          </button>
        </div>
      </div>
    </div>
  </transition>
</template>
