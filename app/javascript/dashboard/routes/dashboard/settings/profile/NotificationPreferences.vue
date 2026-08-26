<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
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
  <div id="profile-settings-notifications" class="flex flex-col gap-6">
    <!-- Top Page Header (when showPageHeader is true or in tab view) -->
    <div v-if="showPageHeader" class="flex flex-col gap-1">
      <h2 class="text-xl font-semibold tracking-tight text-foreground">
        {{ t('NOTIFICATION_SETTINGS.TITLE') }}
      </h2>
      <p class="text-sm text-muted-foreground">
        {{ t('NOTIFICATION_SETTINGS.DESCRIPTION') }}
      </p>
    </div>

    <!-- CARD 1: Notification preferences Card -->
    <div
      class="rounded-xl border border-border/60 bg-card p-6 shadow-xs transition-colors"
    >
      <!-- Header row with title & search -->
      <div
        class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between pb-6 border-b border-border/40"
      >
        <div>
          <h3 class="text-[17px] font-semibold text-foreground">
            {{ t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.PREFERENCES_TITLE') || 'Notification preferences' }}
          </h3>
          <p class="mt-0.5 text-xs text-muted-foreground">
            {{ t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.PREFERENCES_SUBTITLE') || 'Choose the events you want to be notified about.' }}
          </p>
        </div>

        <div class="relative w-full sm:w-64">
          <span
            class="i-lucide-search pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
          />
          <RelayInput
            v-model="searchQuery"
            type="search"
            :placeholder="t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.SEARCH')"
            class-name="pl-9 h-9 bg-background shadow-xs text-xs rounded-md"
          />
        </div>
      </div>

      <!-- Desktop / tablet table -->
      <div class="hidden overflow-x-auto sm:block">
        <div class="min-w-[620px]">
          <!-- Table Header -->
          <div
            class="grid grid-cols-[1fr_72px_72px_72px] items-center gap-4 py-3.5 px-2 border-b border-border/40"
          >
            <div
              class="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground"
            >
              {{ t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.EVENT') }}
            </div>
            <div
              class="text-center text-[11px] font-semibold uppercase tracking-wider text-muted-foreground"
            >
              {{ t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.IN_APP') || 'IN-APP' }}
            </div>
            <div
              class="text-center text-[11px] font-semibold uppercase tracking-wider text-muted-foreground"
            >
              {{ t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.EMAIL') }}
            </div>
            <div
              class="text-center text-[11px] font-semibold uppercase tracking-wider text-muted-foreground"
            >
              {{ t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.PUSH') }}
            </div>
          </div>

          <!-- Table Rows -->
          <div class="divide-y divide-border/40">
            <div
              v-for="notification in visibleNotificationTypes"
              :key="notification.value"
              class="grid grid-cols-[1fr_72px_72px_72px] items-center gap-4 py-4 px-2 transition-colors hover:bg-muted/10"
            >
              <div class="flex items-center gap-3.5">
                <div
                  class="flex size-9 shrink-0 items-center justify-center rounded-lg bg-indigo-50 text-indigo-600 dark:bg-indigo-950/60 dark:text-indigo-400"
                >
                  <span :class="[notification.icon, 'size-4']" />
                </div>
                <div>
                  <h4 class="text-sm font-medium text-foreground">
                    {{ notification.defaultTitle || t(notification.label) }}
                  </h4>
                  <p class="mt-0.5 text-xs text-muted-foreground">
                    {{ notification.defaultDescription || t(notification.description) }}
                  </p>
                </div>
              </div>

              <!-- IN-APP Checkbox -->
              <div class="flex justify-center">
                <RelayCheckbox
                  :model-value="checkFlagStatus('push', notification.value) || checkFlagStatus('email', notification.value)"
                  @update:model-value="
                    enabled =>
                      handleChannelToggle('push', notification.value, enabled)
                  "
                />
              </div>

              <!-- EMAIL Checkbox -->
              <div class="flex justify-center">
                <RelayCheckbox
                  :model-value="checkFlagStatus('email', notification.value)"
                  @update:model-value="
                    enabled =>
                      handleChannelToggle('email', notification.value, enabled)
                  "
                />
              </div>

              <!-- PUSH Checkbox -->
              <div class="flex justify-center">
                <RelayCheckbox
                  :model-value="checkFlagStatus('push', notification.value)"
                  @update:model-value="
                    enabled =>
                      handleChannelToggle('push', notification.value, enabled)
                  "
                />
              </div>
            </div>

            <!-- Show More / Show Less Toggle -->
            <div v-if="canToggleShowMore" class="pt-4 px-2">
              <button
                type="button"
                class="flex items-center gap-1.5 text-xs font-medium text-primary transition-colors hover:underline"
                @click="showAll = !showAll"
              >
                {{
                  showAll
                    ? (t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.SHOW_LESS') || 'Show less')
                    : (t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.SHOW_MORE') || 'Show more')
                }}
                <span
                  class="i-lucide-chevron-down size-3.5 transition-transform"
                  :class="{ 'rotate-180': showAll }"
                />
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Mobile layout -->
      <div class="flex flex-col gap-4 sm:hidden pt-4">
        <div
          v-for="notification in visibleNotificationTypes"
          :key="`mobile-${notification.value}`"
          class="flex flex-col gap-3 rounded-lg border border-border/40 p-4"
        >
          <div class="flex items-start gap-3">
            <div
              class="flex size-9 shrink-0 items-center justify-center rounded-lg bg-indigo-50 text-indigo-600 dark:bg-indigo-950/60 dark:text-indigo-400"
            >
              <span :class="[notification.icon, 'size-4']" />
            </div>
            <div>
              <h4 class="text-sm font-medium text-foreground">
                {{ notification.defaultTitle || t(notification.label) }}
              </h4>
              <p class="mt-0.5 text-xs text-muted-foreground">
                {{ notification.defaultDescription || t(notification.description) }}
              </p>
            </div>
          </div>
          <div class="flex items-center justify-between gap-4">
            <span class="text-xs text-muted-foreground">
              {{ t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.IN_APP') || 'IN-APP' }}
            </span>
            <RelayCheckbox
              :model-value="checkFlagStatus('push', notification.value) || checkFlagStatus('email', notification.value)"
              @update:model-value="
                enabled =>
                  handleChannelToggle('push', notification.value, enabled)
              "
            />
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
          class="flex items-center gap-1 text-xs font-medium text-primary hover:underline"
          @click="showAll = !showAll"
        >
          {{
            showAll
              ? (t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.SHOW_LESS') || 'Show less')
              : (t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.SHOW_MORE') || 'Show more')
          }}
          <span
            class="i-lucide-chevron-down size-3.5 transition-transform"
            :class="{ 'rotate-180': showAll }"
          />
        </button>
      </div>
    </div>

    <!-- CARD 2: Delivery channels Card -->
    <div
      class="rounded-xl border border-border/60 bg-card p-6 shadow-xs transition-colors"
    >
      <div class="mb-6">
        <h3 class="text-[17px] font-semibold text-foreground">
          {{ t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.DELIVERY_CHANNELS') || 'Delivery channels' }}
        </h3>
        <p class="mt-0.5 text-xs text-muted-foreground">
          {{ t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.DELIVERY_CHANNELS_SUBTITLE') || 'Choose where you want to receive notifications.' }}
        </p>
      </div>

      <div class="divide-y divide-border/40">
        <!-- In-app -->
        <div class="flex items-center justify-between py-3.5">
          <div class="flex items-center gap-3">
            <span class="i-lucide-monitor size-4 text-muted-foreground" />
            <div>
              <h4 class="text-xs font-medium text-foreground">In-app</h4>
              <p class="text-[11px] text-muted-foreground">Receive notifications inside the platform.</p>
            </div>
          </div>
          <RelayCheckbox v-model="deliveryInApp" />
        </div>

        <!-- Email -->
        <div class="flex items-center justify-between py-3.5">
          <div class="flex items-center gap-3">
            <span class="i-lucide-mail size-4 text-muted-foreground" />
            <div>
              <h4 class="text-xs font-medium text-foreground">Email</h4>
              <p class="text-[11px] text-muted-foreground">Receive notifications via email.</p>
            </div>
          </div>
          <RelayCheckbox v-model="deliveryEmail" />
        </div>

        <!-- Push notifications -->
        <div class="flex items-center justify-between py-3.5">
          <div class="flex items-center gap-3">
            <span class="i-lucide-smartphone size-4 text-muted-foreground" />
            <div>
              <h4 class="text-xs font-medium text-foreground">Push notifications</h4>
              <p class="text-[11px] text-muted-foreground">Receive push notifications on your device.</p>
            </div>
          </div>
          <RelayCheckbox
            :model-value="hasEnabledPushPermissions || deliveryPush"
            @update:model-value="onRequestPermissions"
          />
        </div>

        <!-- Slack -->
        <div class="flex items-center justify-between py-3.5">
          <div class="flex items-center gap-3">
            <span class="i-lucide-hash size-4 text-muted-foreground" />
            <div>
              <h4 class="text-xs font-medium text-foreground">Slack</h4>
              <p class="text-[11px] text-muted-foreground">Receive notifications in Slack.</p>
            </div>
          </div>
          <RelayCheckbox v-model="deliverySlack" />
        </div>

        <!-- Microsoft Teams -->
        <div class="flex items-center justify-between py-3.5">
          <div class="flex items-center gap-3">
            <span class="i-lucide-message-square size-4 text-muted-foreground" />
            <div>
              <h4 class="text-xs font-medium text-foreground">Microsoft Teams</h4>
              <p class="text-[11px] text-muted-foreground">Receive notifications in Microsoft Teams.</p>
            </div>
          </div>
          <RelayCheckbox v-model="deliveryTeams" />
        </div>
      </div>

      <div class="pt-4">
        <router-link
          to="integrations"
          class="inline-flex items-center gap-1 text-xs font-medium text-primary hover:underline"
        >
          Manage integrations
          <span class="i-lucide-external-link size-3" />
        </router-link>
      </div>
    </div>

    <!-- CARD 3: Quiet hours Card -->
    <div
      class="rounded-xl border border-border/60 bg-card p-6 shadow-xs transition-colors"
    >
      <div class="flex items-center justify-between mb-4">
        <div>
          <h3 class="text-[17px] font-semibold text-foreground">
            Quiet hours
          </h3>
          <p class="mt-0.5 text-xs text-muted-foreground">
            Pause non-urgent notifications during these hours.
          </p>
        </div>
        <RelaySwitch v-model="quietHoursEnabled" />
      </div>

      <div v-if="quietHoursEnabled" class="flex flex-col gap-4 pt-2">
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label class="block text-xs font-medium text-muted-foreground mb-1">From</label>
            <div class="relative">
              <input
                v-model="quietHoursFrom"
                type="time"
                class="h-9 w-full rounded-md border border-input bg-background px-3 text-xs text-foreground shadow-xs focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring cursor-pointer"
              />
            </div>
          </div>
          <div>
            <label class="block text-xs font-medium text-muted-foreground mb-1">To</label>
            <div class="relative">
              <input
                v-model="quietHoursTo"
                type="time"
                class="h-9 w-full rounded-md border border-input bg-background px-3 text-xs text-foreground shadow-xs focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring cursor-pointer"
              />
            </div>
          </div>
        </div>

        <div>
          <label class="block text-xs font-medium text-muted-foreground mb-1">Time zone</label>
          <select
            v-model="selectedTimezone"
            class="w-full h-9 rounded-md border border-input bg-background px-3 text-xs text-foreground shadow-xs focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          >
            <option value="(GMT+05:30) Asia/Kolkata">(GMT+05:30) Asia/Kolkata</option>
            <option value="(GMT+00:00) UTC">(GMT+00:00) UTC</option>
            <option value="(GMT-05:00) Eastern Time">(GMT-05:00) Eastern Time</option>
            <option value="(GMT-08:00) Pacific Time">(GMT-08:00) Pacific Time</option>
          </select>
        </div>

        <div class="flex flex-wrap gap-2 pt-1">
          <button
            v-for="day in availableDays"
            :key="day"
            type="button"
            class="px-3 py-1.5 rounded-md text-xs font-medium border transition-colors"
            :class="[
              activeDays.includes(day)
                ? 'bg-indigo-50 border-indigo-200 text-indigo-600 dark:bg-indigo-950/60 dark:border-indigo-800 dark:text-indigo-300'
                : 'bg-background border-border/60 text-muted-foreground hover:bg-muted/10'
            ]"
            @click="toggleDay(day)"
          >
            {{ day }}
          </button>
        </div>
      </div>
    </div>

    <!-- Bottom Action Bar -->
    <div class="flex items-center justify-end gap-3 pt-2">
      <RelayButton variant="outline" size="sm">
        Cancel
      </RelayButton>
      <RelayButton variant="primary" size="sm" @click="updateNotificationSettings">
        Save changes
      </RelayButton>
    </div>
  </div>
</template>
