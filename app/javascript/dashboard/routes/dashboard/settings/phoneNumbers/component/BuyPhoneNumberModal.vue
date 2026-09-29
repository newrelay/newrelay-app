<script setup>
import { computed, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import {
  RelayButton,
  RelayBadge,
  RelayInput,
  RelayModal,
  RELAY_MODAL_BODY_CLASS,
  RELAY_MODAL_FORM_FOOTER_CLASS,
} from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';
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
const providers = useMapGetter('phoneNumberOrders/getProviders');

const state = reactive({
  step: STEPS.COUNTRY,
  countryCode: '',
  numbers: [],
  searchQuery: '',
  selectedNumber: null,
  orderIdempotencyKey: null,
});

// Provider is derived from country on the backend (NumberProvisioning.for) --
// this UI only ever exposes a country choice, never a provider choice.
const countries = computed(() =>
  [
    {
      code: 'US',
      provider: 'telnyx',
      title: t('PHONE_NUMBERS_MGMT.BUY_MODAL.SELECT_COUNTRY.US'),
      description: t('PHONE_NUMBERS_MGMT.BUY_MODAL.SELECT_COUNTRY.US_DESC'),
    },
    {
      code: 'IN',
      provider: 'exotel',
      title: t('PHONE_NUMBERS_MGMT.BUY_MODAL.SELECT_COUNTRY.IN'),
      description: t('PHONE_NUMBERS_MGMT.BUY_MODAL.SELECT_COUNTRY.IN_DESC'),
    },
  ].filter(country => providers.value?.[country.provider])
);

const stepTitle = computed(() => {
  if (state.step === STEPS.RESULTS) {
    return t('PHONE_NUMBERS_MGMT.BUY_MODAL.RESULTS.TITLE');
  }
  if (state.step === STEPS.CONFIRM) {
    return t('PHONE_NUMBERS_MGMT.BUY_MODAL.CONFIRM.TITLE');
  }
  return t('PHONE_NUMBERS_MGMT.BUY_MODAL.TITLE');
});

// Both adapters return the normalized shape
// { phone_number, monthly_price_cents, currency, capabilities } from search().
function getPhoneNumber(result) {
  return result?.phone_number || '';
}

function getCapabilities(result) {
  return result?.capabilities || [];
}

// Monthly price, formatted in the result's currency. null when the provider
// didn't quote a price (rendered as PRICE_UNKNOWN).
function formatPrice(result) {
  const cents = result?.monthly_price_cents;
  if (cents == null) return null;
  const amount = cents / 100;
  const currency = result?.currency;
  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency,
    }).format(amount);
  } catch {
    return `${amount.toFixed(2)}${currency ? ` ${currency}` : ''}`;
  }
}

// Client-side filter over the already-fetched results, matched on digits so a
// query with or without spaces/+ still hits (e.g. "9198" matches "+91 98...").
const filteredNumbers = computed(() => {
  const query = state.searchQuery.replace(/\D/g, '');
  if (!query) return state.numbers;
  return state.numbers.filter(result =>
    getPhoneNumber(result).replace(/\D/g, '').includes(query)
  );
});

function resetState() {
  state.step = STEPS.COUNTRY;
  state.countryCode = '';
  state.numbers = [];
  state.searchQuery = '';
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
  state.searchQuery = '';
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
    store.dispatch('phoneNumberOrders/get', { silent: true });
  }
}

// Reset to the first step each time the modal is reopened, rather than on
// close, so the closing animation (if any) doesn't show the state resetting.
watch(
  () => props.show,
  show => {
    if (!show) return;
    resetState();
    store.dispatch('phoneNumberOrders/fetchConfig');
  }
);
</script>

<template>
  <RelayModal
    :show="show"
    :title="stepTitle"
    :description="t('PHONE_NUMBERS_MGMT.BUY_MODAL.DESCRIPTION')"
    size="lg"
    flush
    @close="emit('close')"
  >
    <div
      v-if="state.step === STEPS.COUNTRY"
      class="flex flex-col gap-3"
      :class="RELAY_MODAL_BODY_CLASS"
    >
      <p v-if="!countries.length" class="text-[13.5px] text-muted-foreground">
        {{ t('PHONE_NUMBERS_MGMT.BUY_MODAL.SELECT_COUNTRY.NONE') }}
      </p>
      <ChannelSelector
        v-for="country in countries"
        :key="country.code"
        :title="country.title"
        :description="country.description"
        icon="i-lucide-map-pin"
        @click="selectCountry(country.code)"
      />
    </div>

    <div
      v-else-if="state.step === STEPS.RESULTS"
      class="flex flex-col"
      :class="RELAY_MODAL_BODY_CLASS"
    >
      <div class="mb-4 flex flex-col gap-3">
        <RelayButton
          variant="ghost"
          size="sm"
          class="w-fit gap-1.5 px-2"
          @click="backToCountry"
        >
          <Icon icon="i-lucide-arrow-left" class="size-4" />
          {{ t('PHONE_NUMBERS_MGMT.BUY_MODAL.RESULTS.BACK_BUTTON') }}
        </RelayButton>

        <div v-if="state.numbers.length" class="relative">
          <Icon
            icon="i-lucide-search"
            class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
          />
          <RelayInput
            v-model="state.searchQuery"
            :placeholder="
              t('PHONE_NUMBERS_MGMT.BUY_MODAL.RESULTS.SEARCH_PLACEHOLDER')
            "
            type="search"
            class-name="h-9 bg-background pl-9 shadow-none"
          />
        </div>
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

      <p
        v-else-if="!filteredNumbers.length"
        class="text-[13.5px] text-muted-foreground"
      >
        {{ t('PHONE_NUMBERS_MGMT.BUY_MODAL.RESULTS.NO_MATCH') }}
      </p>

      <div v-else class="flex max-h-80 flex-col gap-3 overflow-y-auto">
        <RelayButton
          v-for="result in filteredNumbers"
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
                formatPrice(result)
                  ? t('PHONE_NUMBERS_MGMT.BUY_MODAL.RESULTS.PRICE_PER_MONTH', {
                      price: formatPrice(result),
                    })
                  : t('PHONE_NUMBERS_MGMT.BUY_MODAL.RESULTS.PRICE_UNKNOWN')
              }}
            </span>
          </span>
        </RelayButton>
      </div>
    </div>

    <template v-else-if="state.step === STEPS.CONFIRM">
      <div :class="RELAY_MODAL_BODY_CLASS">
        <p class="mb-4 text-[13.5px] leading-relaxed text-muted-foreground">
          {{ t('PHONE_NUMBERS_MGMT.BUY_MODAL.CONFIRM.DESCRIPTION') }}
        </p>
        <p class="text-[16px] font-semibold text-foreground">
          {{ getPhoneNumber(state.selectedNumber) }}
        </p>
      </div>
      <div :class="RELAY_MODAL_FORM_FOOTER_CLASS">
        <RelayButton variant="outline" size="lg" @click="backToResults">
          {{ t('PHONE_NUMBERS_MGMT.BUY_MODAL.CONFIRM.BACK_BUTTON') }}
        </RelayButton>
        <RelayButton
          size="lg"
          :disabled="uiFlags.isCreating"
          @click="confirmOrder"
        >
          {{ t('PHONE_NUMBERS_MGMT.BUY_MODAL.CONFIRM.CONFIRM_BUTTON') }}
        </RelayButton>
      </div>
    </template>
  </RelayModal>
</template>
