<script setup>
import { reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import PageHeader from '../../SettingsSubPageHeader.vue';
import { RelayButton, RelayBadge } from 'dashboard/components-next/relay';
import ChannelSelector from 'dashboard/components/ChannelSelector.vue';

const STEPS = {
  COUNTRY: 'country',
  RESULTS: 'results',
  CONFIRM: 'confirm',
  PROVISIONING: 'provisioning',
};

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const uiFlags = useMapGetter('inboxes/getUIFlags');
const allInboxes = useMapGetter('inboxes/getInboxes');

const state = reactive({
  step: STEPS.COUNTRY,
  countryCode: '',
  numbers: [],
  selectedNumber: null,
  order: null,
});

// Provider is derived from country on the backend (NumberProvisioning.for) —
// this UI only ever exposes a country choice, never a provider choice.
const countries = computed(() => [
  {
    code: 'US',
    title: t('INBOX_MGMT.ADD.PHONE_NUMBER.COUNTRIES.US'),
    description: t('INBOX_MGMT.ADD.PHONE_NUMBER.COUNTRIES.US_DESC'),
  },
  {
    code: 'IN',
    title: t('INBOX_MGMT.ADD.PHONE_NUMBER.COUNTRIES.IN'),
    description: t('INBOX_MGMT.ADD.PHONE_NUMBER.COUNTRIES.IN_DESC'),
  },
]);

// The raw search-result shape is not normalized across providers yet
// (Telnyx and Exotel return different fields for the same concepts) —
// these helpers read every shape seen in the adapters instead of assuming one.
function getPhoneNumber(result) {
  return result?.phone_number || result?.PhoneNumber || '';
}

function getCapabilities(result) {
  const capabilities =
    result?.capabilities || result?.features || result?.Capabilities || [];
  return capabilities
    .map(capability =>
      typeof capability === 'string' ? capability : capability?.name
    )
    .filter(Boolean);
}

// TODO: confirm exact price field once the backend normalizes search results
// (Telnyx: cost_information.monthly_cost, Exotel: rental_price — unconfirmed).
function getPrice(result) {
  return (
    result?.monthly_price ??
    result?.rental_price ??
    result?.cost_information?.monthly_cost ??
    null
  );
}

async function selectCountry(countryCode) {
  state.countryCode = countryCode;
  state.step = STEPS.RESULTS;
  try {
    const type = countryCode === 'IN' ? 'Mobile' : undefined;
    const results = await store.dispatch(
      'inboxes/searchNumberProvisioningNumbers',
      { countryCode, type }
    );
    // Exotel's raw search response isn't confirmed to be a top-level array
    // (see NumberProvisioning::ExotelProvider#search) — guard against that.
    state.numbers = Array.isArray(results) ? results : [];
  } catch (error) {
    useAlert(
      error.response?.data?.message ||
        t('INBOX_MGMT.ADD.PHONE_NUMBER.API.SEARCH_ERROR')
    );
    state.step = STEPS.COUNTRY;
  }
}

function backToCountry() {
  state.step = STEPS.COUNTRY;
  state.numbers = [];
  state.countryCode = '';
}

function selectNumber(result) {
  state.selectedNumber = result;
  state.step = STEPS.CONFIRM;
}

function backToResults() {
  state.step = STEPS.RESULTS;
  state.selectedNumber = null;
}

async function confirmOrder() {
  try {
    // Api::V1::Accounts::NumberProvisioning::OrdersController#order_params
    // permits `order: { country_code, phone_number }` only — no `type`.
    state.order = await store.dispatch(
      'inboxes/createNumberProvisioningOrder',
      {
        order: {
          country_code: state.countryCode,
          phone_number: getPhoneNumber(state.selectedNumber),
        },
      }
    );
    state.step = STEPS.PROVISIONING;
  } catch (error) {
    useAlert(
      error.response?.data?.message ||
        t('INBOX_MGMT.ADD.PHONE_NUMBER.API.ORDER_ERROR')
    );
  }
}

// No order-status endpoint is confirmed to exist yet, so this refetches the
// inbox list instead of polling a status route that may not exist — once the
// order goes active, a matching inbox will show up here.
async function checkStatus() {
  await store.dispatch('inboxes/get');
  const inbox = allInboxes.value.find(
    record => record.phone_number === getPhoneNumber(state.selectedNumber)
  );
  if (inbox) {
    router.replace({
      name: 'settings_inboxes_add_agents',
      params: { page: 'new', inbox_id: inbox.id },
    });
  } else {
    useAlert(t('INBOX_MGMT.ADD.PHONE_NUMBER.PROVISIONING.STILL_PROCESSING'));
  }
}
</script>

<template>
  <div class="w-full max-w-2xl">
    <PageHeader
      :header-title="t('INBOX_MGMT.ADD.PHONE_NUMBER.TITLE')"
      :header-content="t('INBOX_MGMT.ADD.PHONE_NUMBER.DESC')"
    />

    <div v-if="state.step === STEPS.COUNTRY">
      <div class="mb-8 border-b border-border/40 pb-4 text-left">
        <h3 class="capitalize mb-1 text-base font-medium text-foreground">
          {{ t('INBOX_MGMT.ADD.PHONE_NUMBER.SELECT_COUNTRY.TITLE') }}
        </h3>
        <p class="text-[14px] leading-relaxed text-muted-foreground">
          {{ t('INBOX_MGMT.ADD.PHONE_NUMBER.SELECT_COUNTRY.DESCRIPTION') }}
        </p>
      </div>

      <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
        <ChannelSelector
          v-for="country in countries"
          :key="country.code"
          :title="country.title"
          :description="country.description"
          icon="i-lucide-map-pin"
          @click="selectCountry(country.code)"
        />
      </div>
    </div>

    <div v-else-if="state.step === STEPS.RESULTS">
      <div class="mb-6 flex items-center justify-between">
        <h3 class="text-base font-medium text-foreground">
          {{ t('INBOX_MGMT.ADD.PHONE_NUMBER.RESULTS.TITLE') }}
        </h3>
        <RelayButton variant="ghost" size="sm" @click="backToCountry">
          {{ t('INBOX_MGMT.ADD.PHONE_NUMBER.RESULTS.BACK_BUTTON') }}
        </RelayButton>
      </div>

      <p
        v-if="uiFlags.isSearchingNumbers"
        class="text-[13.5px] text-muted-foreground"
      >
        {{ t('INBOX_MGMT.ADD.PHONE_NUMBER.RESULTS.LOADING') }}
      </p>

      <p
        v-else-if="!state.numbers.length"
        class="text-[13.5px] text-muted-foreground"
      >
        {{ t('INBOX_MGMT.ADD.PHONE_NUMBER.RESULTS.EMPTY') }}
      </p>

      <div v-else class="flex flex-col gap-3">
        <RelayButton
          v-for="result in state.numbers"
          :key="getPhoneNumber(result)"
          variant="outline"
          class="h-auto w-full justify-between gap-4 px-4 py-3"
          @click="selectNumber(result)"
        >
          <span class="text-[14px] font-medium text-foreground">
            {{ getPhoneNumber(result) }}
          </span>
          <span class="flex items-center gap-2">
            <RelayBadge
              v-for="capability in getCapabilities(result)"
              :key="capability"
              variant="secondary"
            >
              {{ capability }}
            </RelayBadge>
            <span class="text-[13px] text-muted-foreground">
              {{
                getPrice(result) ??
                t('INBOX_MGMT.ADD.PHONE_NUMBER.RESULTS.PRICE_UNKNOWN')
              }}
            </span>
          </span>
        </RelayButton>
      </div>
    </div>

    <div v-else-if="state.step === STEPS.CONFIRM">
      <div class="rounded-xl border border-border bg-card p-6 shadow-sm">
        <h3 class="mb-1 text-base font-medium text-foreground">
          {{ t('INBOX_MGMT.ADD.PHONE_NUMBER.CONFIRM.TITLE') }}
        </h3>
        <p class="mb-4 text-[13.5px] leading-relaxed text-muted-foreground">
          {{ t('INBOX_MGMT.ADD.PHONE_NUMBER.CONFIRM.DESCRIPTION') }}
        </p>
        <p class="mb-6 text-[16px] font-semibold text-foreground">
          {{ getPhoneNumber(state.selectedNumber) }}
        </p>
        <div class="flex gap-3">
          <RelayButton :disabled="uiFlags.isCreating" @click="confirmOrder">
            {{ t('INBOX_MGMT.ADD.PHONE_NUMBER.CONFIRM.CONFIRM_BUTTON') }}
          </RelayButton>
          <RelayButton variant="outline" @click="backToResults">
            {{ t('INBOX_MGMT.ADD.PHONE_NUMBER.CONFIRM.BACK_BUTTON') }}
          </RelayButton>
        </div>
      </div>
    </div>

    <div v-else-if="state.step === STEPS.PROVISIONING">
      <div class="rounded-xl border border-border bg-card p-6 shadow-sm">
        <h3 class="mb-1 text-base font-medium text-foreground">
          {{ t('INBOX_MGMT.ADD.PHONE_NUMBER.PROVISIONING.TITLE') }}
        </h3>
        <p class="mb-6 text-[13.5px] leading-relaxed text-muted-foreground">
          {{
            t('INBOX_MGMT.ADD.PHONE_NUMBER.PROVISIONING.DESCRIPTION', {
              phoneNumber: getPhoneNumber(state.selectedNumber),
            })
          }}
        </p>
        <RelayButton @click="checkStatus">
          {{
            t('INBOX_MGMT.ADD.PHONE_NUMBER.PROVISIONING.CHECK_STATUS_BUTTON')
          }}
        </RelayButton>
      </div>
    </div>
  </div>
</template>
