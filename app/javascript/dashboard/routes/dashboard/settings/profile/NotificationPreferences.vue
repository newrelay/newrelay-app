<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  RelayButton,
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

const props = defineProps({
  showPageHeader: {
    type: Boolean,
    default: false,
  },
});

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

// Delivery Channels state
const deliveryInApp = ref(true);
const deliveryEmail = ref(true);
const deliveryPush = ref(true);
const deliverySlack = ref(false);
const deliveryTeams = ref(false);

// Quiet hours state
const quietHoursEnabled = ref(false);
const quietHoursFrom = ref('22:00');
const quietHoursTo = ref('07:00');
const selectedTimezone = ref('(GMT+05:30) Asia/Kolkata');
const activeDays = ref(['Mon', 'Tue', 'Wed', 'Thu', 'Fri']);
const availableDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
    const title = (notification.defaultTitle || t(notification.label)).toLowerCase();
    const description = (notification.defaultDescription || t(notification.description)).toLowerCase();
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

const toggleDay = day => {
  if (activeDays.value.includes(day)) {
    activeDays.value = activeDays.value.filter(d => d !== day);
  } else {
    activeDays.value.push(day);
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
  <div id="profile-settings-notifications" class="flex-1 w-full max-w-4xl min-w-0">
    <div class="max-w-3xl space-y-8">
      <!-- CARD 1: Notification preferences -->
      <div class="border border-border/60 bg-card rounded-xl shadow-xs overflow-hidden">
        <div class="p-4 sm:p-6 border-b border-border/40 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h3 class="text-base font-semibold text-foreground">Notification preferences</h3>
            <p class="text-sm text-muted-foreground mt-1">Choose the events you want to be notified about.</p>
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
              <path d="m21 21-4.34-4.34"></path>
              <circle cx="11" cy="11" r="8"></circle>
            </svg>
            <input
              v-model="searchQuery"
              class="border-input placeholder:text-muted-foreground focus-visible:ring-ring flex w-full rounded-md border px-3 py-1 text-sm transition-colors focus-visible:ring-1 focus-visible:outline-hidden disabled:cursor-not-allowed disabled:opacity-50 pl-9 h-9 bg-background shadow-none"
              placeholder="Search events..."
            />
          </div>
        </div>

        <div class="overflow-x-auto">
          <div class="min-w-[600px]">
            <!-- Header Row -->
            <div class="grid grid-cols-[1fr_auto_auto_auto] gap-4 p-4 border-b border-border/40 bg-muted/20">
              <div class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider pl-2">Event</div>
              <div class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider w-16 text-center">In-app</div>
              <div class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider w-16 text-center">Email</div>
              <div class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider w-16 text-center">Push</div>
            </div>

            <!-- Table Rows -->
            <div class="divide-y divide-border/40">
              <div
                v-for="notification in visibleNotificationTypes"
                :key="notification.value"
                class="grid grid-cols-[1fr_auto_auto_auto] gap-4 p-4 items-center hover:bg-muted/10 transition-colors"
              >
                <div class="flex items-start gap-4">
                  <div class="size-10 rounded-lg bg-primary/10 flex items-center justify-center shrink-0">
                    <Icon :icon="notification.icon" class="size-5 text-primary" />
                  </div>
                  <div>
                    <h4 class="text-sm font-medium text-foreground">
                      {{ notification.defaultTitle || t(notification.label) }}
                    </h4>
                    <p class="text-xs text-muted-foreground mt-0.5">
                      {{ notification.defaultDescription || t(notification.description) }}
                    </p>
                  </div>
                </div>

                <!-- In-app Checkbox -->
                <div class="w-16 flex justify-center">
                  <RelayCheckbox
                    :model-value="checkFlagStatus('push', notification.value) || checkFlagStatus('email', notification.value)"
                    @update:model-value="enabled => handleChannelToggle('push', notification.value, enabled)"
                  />
                </div>

                <!-- Email Checkbox -->
                <div class="w-16 flex justify-center">
                  <RelayCheckbox
                    :model-value="checkFlagStatus('email', notification.value)"
                    @update:model-value="enabled => handleChannelToggle('email', notification.value, enabled)"
                  />
                </div>

                <!-- Push Checkbox -->
                <div class="w-16 flex justify-center">
                  <RelayCheckbox
                    :model-value="checkFlagStatus('push', notification.value)"
                    @update:model-value="enabled => handleChannelToggle('push', notification.value, enabled)"
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
                  {{ showAll ? 'Show less' : 'Show more' }}
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
      </div>

      <!-- CARD 2: Delivery channels -->
      <div class="border border-border/60 bg-card rounded-xl shadow-xs overflow-hidden mt-8">
        <div class="p-4 sm:p-6 border-b border-border/40">
          <h3 class="text-base font-semibold text-foreground">Delivery channels</h3>
          <p class="text-sm text-muted-foreground mt-1">Choose where you want to receive notifications.</p>
        </div>

        <div class="p-4 sm:p-6 space-y-6">
          <!-- In-app -->
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4">
              <div class="size-10 flex items-center justify-center shrink-0">
                <Icon icon="i-lucide-monitor" class="size-5 text-muted-foreground" />
              </div>
              <div>
                <h4 class="text-sm font-medium text-foreground">In-app</h4>
                <p class="text-xs text-muted-foreground mt-0.5">Receive notifications inside the platform.</p>
              </div>
            </div>
            <RelayCheckbox v-model="deliveryInApp" />
          </div>

          <!-- Email -->
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4">
              <div class="size-10 flex items-center justify-center shrink-0">
                <Icon icon="i-lucide-mail" class="size-5 text-muted-foreground" />
              </div>
              <div>
                <h4 class="text-sm font-medium text-foreground">Email</h4>
                <p class="text-xs text-muted-foreground mt-0.5">Receive notifications via email.</p>
              </div>
            </div>
            <RelayCheckbox v-model="deliveryEmail" />
          </div>

          <!-- Push notifications -->
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4">
              <div class="size-10 flex items-center justify-center shrink-0">
                <Icon icon="i-lucide-smartphone" class="size-5 text-muted-foreground" />
              </div>
              <div>
                <h4 class="text-sm font-medium text-foreground">Push notifications</h4>
                <p class="text-xs text-muted-foreground mt-0.5">Receive push notifications on your device.</p>
              </div>
            </div>
            <RelayCheckbox
              :model-value="hasEnabledPushPermissions || deliveryPush"
              @update:model-value="onRequestPermissions"
            />
          </div>

          <!-- Slack -->
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4">
              <div class="size-10 flex items-center justify-center shrink-0">
                <Icon icon="i-lucide-hash" class="size-5 text-[#E01E5A]" />
              </div>
              <div>
                <h4 class="text-sm font-medium text-foreground">Slack</h4>
                <p class="text-xs text-muted-foreground mt-0.5">Receive notifications in Slack.</p>
              </div>
            </div>
            <RelayCheckbox v-model="deliverySlack" />
          </div>

          <!-- Microsoft Teams -->
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4">
              <div class="size-10 flex items-center justify-center shrink-0">
                <Icon icon="i-lucide-message-square" class="size-5 text-[#6264A7]" />
              </div>
              <div>
                <h4 class="text-sm font-medium text-foreground">Microsoft Teams</h4>
                <p class="text-xs text-muted-foreground mt-0.5">Receive notifications in Microsoft Teams.</p>
              </div>
            </div>
            <RelayCheckbox v-model="deliveryTeams" />
          </div>

          <!-- Manage Integrations Link -->
          <div class="pt-2">
            <router-link
              to="integrations"
              class="text-sm font-medium text-primary hover:text-primary/80 flex items-center gap-1.5 transition-colors"
            >
              Manage integrations
              <Icon icon="i-lucide-external-link" class="size-3.5" />
            </router-link>
          </div>
        </div>
      </div>

      <!-- CARD 3: Quiet hours -->
      <div class="border border-border/60 bg-card rounded-xl shadow-xs overflow-hidden mt-8 mb-4">
        <div
          class="p-4 sm:p-6 flex flex-col md:flex-row md:items-center justify-between gap-4"
          :class="{ 'border-b border-border/40': quietHoursEnabled }"
        >
          <div>
            <h3 class="text-base font-semibold text-foreground">Quiet hours</h3>
            <p class="text-sm text-muted-foreground mt-1">Pause non-urgent notifications during these hours.</p>
          </div>
          <RelaySwitch v-model="quietHoursEnabled" />
        </div>

        <div v-if="quietHoursEnabled" class="p-6 space-y-6">
          <!-- From & To Row -->
          <div class="flex flex-col sm:flex-row items-center gap-6">
            <!-- From -->
            <div class="flex items-center gap-4 w-full sm:w-1/2">
              <span class="text-sm font-medium text-muted-foreground w-12 shrink-0">From</span>
              <div class="relative flex-1">
                <input
                  v-model="quietHoursFrom"
                  type="text"
                  class="w-full h-11 rounded-xl border border-border/60 bg-muted/20 px-4 pr-10 text-sm font-medium text-foreground shadow-xs transition-colors focus:border-primary focus:outline-none"
                  placeholder="22:00"
                />
                <Icon
                  icon="i-lucide-clock"
                  class="pointer-events-none absolute right-3.5 top-1/2 -translate-y-1/2 size-4 text-muted-foreground"
                />
              </div>
            </div>

            <!-- To -->
            <div class="flex items-center gap-4 w-full sm:w-1/2">
              <span class="text-sm font-medium text-muted-foreground w-8 text-center shrink-0">To</span>
              <div class="relative flex-1">
                <input
                  v-model="quietHoursTo"
                  type="text"
                  class="w-full h-11 rounded-xl border border-border/60 bg-muted/20 px-4 pr-10 text-sm font-medium text-foreground shadow-xs transition-colors focus:border-primary focus:outline-none"
                  placeholder="07:00"
                />
                <Icon
                  icon="i-lucide-clock"
                  class="pointer-events-none absolute right-3.5 top-1/2 -translate-y-1/2 size-4 text-muted-foreground"
                />
              </div>
            </div>
          </div>

          <!-- Time zone -->
          <div class="flex flex-col sm:flex-row sm:items-center gap-4">
            <span class="text-sm font-medium text-muted-foreground w-12 shrink-0 leading-tight">Time<br class="hidden sm:inline" />zone</span>
            <div class="relative flex-1">
              <select
                v-model="selectedTimezone"
                class="w-full appearance-none h-11 rounded-xl border border-border/60 bg-background px-4 pr-10 text-sm font-medium text-foreground shadow-xs transition-colors focus:border-primary focus:outline-none cursor-pointer"
              >
                <option value="(GMT+05:30) Asia/Kolkata">(GMT+05:30) Asia/Kolkata</option>
                <option value="(GMT+00:00) UTC">(GMT+00:00) UTC</option>
                <option value="(GMT-05:00) Eastern Time">(GMT-05:00) Eastern Time</option>
                <option value="(GMT-08:00) Pacific Time">(GMT-08:00) Pacific Time</option>
              </select>
              <Icon
                icon="i-lucide-chevron-down"
                class="pointer-events-none absolute right-3.5 top-1/2 -translate-y-1/2 size-4 text-muted-foreground opacity-60"
              />
            </div>
          </div>

          <!-- Day selector pills -->
          <div class="flex flex-wrap gap-2 pt-2">
            <button
              v-for="day in availableDays"
              :key="day"
              type="button"
              class="px-4 py-2 text-xs font-medium rounded transition-colors border"
              :class="[
                activeDays.includes(day)
                  ? 'border-primary/20 bg-primary/10 text-primary'
                  : 'border-border bg-background text-muted-foreground hover:bg-muted'
              ]"
              @click="toggleDay(day)"
            >
              {{ day }}
            </button>
          </div>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="pt-6 pb-2 flex justify-end gap-3 border-t border-border/40 mt-8">
        <button
          type="button"
          class="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-hidden focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0 border border-input bg-background shadow-xs hover:bg-accent hover:text-accent-foreground hover:border-transparent h-9 px-4 py-2"
        >
          Cancel
        </button>
        <button
          type="button"
          class="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-hidden focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0 bg-primary text-primary-foreground hover:bg-primary/90 h-9 px-4 py-2 shadow-sm"
          @click="updateNotificationSettings"
        >
          Save changes
        </button>
      </div>
    </div>
  </div>
</template>
