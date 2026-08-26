<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import {
  RelayCheckbox,
  RelayInput,
  RelaySwitch,
} from 'dashboard/components-next/relay';
import {
  hasPushPermissions,
  requestPushPermissions,
  verifyServiceWorkerExistence,
} from 'dashboard/helper/pushHelper.js';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { NOTIFICATION_TYPES } from './constants';

const INITIAL_VISIBLE = 4;

const { t } = useI18n();
const store = useStore();

const accountId = useMapGetter('getCurrentAccountId');
const emailFlags = useMapGetter(
  'userNotificationSettings/getSelectedEmailFlags'
);
const pushFlags = useMapGetter('userNotificationSettings/getSelectedPushFlags');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const selectedEmailFlags = ref([]);
const selectedPushFlags = ref([]);
const hasEnabledPushPermissions = ref(false);
const searchQuery = ref('');
const showAll = ref(false);

const isSLAEnabled = computed(() =>
  isFeatureEnabledonAccount.value(accountId.value, FEATURE_FLAGS.SLA)
);

const notificationTypes = computed(() =>
  NOTIFICATION_TYPES.filter(notification =>
    isSLAEnabled.value
      ? true
      : ![
          'sla_missed_first_response',
          'sla_missed_next_response',
          'sla_missed_resolution',
        ].includes(notification.value)
  )
);

const filteredNotificationTypes = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return notificationTypes.value;

  return notificationTypes.value.filter(notification => {
    const title = t(notification.label).toLowerCase();
    const description = t(notification.description).toLowerCase();
    return title.includes(query) || description.includes(query);
  });
});

const visibleNotificationTypes = computed(() => {
  if (showAll.value || searchQuery.value.trim()) {
    return filteredNotificationTypes.value;
  }
  return filteredNotificationTypes.value.slice(0, INITIAL_VISIBLE);
});

const canToggleShowMore = computed(
  () =>
    !searchQuery.value.trim() &&
    filteredNotificationTypes.value.length > INITIAL_VISIBLE
);

watch(
  emailFlags,
  value => {
    selectedEmailFlags.value = value || [];
  },
  { immediate: true }
);

watch(
  pushFlags,
  value => {
    selectedPushFlags.value = value || [];
  },
  { immediate: true }
);

const checkFlagStatus = (type, flagType) => {
  const selectedFlags =
    type === 'email' ? selectedEmailFlags.value : selectedPushFlags.value;
  return selectedFlags.includes(`${type}_${flagType}`);
};

const toggleInput = (selected, current) => {
  if (selected.includes(current)) {
    return selected.filter(flag => flag !== current);
  }
  return [...selected, current];
};

const updateNotificationSettings = async () => {
  try {
    await store.dispatch('userNotificationSettings/update', {
      selectedEmailFlags: selectedEmailFlags.value,
      selectedPushFlags: selectedPushFlags.value,
    });
    useAlert(t('PROFILE_SETTINGS.FORM.API.UPDATE_SUCCESS'));
  } catch (error) {
    useAlert(t('PROFILE_SETTINGS.FORM.API.UPDATE_ERROR'));
  }
};

const handleEmailInput = id => {
  selectedEmailFlags.value = toggleInput(selectedEmailFlags.value, id);
  updateNotificationSettings();
};

const handlePushInput = id => {
  selectedPushFlags.value = toggleInput(selectedPushFlags.value, id);
  updateNotificationSettings();
};

const handleChannelToggle = (type, flagType, enabled) => {
  const id = `${type}_${flagType}`;
  const selected =
    type === 'email' ? selectedEmailFlags.value : selectedPushFlags.value;
  const isSelected = selected.includes(id);
  if (enabled === isSelected) return;
  if (type === 'email') {
    handleEmailInput(id);
  } else {
    handlePushInput(id);
  }
};

const onRegistrationSuccess = () => {
  hasEnabledPushPermissions.value = true;
};

const disablePushPermissions = () => {
  verifyServiceWorkerExistence(registration =>
    registration.pushManager
      .getSubscription()
      .then(subscription => {
        if (subscription) {
          return subscription.unsubscribe();
        }
        return null;
      })
      .finally(() => {
        hasEnabledPushPermissions.value = false;
      })
      .catch(() => {})
  );
};

const onRequestPermissions = value => {
  if (value) {
    requestPushPermissions({
      onSuccess: onRegistrationSuccess,
    });
  } else {
    disablePushPermissions();
  }
};

const getPushSubscription = () => {
  verifyServiceWorkerExistence(registration =>
    registration.pushManager
      .getSubscription()
      .then(subscription => {
        hasEnabledPushPermissions.value = Boolean(subscription);
      })
      // eslint-disable-next-line no-console
      .catch(error => console.log(error))
  );
};

onMounted(() => {
  if (hasPushPermissions()) {
    getPushSubscription();
  }
  store.dispatch('userNotificationSettings/get');
});
</script>

