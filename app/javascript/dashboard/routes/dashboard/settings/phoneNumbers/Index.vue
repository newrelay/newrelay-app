<script setup>
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';

import BuyPhoneNumberModal from './component/BuyPhoneNumberModal.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { RelayButton, RelayBadge } from 'dashboard/components-next/relay';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const showBuyModal = ref(false);

const records = computed(() => getters['phoneNumberOrders/getOrders'].value);
const uiFlags = computed(() => getters['phoneNumberOrders/getUIFlags'].value);

// Statuses that never actually get set by the backend today (search_pending,
// requirements_* mid-flow, cancelled) still render if they somehow appear --
// this just controls the badge color, not which statuses are reachable.
const STATUS_BADGE_VARIANT = {
  active: 'default',
  failed: 'destructive',
  requirements_rejected: 'destructive',
};

function statusVariant(status) {
  return STATUS_BADGE_VARIANT[status] || 'secondary';
}

function statusLabel(status) {
  const key = `PHONE_NUMBERS_MGMT.LIST.STATUS.${status.toUpperCase()}`;
  const translated = t(key);
  return translated === key ? status : translated;
}

function formatDate(timestampSeconds) {
  return new Date(timestampSeconds * 1000).toLocaleDateString();
}

function openBuyModal() {
  showBuyModal.value = true;
}

function closeBuyModal() {
  showBuyModal.value = false;
}

onBeforeMount(() => {
  store.dispatch('phoneNumberOrders/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('PHONE_NUMBERS_MGMT.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="$t('PHONE_NUMBERS_MGMT.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('PHONE_NUMBERS_MGMT.HEADER')"
        :description="$t('PHONE_NUMBERS_MGMT.DESCRIPTION')"
      >
        <template v-if="records?.length" #count>
          <span class="text-sm text-muted-foreground">
            {{ $t('PHONE_NUMBERS_MGMT.COUNT', { n: records.length }) }}
          </span>
        </template>
        <template #actions>
          <RelayButton size="sm" @click="openBuyModal">
            {{ $t('PHONE_NUMBERS_MGMT.HEADER_BTN_TXT') }}
          </RelayButton>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div
        class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
      >
        <div class="overflow-x-auto">
          <table class="w-full border-collapse text-left">
            <thead>
              <tr class="border-b border-border/50 bg-muted/20">
                <th
                  class="px-6 py-3.5 text-[14px] font-semibold text-muted-foreground"
                >
                  {{ $t('PHONE_NUMBERS_MGMT.LIST.TABLE_HEADER.PHONE_NUMBER') }}
                </th>
                <th
                  class="w-32 px-6 py-3.5 text-[14px] font-semibold text-muted-foreground"
                >
                  {{ $t('PHONE_NUMBERS_MGMT.LIST.TABLE_HEADER.COUNTRY') }}
                </th>
                <th
                  class="w-32 px-6 py-3.5 text-[14px] font-semibold text-muted-foreground"
                >
                  {{ $t('PHONE_NUMBERS_MGMT.LIST.TABLE_HEADER.PROVIDER') }}
                </th>
                <th
                  class="w-48 px-6 py-3.5 text-[14px] font-semibold text-muted-foreground"
                >
                  {{ $t('PHONE_NUMBERS_MGMT.LIST.TABLE_HEADER.STATUS') }}
                </th>
                <th
                  class="w-40 px-6 py-3.5 text-[14px] font-semibold text-muted-foreground"
                >
                  {{ $t('PHONE_NUMBERS_MGMT.LIST.TABLE_HEADER.PURCHASED') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-border/40">
              <tr
                v-for="order in records"
                :key="order.id"
                class="bg-card transition-colors hover:bg-accent"
              >
                <td class="px-6 py-4 text-[14px] font-medium text-foreground">
                  {{ order.phone_number || '—' }}
                </td>
                <td class="px-6 py-4 text-[13px] text-muted-foreground">
                  {{ order.country_code }}
                </td>
                <td
                  class="px-6 py-4 text-[13px] capitalize text-muted-foreground"
                >
                  {{ order.provider_type }}
                </td>
                <td class="px-6 py-4">
                  <RelayBadge :variant="statusVariant(order.status)">
                    {{ statusLabel(order.status) }}
                  </RelayBadge>
                </td>
                <td class="px-6 py-4 text-[13px] text-muted-foreground">
                  {{ formatDate(order.created_at) }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </template>

    <BuyPhoneNumberModal :show="showBuyModal" @close="closeBuyModal" />
  </SettingsLayout>
</template>
