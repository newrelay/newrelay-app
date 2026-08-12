<script setup>
import { computed, ref } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import Auth from 'dashboard/api/auth';
import RelaySwitch from '../switch/Switch.vue';
import { useImpersonation } from 'dashboard/composables/useImpersonation';
import { useAlert } from 'dashboard/composables';

const emit = defineEmits(['showCreateAccountModal', 'openKeyShortcutModal']);

const { t } = useI18n();
const store = useStore();
const { accountId, currentAccount } = useAccount();
const currentUser = useMapGetter('getCurrentUser');
const currentUserAvailability = useMapGetter('getCurrentUserAvailability');
const currentUserAutoOffline = useMapGetter('getCurrentUserAutoOffline');
const currentAccountId = useMapGetter('getCurrentAccountId');
const globalConfig = useMapGetter('globalConfig/get');
const { isImpersonating } = useImpersonation();

const isOpen = ref(false);
const isStatusOpen = ref(false);

const isAdmin = computed(() => {
  if (currentUser.value.type === 'SuperAdmin') return true;
  const current = (currentUser.value.accounts || []).find(
    a => a.id === accountId.value
  );
  return current?.role === 'administrator';
});

const isSubAccount = computed(() => {
  const current = (currentUser.value.accounts || []).find(
    a => a.id === accountId.value
  );
  return !!current?.parent_id;
});

const canCreateWorkspace = computed(
  () =>
    globalConfig.value.createNewAccountFromDashboard &&
    isAdmin.value &&
    !isSubAccount.value
);

const brandInitial = computed(() => {
  const name =
    currentAccount.value?.name || globalConfig.value?.installationName || 'N';
  return name.charAt(0).toUpperCase();
});

const brandSubtitle = computed(() => t('SIDEBAR.ENTERPRISE_EDITION'));

const availabilityLabel = computed(() => {
  if (currentUserAvailability.value === 'online')
    return t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.ONLINE');
  if (currentUserAvailability.value === 'busy')
    return t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.BUSY');
  return t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.OFFLINE');
});

const statusDotClass = computed(() => {
  if (currentUserAvailability.value === 'online') return 'bg-emerald-500';
  if (currentUserAvailability.value === 'busy') return 'bg-amber-500';
  return 'bg-muted-foreground';
});

const autoOfflineToggle = computed({
  get: () => currentUserAutoOffline.value,
  set: autoOffline => {
    store.dispatch('updateAutoOffline', {
      accountId: currentAccountId.value,
      autoOffline,
    });
  },
});

function changeAvailabilityStatus(availability) {
  if (isImpersonating.value) {
    useAlert(t('PROFILE_SETTINGS.FORM.AVAILABILITY.IMPERSONATING_ERROR'));
    return;
  }
  try {
    store.dispatch('updateAvailability', {
      availability,
      account_id: currentAccountId.value,
    });
    isStatusOpen.value = false;
  } catch (error) {
    useAlert(t('PROFILE_SETTINGS.FORM.AVAILABILITY.SET_AVAILABILITY_ERROR'));
  }
}

const sortedAccounts = computed(() => {
  const accounts = currentUser.value.accounts || [];
  const parents = accounts
    .filter(a => !a.parent_id)
    .sort((a, b) => a.name.localeCompare(b.name));
  const result = [];

  parents.forEach(parent => {
    result.push(parent);
    accounts
      .filter(a => a.parent_id === parent.id)
      .sort((a, b) => a.name.localeCompare(b.name))
      .forEach(child => {
        result.push({ ...child, isChild: true });
      });
  });

  const childIds = result.map(a => a.id);
  accounts
    .filter(a => a.parent_id && !childIds.includes(a.id))
    .sort((a, b) => a.name.localeCompare(b.name))
    .forEach(orphan => result.push(orphan));

  return result;
});

const availableWorkspaces = computed(() =>
  sortedAccounts.value.filter(account => account.id !== accountId.value)
);

const accountInitial = name => (name || 'W').charAt(0).toUpperCase();

const closeMenu = () => {
  isOpen.value = false;
  isStatusOpen.value = false;
};

const toggleMenu = () => {
  isOpen.value = !isOpen.value;
  if (!isOpen.value) isStatusOpen.value = false;
};

const onChangeAccount = newId => {
  closeMenu();
  window.location.href = `/app/accounts/${newId}/dashboard`;
};

const onAddWorkspace = () => {
  closeMenu();
  emit('showCreateAccountModal');
};

const onLogout = () => {
  closeMenu();
  Auth.logout();
};
</script>

