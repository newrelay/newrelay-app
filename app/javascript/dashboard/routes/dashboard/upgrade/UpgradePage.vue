<script setup>
import { onMounted, computed, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useConfig } from 'dashboard/composables/useConfig';
import { differenceInDays } from 'date-fns';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useI18n } from 'vue-i18n';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  bypassUpgradePage: {
    type: Boolean,
    default: false,
  },
});

const router = useRouter();
const store = useStore();
const { t } = useI18n();
const { accountId, currentAccount } = useAccount();
const { isEnterprise } = useConfig();
const { isAdmin } = useAdmin();

const isOnChatwootCloud = useMapGetter('globalConfig/isOnChatwootCloud');

// The backend reports this fixed number as the "allowed" value for resources
// that are actually unlimited on a plan (see ChatwootApp.max_limit), rather
// than a real cap - so it must never be treated as an enforceable limit.
const UNLIMITED_SENTINEL = 100000;

const testLimit = limit => {
  if (!limit) return false;
  const { allowed, consumed } = limit;
  if (allowed == null || allowed >= UNLIMITED_SENTINEL) return false;
  return consumed > allowed;
};

// Resource keys (from the /limits endpoint) checked in order of how
// "blocking" they typically are for a workspace.
const LIMIT_KEYS = [
  'conversation',
  'non_web_inboxes',
  'agents',
  'contacts',
  'automations',
  't3_subaccounts',
];

const isTrialAccount = computed(() => {
  // check if account is less than 15 days old
  const account = currentAccount.value;
  if (!account) return false;

  const createdAt = new Date(account.created_at);
  const diffDays = differenceInDays(new Date(), createdAt);

  return diffDays <= 15;
});

const exceededLimitKey = computed(() => {
  const limits = currentAccount.value?.limits;
  if (!limits) return null;

  return LIMIT_KEYS.find(key => testLimit(limits[key])) || null;
});

const isLimitExceeded = computed(() => !!exceededLimitKey.value);

// Before the account's full details load (e.g. right after login), the store
// getter returns a placeholder `{}` rather than null/undefined - checking
// `!account` alone doesn't catch that. Gate on `account.id` instead, which is
// only ever present once the real account has loaded, to avoid a false
// "no plan" flash that redirects an already-subscribed admin to billing.
const isAccountLoaded = computed(() => !!currentAccount.value?.id);

const hasNoPlan = computed(() => {
  if (!isEnterprise) return false;
  if (!isAccountLoaded.value) return false;
  return !currentAccount.value.custom_attributes?.plan_name;
});

const isSubscriptionInactive = computed(() => {
  if (!isEnterprise) return false;
  if (!isAccountLoaded.value) return false;

  // If there's no subscription record, or it is not active, block access!
  const account = currentAccount.value;
  return !account.subscription || account.subscription.active === false;
});

const shouldShowUpgradePage = computed(() => {
  // Skip upgrade page in Billing, Inbox, and Agent pages
  if (props.bypassUpgradePage) return false;
  if (hasNoPlan.value) return true;
  if (isSubscriptionInactive.value) return true;

  if (!isOnChatwootCloud.value) return false;
  if (isTrialAccount.value) return false;
  return isLimitExceeded.value;
});

const limitExceededMessage = computed(() => {
  if (hasNoPlan.value) {
    return t('GENERAL_SETTINGS.LIMIT_MESSAGES.NO_PLAN');
  }

  if (isSubscriptionInactive.value) {
    return t('GENERAL_SETTINGS.LIMIT_MESSAGES.SUBSCRIPTION_INACTIVE');
  }

  const limits = currentAccount.value?.limits || {};
  switch (exceededLimitKey.value) {
    case 'conversation':
      return t('GENERAL_SETTINGS.LIMIT_MESSAGES.CONVERSATION');
    case 'non_web_inboxes':
      return t('GENERAL_SETTINGS.LIMIT_MESSAGES.INBOXES');
    case 'agents':
      return t('GENERAL_SETTINGS.LIMIT_MESSAGES.AGENTS', {
        allowedAgents: limits.agents.allowed,
      });
    case 'contacts':
      return t('GENERAL_SETTINGS.LIMIT_MESSAGES.CONTACTS');
    case 'automations':
      return t('GENERAL_SETTINGS.LIMIT_MESSAGES.AUTOMATIONS');
    case 't3_subaccounts':
      return t('GENERAL_SETTINGS.LIMIT_MESSAGES.T3_SUBACCOUNTS');
    default:
      return '';
  }
});

const fetchLimits = () => {
  store.dispatch('accounts/limits');
};

const routeToBilling = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};

// When an admin has no plan (or an inactive subscription), send them straight
// to billing to pick a plan instead of showing a blocked dashboard. Gated on
// Chatwoot Cloud since the billing page bounces back to home off-cloud.
const shouldRedirectToBilling = computed(() => {
  if (props.bypassUpgradePage) return false;
  if (!isAdmin.value) return false;
  if (!isOnChatwootCloud.value) return false;
  return hasNoPlan.value || isSubscriptionInactive.value;
});

watch(
  shouldRedirectToBilling,
  value => {
    if (!value) return;
    router.replace({
      name: 'billing_settings_index',
      params: { accountId: accountId.value },
    });
  },
  { immediate: true }
);

onMounted(() => {
  if (isEnterprise) {
    fetchLimits();
  }
});

defineExpose({ shouldShowUpgradePage });
</script>

<template>
  <div
    v-if="shouldShowUpgradePage"
    class="mx-auto h-full pt-[clamp(3rem,15vh,12rem)]"
  >
    <div
      class="flex flex-col gap-4 max-w-md px-8 py-6 shadow-lg bg-n-solid-1 rounded-xl outline outline-1 outline-n-container"
    >
      <div class="flex flex-col gap-4">
        <div class="flex items-center w-full gap-2">
          <span
            class="flex items-center justify-center w-6 h-6 rounded-full bg-n-solid-blue"
          >
            <Icon
              class="flex-shrink-0 text-n-brand size-[14px]"
              icon="i-lucide-lock-keyhole"
            />
          </span>
          <span class="text-base font-medium text-n-slate-12">
            {{ $t('GENERAL_SETTINGS.UPGRADE') }}
          </span>
        </div>
        <div>
          <p class="text-sm font-normal text-n-slate-11 mb-3">
            {{ limitExceededMessage }}
          </p>
          <p v-if="!isAdmin">
            {{ t('GENERAL_SETTINGS.LIMIT_MESSAGES.NON_ADMIN') }}
          </p>
        </div>
      </div>
      <NextButton
        v-if="isAdmin"
        :label="$t('GENERAL_SETTINGS.OPEN_BILLING')"
        icon="i-lucide-credit-card"
        @click="routeToBilling()"
      />
    </div>
    <slot />
  </div>
  <div v-else />
</template>
