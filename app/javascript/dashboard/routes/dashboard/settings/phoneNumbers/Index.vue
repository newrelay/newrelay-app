<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';

import BuyPhoneNumberModal from './component/BuyPhoneNumberModal.vue';
import SettingsLayout from '../SettingsLayout.vue';
import SettingsListCard from '../components/SettingsListCard.vue';
import SettingsListRow from '../components/SettingsListRow.vue';
import { RelayButton, RelayBadge } from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const REFRESH_MS = 15000;
const showBuyModal = ref(false);
const resumeOrder = ref(null);
const connectingId = ref(null);
let refreshTimer = null;

const accountId = computed(() => getters.getCurrentAccountId.value);
const phoneNumbersEnabled = computed(() =>
  getters['accounts/isFeatureEnabledonAccount'].value(
    accountId.value,
    'phone_numbers'
  )
);
const records = computed(() => getters['phoneNumberOrders/getOrders'].value);
const uiFlags = computed(() => getters['phoneNumberOrders/getUIFlags'].value);
const inboxes = computed(() => getters['inboxes/getInboxes'].value || []);

// Badge color only. Whether a row is finished comes from the API `unfinished` flag.
const STATUS_BADGE_VARIANT = {
  active: 'default',
  failed: 'destructive',
  billing_failed: 'destructive',
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
  resumeOrder.value = null;
  showBuyModal.value = true;
}

function openDocuments(order) {
  resumeOrder.value = order;
  showBuyModal.value = true;
}

function closeBuyModal() {
  showBuyModal.value = false;
  resumeOrder.value = null;
}

function voiceAgent(order) {
  return order.voice_agent;
}

function showConnect(order) {
  return order.status === 'active' && voiceAgent(order)?.status !== 'saved';
}

const CONNECTABLE_KINDS = ['sms', 'voice', 'whatsapp'];
const SMS_CHANNEL_TYPES = new Set([
  'Channel::Sms',
  'Channel::ExotelSms',
  'Channel::TelnyxSms',
  'Channel::TwilioSms',
]);

function inboxesForOrder(order) {
  const byId = new Map();
  if (order.inbox) byId.set(order.inbox.id, order.inbox);
  inboxes.value.forEach(inbox => {
    const sameId = order.inbox && inbox.id === order.inbox.id;
    const sameNumber =
      inbox.phone_number && inbox.phone_number === order.phone_number;
    if (sameId || sameNumber) {
      byId.set(inbox.id, { ...byId.get(inbox.id), ...inbox });
    }
  });
  return [...byId.values()];
}

function kindsForInbox(inbox) {
  const type = inbox.channel_type || inbox.channelType;
  const kinds = new Set();
  if (type === 'Channel::Whatsapp' || inbox.medium === 'whatsapp') {
    kinds.add('whatsapp');
  } else if (SMS_CHANNEL_TYPES.has(type)) {
    kinds.add('sms');
  }
  if (inbox.voice_enabled || inbox.voiceEnabled) kinds.add('voice');
  return kinds;
}

function connectedKinds(order) {
  const kinds = new Set();
  inboxesForOrder(order).forEach(inbox => {
    kindsForInbox(inbox).forEach(kind => kinds.add(kind));
  });
  return CONNECTABLE_KINDS.filter(kind => kinds.has(kind));
}

function possibleKinds(order) {
  const connected = new Set(connectedKinds(order));
  return CONNECTABLE_KINDS.filter(kind => !connected.has(kind));
}

function kindLabels(kinds) {
  return kinds
    .map(kind => t(`PHONE_NUMBERS_MGMT.LIST.KINDS.${kind}`))
    .join(', ');
}

function voiceError(order) {
  const code = voiceAgent(order)?.failure_code;
  if (!code) return '';
  return t(`PHONE_NUMBERS_MGMT.LIST.ERRORS.${code}`);
}