<template>
  <div v-on-click-outside="closeMenu" class="relative">
    <button
      type="button"
      class="flex items-center gap-2 rounded-full border border-input bg-background py-1 pl-1 pr-2 text-left text-sm shadow-xs transition-colors hover:border-transparent hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
      :class="{ 'bg-accent': isOpen }"
      :aria-expanded="isOpen"
      @click="toggleMenu"
    >
      <div class="relative">
        <img
          v-if="currentUser?.avatar_url"
          :src="currentUser.avatar_url"
          :alt="currentUser.available_name"
          class="size-8 rounded-full object-cover shrink-0"
        />
        <div
          v-else
          class="flex size-8 shrink-0 items-center justify-center rounded-full bg-primary text-sm font-bold text-primary-foreground"
        >
          {{ brandInitial }}
        </div>
        <div
          class="absolute -bottom-0.5 -right-0.5 size-3 rounded-full border-2 border-background"
          :class="statusDotClass"
        />
      </div>
      <div class="hidden items-center gap-1.5 md:flex">
        <span class="max-w-28 truncate text-sm font-medium text-foreground">
          {{ currentAccount.name }}
        </span>
        <span
          class="i-lucide-chevron-down size-3.5 shrink-0 text-muted-foreground"
        />
      </div>
    </button>

    <div
      v-if="isOpen"
      class="absolute top-full z-50 mt-1 w-64 rounded-xl border border-border bg-popover p-2 text-popover-foreground shadow-sm ltr:right-0 rtl:left-0"
    >
      <!-- Current Workspace Header -->
      <div class="mb-1 rounded-md p-0 font-normal">
        <div class="flex items-center gap-3 px-2 py-2">
          <div class="relative">
            <img
              v-if="currentUser?.avatar_url"
              :src="currentUser.avatar_url"
              :alt="currentUser.available_name"
              class="size-8 rounded-full object-cover shrink-0"
            />
            <div
              v-else
              class="flex size-8 shrink-0 items-center justify-center rounded-full bg-primary text-sm font-bold text-primary-foreground"
            >
              {{ brandInitial }}
            </div>
            <div
              class="absolute -bottom-0.5 -right-0.5 size-3 rounded-full border-2 border-background"
              :class="statusDotClass"
            />
          </div>
          <div class="grid min-w-0 flex-1 text-left text-sm leading-tight">
            <span class="truncate font-semibold text-foreground">
              {{ currentAccount.name }}
            </span>
            <span class="truncate text-xs font-normal text-muted-foreground">
              {{ brandSubtitle }}
            </span>
          </div>
          <button
            type="button"
            class="ml-auto flex size-8 shrink-0 items-center justify-center rounded-md bg-destructive/10 text-destructive transition-colors hover:bg-destructive/20 cursor-pointer"
            :title="t('SIDEBAR_ITEMS.LOGOUT')"
            @click="onLogout"
          >
            <span class="i-lucide-log-out size-4" />
          </button>
        </div>
      </div>

      <div class="my-2 h-px bg-border" />

      <!-- Status Selector -->
      <div class="relative">
        <button
          type="button"
          class="flex w-full cursor-pointer items-center justify-between rounded-md px-2 py-1.5 text-sm transition-colors hover:bg-accent hover:text-accent-foreground"
          @click="isStatusOpen = !isStatusOpen"
        >
          <span>{{ t('SIDEBAR.STATUS') }}</span>
          <div
            class="flex items-center gap-1.5 rounded border border-border/50 bg-muted/50 px-2 py-1 text-xs font-medium"
          >
            <div class="size-2 rounded-full" :class="statusDotClass" />
            <span>{{ availabilityLabel }}</span>
            <span
              class="i-lucide-chevron-down size-3 ml-0.5 text-muted-foreground"
            />
          </div>
        </button>

        <div
          v-if="isStatusOpen"
          class="mt-1 w-full rounded-md border border-border bg-popover p-1 shadow-md"
        >
          <button
            type="button"
            class="flex w-full cursor-pointer items-center gap-2 rounded-md px-2 py-1.5 text-sm transition-colors hover:bg-accent"
            @click="changeAvailabilityStatus('online')"
          >
            <span class="size-2.5 rounded-full bg-emerald-500" />
            <span>{{
              t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.ONLINE')
            }}</span>
            <span
              v-if="currentUserAvailability === 'online'"
              class="i-lucide-check ml-auto size-3.5 text-primary"
            />
          </button>
          <button
            type="button"
            class="flex w-full cursor-pointer items-center gap-2 rounded-md px-2 py-1.5 text-sm transition-colors hover:bg-accent"
            @click="changeAvailabilityStatus('busy')"
          >
            <span class="size-2.5 rounded-full bg-amber-500" />
            <span>{{
              t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.BUSY')
            }}</span>
            <span
              v-if="currentUserAvailability === 'busy'"
              class="i-lucide-check ml-auto size-3.5 text-primary"
            />
          </button>
          <button
            type="button"
            class="flex w-full cursor-pointer items-center gap-2 rounded-md px-2 py-1.5 text-sm transition-colors hover:bg-accent"
            @click="changeAvailabilityStatus('offline')"
          >
            <span class="size-2.5 rounded-full bg-muted-foreground" />
            <span>{{
              t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.OFFLINE')
            }}</span>
            <span
              v-if="currentUserAvailability === 'offline'"
              class="i-lucide-check ml-auto size-3.5 text-primary"
            />
          </button>
        </div>
      </div>

      <!-- Auto Offline Toggle -->
      <div
        class="mt-1 flex w-full items-center justify-between rounded-md px-2 py-2 text-sm"
      >
        <div class="flex items-center gap-1.5">
          <span>{{ t('SIDEBAR.SET_AUTO_OFFLINE.TEXT') }}</span>
          <span
            v-tooltip.top="$t('SIDEBAR.SET_AUTO_OFFLINE.INFO_SHORT')"
            class="i-lucide-info size-3.5 cursor-help text-muted-foreground"
          />
        </div>
        <RelaySwitch v-model="autoOfflineToggle" />
      </div>

      <div class="my-2 h-px bg-border" />

      <p class="px-2 pb-2 pt-1 text-xs font-semibold text-muted-foreground">
        {{ t('SIDEBAR_ITEMS.AVAILABLE_WORKSPACES') }}
      </p>

      <div
        v-if="availableWorkspaces.length"
        class="mb-1 max-h-48 overflow-y-auto"
      >
        <button
          v-for="account in availableWorkspaces"
          :id="`workspace-${account.id}`"
          :key="account.id"
          type="button"
          class="flex w-full cursor-pointer items-center gap-2 rounded-md p-2 text-left transition-colors hover:bg-accent"
          @click="onChangeAccount(account.id)"
        >
          <span
            class="flex size-6 shrink-0 items-center justify-center rounded-full bg-secondary text-xs font-bold text-secondary-foreground"
          >
            {{ accountInitial(account.name) }}
          </span>
          <span
            class="truncate text-sm text-foreground"
            :class="{ 'pl-2 text-muted-foreground': account.isChild }"
          >
            {{ account.name }}
          </span>
        </button>
      </div>
      <p v-else class="px-2 pb-2 text-xs text-muted-foreground">
        {{ t('SIDEBAR_ITEMS.NO_OTHER_WORKSPACES') }}
      </p>

      <div v-if="canCreateWorkspace" class="my-1 h-px bg-border" />

      <button
        v-if="canCreateWorkspace"
        type="button"
        class="flex w-full cursor-pointer items-center gap-2 rounded-md p-2 text-left text-sm text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
        @click="onAddWorkspace"
      >
        <span class="i-lucide-plus size-4 shrink-0" />
        <span>{{ t('SIDEBAR_ITEMS.ADD_NEW_WORKSPACE') }}</span>
      </button>

      <div class="my-1 h-px bg-border" />

      <router-link
        :to="{ name: 'profile_settings_index' }"
        class="flex w-full cursor-pointer items-center gap-2 rounded-md p-2 text-sm text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
        @click="closeMenu"
      >
        <span class="i-lucide-user size-4 shrink-0" />
        <span>{{ t('SIDEBAR_ITEMS.PROFILE_SETTING') }}</span>
      </router-link>

      <router-link
        :to="{ name: 'billing_settings_index' }"
        class="flex w-full cursor-pointer items-center gap-2 rounded-md p-2 text-sm text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
        @click="closeMenu"
      >
        <span class="i-lucide-credit-card size-4 shrink-0" />
        <span>{{ t('SIDEBAR_ITEMS.BILLING') }}</span>
      </router-link>

      <button
        type="button"
        class="flex w-full cursor-pointer items-center gap-2 rounded-md p-2 text-left text-sm text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
        @click="
          closeMenu();
          emit('openKeyShortcutModal');
        "
      >
        <span class="i-lucide-keyboard size-4 shrink-0" />
        <span>{{ t('SIDEBAR_ITEMS.KEYBOARD_SHORTCUTS') }}</span>
      </button>
    </div>
  </div>
</template>