<template>
  <div id="profile-settings-notifications" class="flex flex-col gap-6">
    <div class="relative w-full md:max-w-xs md:ml-auto">
      <span
        class="i-lucide-search pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
      />
      <RelayInput
        v-model="searchQuery"
        type="search"
        :placeholder="t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.SEARCH')"
        class-name="pl-9 h-9 bg-background shadow-none"
      />
    </div>

    <!-- Desktop / tablet table -->
    <div class="hidden overflow-x-auto sm:block">
      <div class="min-w-[560px]">
        <div
          class="grid grid-cols-[1fr_auto_auto] gap-4 border-b border-border/40 bg-muted/20 p-4"
        >
          <div
            class="pl-2 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground"
          >
            {{ t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.EVENT') }}
          </div>
          <div
            class="w-16 text-center text-[11px] font-semibold uppercase tracking-wider text-muted-foreground"
          >
            {{ t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.EMAIL') }}
          </div>
          <div
            class="w-16 text-center text-[11px] font-semibold uppercase tracking-wider text-muted-foreground"
          >
            {{ t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.PUSH') }}
          </div>
        </div>

        <div class="divide-y divide-border/40">
          <div
            v-for="notification in visibleNotificationTypes"
            :key="notification.value"
            class="grid grid-cols-[1fr_auto_auto] items-center gap-4 p-4 transition-colors hover:bg-muted/10"
          >
            <div class="flex items-start gap-4">
              <div
                class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary/10"
              >
                <span :class="[notification.icon, 'size-5 text-primary']" />
              </div>
              <div>
                <h4 class="text-sm font-medium text-foreground">
                  {{ t(notification.label) }}
                </h4>
                <p class="mt-0.5 text-xs text-muted-foreground">
                  {{ t(notification.description) }}
                </p>
              </div>
            </div>
            <div class="flex w-16 justify-center">
              <RelayCheckbox
                :model-value="checkFlagStatus('email', notification.value)"
                @update:model-value="
                  enabled =>
                    handleChannelToggle('email', notification.value, enabled)
                "
              />
            </div>
            <div class="flex w-16 justify-center">
              <RelayCheckbox
                :model-value="checkFlagStatus('push', notification.value)"
                @update:model-value="
                  enabled =>
                    handleChannelToggle('push', notification.value, enabled)
                "
              />
            </div>
          </div>

          <div v-if="canToggleShowMore" class="bg-muted/10 p-4">
            <button
              type="button"
              class="flex items-center gap-1 text-sm font-medium text-primary transition-colors hover:text-primary/80"
              @click="showAll = !showAll"
            >
              {{
                showAll
                  ? t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.SHOW_LESS')
                  : t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.SHOW_MORE')
              }}
              <span
                class="i-lucide-chevron-down size-4 transition-transform"
                :class="{ 'rotate-180': showAll }"
              />
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Mobile layout -->
    <div class="flex flex-col gap-4 sm:hidden">
      <div
        v-for="notification in visibleNotificationTypes"
        :key="`mobile-${notification.value}`"
        class="flex flex-col gap-3 rounded-lg border border-border/40 p-4"
      >
        <div class="flex items-start gap-3">
          <div
            class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary/10"
          >
            <span :class="[notification.icon, 'size-5 text-primary']" />
          </div>
          <div>
            <h4 class="text-sm font-medium text-foreground">
              {{ t(notification.label) }}
            </h4>
            <p class="mt-0.5 text-xs text-muted-foreground">
              {{ t(notification.description) }}
            </p>
          </div>
        </div>
        <div class="flex items-center justify-between gap-4">
          <span class="text-xs text-muted-foreground">
            {{ t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.EMAIL') }}
          </span>
          <RelayCheckbox
            :model-value="checkFlagStatus('email', notification.value)"
            @update:model-value="
              enabled =>
                handleChannelToggle('email', notification.value, enabled)
            "
          />
        </div>
        <div class="flex items-center justify-between gap-4">
          <span class="text-xs text-muted-foreground">
            {{ t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.PUSH') }}
          </span>
          <RelayCheckbox
            :model-value="checkFlagStatus('push', notification.value)"
            @update:model-value="
              enabled =>
                handleChannelToggle('push', notification.value, enabled)
            "
          />
        </div>
      </div>

      <button
        v-if="canToggleShowMore"
        type="button"
        class="flex items-center gap-1 text-sm font-medium text-primary"
        @click="showAll = !showAll"
      >
        {{
          showAll
            ? t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.SHOW_LESS')
            : t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.SHOW_MORE')
        }}
        <span
          class="i-lucide-chevron-down size-4 transition-transform"
          :class="{ 'rotate-180': showAll }"
        />
      </button>
    </div>

    <div
      class="flex w-full items-center justify-between gap-3 rounded-xl border border-border/60 bg-card p-4 shadow-sm"
    >
      <div class="flex items-center gap-3 text-foreground">
        <span class="i-lucide-bell size-4 shrink-0 text-muted-foreground" />
        <span class="text-[14px]">
          {{ t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.BROWSER_PERMISSION') }}
        </span>
      </div>
      <RelaySwitch
        :model-value="hasEnabledPushPermissions"
        @update:model-value="onRequestPermissions"
      />
    </div>
  </div>
</template>