async function connectVoiceAgent(order) {
  connectingId.value = order.id;
  try {
    await store.dispatch('phoneNumberOrders/connectVoiceAgent', order.id);
  } catch {
    await store.dispatch('phoneNumberOrders/get', { silent: true });
  } finally {
    connectingId.value = null;
  }
}

function hasUnfinished() {
  return records.value.some(order => order.unfinished);
}

function clearRefresh() {
  clearTimeout(refreshTimer);
  refreshTimer = null;
}

function scheduleRefresh() {
  clearRefresh();
  if (document.hidden || !hasUnfinished()) return;
  refreshTimer = setTimeout(async () => {
    await store.dispatch('phoneNumberOrders/get', { silent: true });
    scheduleRefresh();
  }, REFRESH_MS);
}

function onVisibilityChange() {
  if (document.hidden) clearRefresh();
  else scheduleRefresh();
}

async function loadOrders() {
  if (!phoneNumbersEnabled.value) return;
  await Promise.all([
    store.dispatch('phoneNumberOrders/get'),
    store.dispatch('inboxes/get'),
  ]);
  scheduleRefresh();
}

onMounted(() => {
  loadOrders();
  document.addEventListener('visibilitychange', onVisibilityChange);
});

watch(phoneNumbersEnabled, enabled => {
  if (enabled) loadOrders();
});

onBeforeUnmount(() => {
  clearRefresh();
  document.removeEventListener('visibilitychange', onVisibilityChange);
});

watch(records, () => {
  if (!hasUnfinished()) clearRefresh();
  else if (!refreshTimer) scheduleRefresh();
});
</script>

