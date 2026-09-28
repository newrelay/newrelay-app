<script setup>
import { computed, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import {
  RelayButton,
  RelayBadge,
  RelayModal,
} from 'dashboard/components-next/relay';
import ChannelSelector from 'dashboard/components/ChannelSelector.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close']);

const STEPS = {
  COUNTRY: 'country',
  RESULTS: 'results',
  CONFIRM: 'confirm',
};

const { t } = useI18n();
const store = useStore();

const uiFlags = useMapGetter('phoneNumberOrders/getUIFlags');

const state = reactive({
  step: STEPS.COUNTRY,
  countryCode: '',
  numbers: [],
  selectedNumber: null,
  orderIdempotencyKey: null,
});

// Provider is derived from country on the backend (NumberProvisioning.for) --
// this UI only ever exposes a country choice, never a provider choice.
const countries = computed(() => [
  {
    code: 'US',
    title: t('PHONE_NUMBERS_MGMT.BUY_MODAL.SELECT_COUNTRY.US'),
    description: t('PHONE_NUMBERS_MGMT.BUY_MODAL.SELECT_COUNTRY.US_DESC'),
  },
  {
    code: 'IN',
    title: t('PHONE_NUMBERS_MGMT.BUY_MODAL.SELECT_COUNTRY.IN'),
    description: t('PHONE_NUMBERS_MGMT.BUY_MODAL.SELECT_COUNTRY.IN_DESC'),
  },
]);

const stepTitle = computed(() => {
  if (state.step === STEPS.RESULTS) {
    return t('PHONE_NUMBERS_MGMT.BUY_MODAL.RESULTS.TITLE');
  }
  if (state.step === STEPS.CONFIRM) {
    return t('PHONE_NUMBERS_MGMT.BUY_MODAL.CONFIRM.TITLE');
  }
  return t('PHONE_NUMBERS_MGMT.BUY_MODAL.TITLE');
});

// The raw search-result shape is not normalized across providers yet
// (Telnyx and Exotel return different fields for the same concepts) --
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
// (Telnyx: cost_information.monthly_cost, Exotel: rental_price -- unconfirmed).
function getPrice(result) {
  return (
    result?.monthly_price ??
    result?.rental_price ??
    result?.cost_information?.monthly_cost ??
    null
  );
}

function resetState() {
  state.step = STEPS.COUNTRY;
  state.countryCode = '';
  state.numbers = [];
  state.selectedNumber = null;
  state.orderIdempotencyKey = null;
}

async function selectCountry(countryCode) {
  state.countryCode = countryCode;
  state.step = STEPS.RESULTS;
  try {
    const type = countryCode === 'IN' ? 'Mobile' : undefined;
    const results = await store.dispatch('phoneNumberOrders/search', {
      countryCode,
      type,
    });
    // Exotel's raw search response isn't confirmed to be a top-level array
    // (see NumberProvisioning::ExotelProvider#search) -- guard against that.
    state.numbers = Array.isArray(results) ? results : [];
  } catch (error) {
    useAlert(
      error.response?.data?.message ||
        error.response?.data?.error ||
        t('PHONE_NUMBERS_MGMT.BUY_MODAL.API.SEARCH_ERROR')
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
  // Generated once per selection, not per click, so a retry after a failed
  // confirm (e.g. network blip) replays the same attempt instead of risking
  // a duplicate order if the first request actually landed server-side.
  state.orderIdempotencyKey = crypto.randomUUID();
}

function backToResults() {
  state.step = STEPS.RESULTS;
  state.selectedNumber = null;
}

async function confirmOrder() {
  try {
    // Api::V1::Accounts::NumberProvisioning::OrdersController#order_params
    // permits `order: { country_code, phone_number }` only -- no `type`.
    await store.dispatch('phoneNumberOrders/create', {
      idempotencyKey: state.orderIdempotencyKey,
      order: {
        country_code: state.countryCode,
        phone_number: getPhoneNumber(state.selectedNumber),
      },
    });
    useAlert(t('PHONE_NUMBERS_MGMT.BUY_MODAL.API.ORDER_SUCCESS'));
    emit('close');
  } catch (error) {
    useAlert(
      error.response?.data?.message ||
        error.response?.data?.error ||
        t('PHONE_NUMBERS_MGMT.BUY_MODAL.API.ORDER_ERROR')
    );
  }
}

// Reset to the first step each time the modal is reopened, rather than on
// close, so the closing animation (if any) doesn't show the state resetting.
watch(
  () => props.show,
  show => {
    if (show) resetState();
  }
);
</script>

<template>
  <RelayModal
    :show="show"
    :title="stepTitle"
    :description="t('PHONE_NUMBERS_MGMT.BUY_MODAL.DESCRIPTION')"
    size="lg"
    @close="emit('close')"
  >
    <div v-if="state.step === STEPS.COUNTRY" class="flex flex-col gap-3 p-5">
      <ChannelSelector
        v-for="country in countries"
        :key="country.code"
        :title="country.title"
        :description="country.description"
        icon="i-lucide-map-pin"
        @click="selectCountry(country.code)"
      />
    </div>

    <div v-else-if="state.step === STEPS.RESULTS" class="p-5">
      <div class="mb-4 flex items-center justify-between">
        <RelayButton variant="ghost" size="sm" @click="backToCountry">
          {{ t('PHONE_NUMBERS_MGMT.BUY_MODAL.RESULTS.BACK_BUTTON') }}
        </RelayButton>
      </div>

      <p
        v-if="uiFlags.isSearchingNumbers"
        class="text-[13.5px] text-muted-foreground"
      >
        {{ t('PHONE_NUMBERS_MGMT.BUY_MODAL.RESULTS.LOADING') }}
      </p>

      <p
        v-else-if="!state.numbers.length"
        class="text-[13.5px] text-muted-foreground"
      >
        {{ t('PHONE_NUMBERS_MGMT.BUY_MODAL.RESULTS.EMPTY') }}
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
                t('PHONE_NUMBERS_MGMT.BUY_MODAL.RESULTS.PRICE_UNKNOWN')
              }}
            </span>
          </span>
        </RelayButton>
      </div>
    </div>

    <div v-else-if="state.step === STEPS.CONFIRM" class="p-5">
      <p class="mb-4 text-[13.5px] leading-relaxed text-muted-foreground">
        {{ t('PHONE_NUMBERS_MGMT.BUY_MODAL.CONFIRM.DESCRIPTION') }}
      </p>
      <p class="mb-6 text-[16px] font-semibold text-foreground">
        {{ getPhoneNumber(state.selectedNumber) }}
      </p>
      <div class="flex gap-3">
        <RelayButton :disabled="uiFlags.isCreating" @click="confirmOrder">
          {{ t('PHONE_NUMBERS_MGMT.BUY_MODAL.CONFIRM.CONFIRM_BUTTON') }}
        </RelayButton>
        <RelayButton variant="outline" @click="backToResults">
          {{ t('PHONE_NUMBERS_MGMT.BUY_MODAL.CONFIRM.BACK_BUTTON') }}
        </RelayButton>
      </div>
    </div>
  </RelayModal>
</template>
