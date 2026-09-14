<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayCheckbox, RelaySwitch } from 'dashboard/components-next/relay';
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
    const title = (
      notification.defaultTitle || t(notification.label)
    ).toLowerCase();
    const description = (
      notification.defaultDescription || t(notification.description)
    ).toLowerCase();
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
  <div id="profile-settings-notifications" class="flex-1 w-full min-w-0">
    <div class="w-full space-y-8">
      <!-- CARD 1: Notification preferences -->
      <div
        class="border border-border/60 bg-card rounded-xl shadow-sm overflow-hidden"
      >
        <div
          class="p-4 sm:p-6 border-b border-border/40 flex flex-col md:flex-row md:items-center justify-between gap-4"
        >
          <div>
            <h3 class="text-base font-semibold text-foreground">
              {{ $t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.TITLE') }}
            </h3>
            <p class="text-sm text-muted-foreground mt-1">
              {{ $t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.NOTE') }}
            </p>
          </div>
          <div class="relative w-full md:w-64">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="lucide absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground lucide-search-icon lucide-search absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground"
              aria-hidden="true"
            >
              <path d="m21 21-4.34-4.34" />
              <circle cx="11" cy="11" r="8" />
            </svg>
            <input
              v-model="searchQuery"
              class="border-input placeholder:text-muted-foreground focus-visible:ring-ring flex w-full rounded-md border px-3 py-1 text-sm transition-colors focus-visible:ring-1 focus-visible:outline-hidden disabled:cursor-not-allowed disabled:opacity-50 pl-9 h-9 bg-background shadow-none"
              :placeholder="$t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.SEARCH')"
            />
          </div>
        </div>

        <div class="overflow-x-auto">
          <div class="min-w-[600px]">
            <!-- Header Row -->
            <div
              class="grid grid-cols-[1fr_auto_auto_auto] gap-4 p-4 border-b border-border/40 bg-muted/20 capitalize"
            >
              <div class="text-[14px] font-semibold text-muted-foreground pl-2">
                {{ $t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.EVENT') }}
              </div>
              <div
                class="text-[14px] font-semibold text-muted-foreground w-16 text-center"
              >
                {{ $t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.IN_APP') }}
              </div>
              <div
                class="text-[14px] font-semibold text-muted-foreground w-16 text-center"
              >
                {{ $t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.EMAIL') }}
              </div>
              <div
                class="text-[14px] font-semibold text-muted-foreground w-16 text-center"
              >
                {{ $t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.PUSH') }}
              </div>
            </div>

            <!-- Table Rows -->
            <div class="divide-y divide-border/40">
              <div
                v-for="notification in visibleNotificationTypes"
                :key="notification.value"
                class="grid grid-cols-[1fr_auto_auto_auto] gap-4 p-4 items-center hover:bg-accent transition-colors"
              >
                <div class="flex items-start gap-4">
                  <div
                    class="size-10 rounded-lg bg-primary/10 flex items-center justify-center shrink-0"
                  >
                    <Icon
                      :icon="notification.icon"
                      class="size-5 text-primary"
                    />
                  </div>
                  <div>
                    <h4 class="text-sm font-medium text-foreground">
                      {{ notification.defaultTitle || t(notification.label) }}
                    </h4>
                    <p class="text-xs text-muted-foreground mt-0.5">
                      {{
                        notification.defaultDescription ||
                        t(notification.description)
                      }}
                    </p>
                  </div>
                </div>

                <!-- In-app Checkbox -->
                <div class="w-16 flex justify-center">
                  <RelayCheckbox
                    :model-value="
                      checkFlagStatus('push', notification.value) ||
                      checkFlagStatus('email', notification.value)
                    "
                    @update:model-value="
                      enabled =>
                        handleChannelToggle('push', notification.value, enabled)
                    "
                  />
                </div>

                <!-- Email Checkbox -->
                <div class="w-16 flex justify-center">
                  <RelayCheckbox
                    :model-value="checkFlagStatus('email', notification.value)"
                    @update:model-value="
                      enabled =>
                        handleChannelToggle(
                          'email',
                          notification.value,
                          enabled
                        )
                    "
                  />
                </div>

                <!-- Push Checkbox -->
                <div class="w-16 flex justify-center">
                  <RelayCheckbox
                    :model-value="checkFlagStatus('push', notification.value)"
                    @update:model-value="
                      enabled =>
                        handleChannelToggle('push', notification.value, enabled)
                    "
                  />
                </div>
              </div>

              <!-- Show More / Show Less Button -->
              <div v-if="canToggleShowMore" class="p-4 bg-muted/10">
                <button
                  type="button"
                  class="text-sm font-medium text-primary hover:text-primary/80 flex items-center gap-1 transition-colors"
                  @click="showAll = !showAll"
                >
                  {{
                    showAll
                      ? $t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.SHOW_LESS')
                      : $t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.SHOW_MORE')
                  }}
                  <Icon
                    icon="i-lucide-chevron-down"
                    class="size-4 transition-transform"
                    :class="{ 'rotate-180': showAll }"
                  />
                </button>
              </div>
            </div>
          </div>
        </div>

        <div
          class="p-4 sm:p-6 border-t border-border/40 flex items-center justify-between gap-4"
        >
          <div class="flex items-center gap-3 text-foreground min-w-0">
            <Icon
              icon="i-lucide-bell"
              class="size-4 text-muted-foreground shrink-0"
            />
            <span class="text-[14px]">
              {{ $t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.BROWSER_PERMISSION') }}
            </span>
          </div>
          <RelaySwitch
            :model-value="hasEnabledPushPermissions"
            @update:model-value="onRequestPermissions"
          />
        </div>
      </div>
    </div>
  </div>
</template>