<template>
  <SettingsLayout
    class="min-h-0 overflow-y-auto p-4 sm:p-6"
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('PHONE_NUMBERS_MGMT.LOADING')"
    :no-records-found="false"
  >
    <template #body>
      <p v-if="!phoneNumbersEnabled" class="text-sm text-muted-foreground">
        {{ $t('PHONE_NUMBERS_MGMT.ACCOUNT_OFF') }}
      </p>
      <SettingsListCard
        v-else
        :details-label="$t('PHONE_NUMBERS_MGMT.LIST.DETAILS')"
        :show-column-headers="!!records.length"
      >
        <template #toolbar>
          <div>
            <h3 class="text-base font-medium text-foreground">
              {{ $t('PHONE_NUMBERS_MGMT.HEADER') }}
              <span
                v-if="records.length"
                class="ml-1.5 text-sm font-normal text-muted-foreground"
              >
                {{ $t('PHONE_NUMBERS_MGMT.COUNT', { n: records.length }) }}
              </span>
            </h3>
            <p class="mt-1 text-sm text-muted-foreground">
              {{ $t('PHONE_NUMBERS_MGMT.DESCRIPTION') }}
            </p>
          </div>
          <RelayButton
            class="h-9 w-full whitespace-nowrap shadow-sm sm:w-auto"
            @click="openBuyModal"
          >
            {{ $t('PHONE_NUMBERS_MGMT.HEADER_BTN_TXT') }}
          </RelayButton>
        </template>
        <template v-if="!records.length" #empty>
          <div
            class="flex flex-col items-center justify-center bg-muted/10 px-6 py-4"
          >
            <div
              class="mb-5 flex size-16 items-center justify-center rounded-full border border-border bg-muted/50"
            >
              <Icon
                icon="i-lucide-phone"
                class="size-6 text-muted-foreground/70"
              />
            </div>
            <h3 class="mb-1.5 text-[20px] font-[600] text-foreground">
              {{ $t('PHONE_NUMBERS_MGMT.LIST.EMPTY_TITLE') }}
            </h3>
            <p
              class="mb-6 max-w-sm text-center text-[13.5px] leading-relaxed text-muted-foreground"
            >
              {{ $t('PHONE_NUMBERS_MGMT.LIST.EMPTY_DESC') }}
            </p>
            <RelayButton class="h-9 shadow-sm" @click="openBuyModal">
              <Icon icon="i-lucide-plus" class="size-4" />
              {{ $t('PHONE_NUMBERS_MGMT.HEADER_BTN_TXT') }}
            </RelayButton>
          </div>
        </template>
        <SettingsListRow v-for="order in records" :key="order.id">
          <template #leading>
            <div
              class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary/10"
            >
              <Icon icon="i-lucide-phone" class="size-4 text-primary" />
            </div>
          </template>
          <div class="flex items-center gap-2">
            <span class="text-sm font-medium text-foreground">
              {{ order.phone_number || '—' }}
            </span>
            <RelayBadge :variant="statusVariant(order.status)">
              {{ statusLabel(order.status) }}
            </RelayBadge>
            <RelayButton
              v-if="order.status === 'requirements_pending'"
              variant="outline"
              class="h-8 border border-border px-3 text-[13px] font-normal"
              @click="openDocuments(order)"
            >
              {{ $t('PHONE_NUMBERS_MGMT.LIST.UPLOAD_DOCUMENTS') }}
            </RelayButton>
            <RelayButton
              v-if="showConnect(order)"
              variant="outline"
              class="h-8 border border-border px-3 text-[13px] font-normal"
              :disabled="connectingId === order.id"
              @click="connectVoiceAgent(order)"
            >
              {{ $t('PHONE_NUMBERS_MGMT.LIST.CONNECT') }}
            </RelayButton>
          </div>
          <p
            v-if="voiceAgent(order)?.status === 'saved'"
            class="mt-1 text-[13px] text-muted-foreground"
          >
            {{
              voiceAgent(order).twilio_connected
                ? $t('PHONE_NUMBERS_MGMT.LIST.TWILIO_CONNECTED')
                : $t('PHONE_NUMBERS_MGMT.LIST.SAVED')
            }}
          </p>
          <p
            v-else-if="voiceError(order)"
            class="mt-1 text-[13px] text-destructive"
          >
            {{ voiceError(order) }}
          </p>
          <p class="mt-1 text-[13px] text-muted-foreground">
            <span class="font-medium text-foreground">
              {{ $t('PHONE_NUMBERS_MGMT.LIST.CONNECTED_INBOXES') }}:
            </span>
            {{
              kindLabels(connectedKinds(order)) ||
              $t('PHONE_NUMBERS_MGMT.LIST.NO_CONNECTED_INBOX')
            }}
          </p>
          <p class="mt-1 text-[13px] text-muted-foreground">
            <span class="font-medium text-foreground">
              {{ $t('PHONE_NUMBERS_MGMT.LIST.POSSIBLE_INBOXES') }}:
            </span>
            {{
              kindLabels(possibleKinds(order)) ||
              $t('PHONE_NUMBERS_MGMT.LIST.NO_POSSIBLE_INBOX')
            }}
          </p>
          <div
            class="mt-1 flex flex-wrap items-center gap-3.5 text-[13px] text-muted-foreground"
          >
            <span>{{ order.country_code }}</span>
            <div class="size-1 rounded-full bg-muted-foreground/40" />
            <span class="capitalize">{{ order.provider_type }}</span>
            <div class="size-1 rounded-full bg-muted-foreground/40" />
            <span>
              {{
                $t('PHONE_NUMBERS_MGMT.LIST.PURCHASED_ON', {
                  date: formatDate(order.created_at),
                })
              }}
            </span>
          </div>
          <p
            v-if="order.failure_message"
            class="mt-1 text-[13px] text-muted-foreground"
          >
            {{ order.failure_message }}
          </p>
        </SettingsListRow>
      </SettingsListCard>
    </template>

    <BuyPhoneNumberModal
      :show="showBuyModal"
      :resume-order="resumeOrder"
      @close="closeBuyModal"
    />
  </SettingsLayout>
</template>
