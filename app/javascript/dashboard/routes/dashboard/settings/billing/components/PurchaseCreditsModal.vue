<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import CreditPackageCard from './CreditPackageCard.vue';
import EnterpriseAccountAPI from 'dashboard/api/enterprise/account';
import { buildCheckoutReturnUrls } from 'dashboard/composables/useBillingCheckoutReturn';

const props = defineProps({
  paymentProvider: {
    type: String,
    default: 'stripe',
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();

const STRIPE_TOPUP_OPTIONS = [
  { credits: 1000, amount: 20.0, currency: 'usd' },
  { credits: 2500, amount: 50.0, currency: 'usd' },
  { credits: 6000, amount: 100.0, currency: 'usd' },
  { credits: 12000, amount: 200.0, currency: 'usd' },
];

const RAZORPAY_TOPUP_OPTIONS = [
  { credits: 1000, amount: 1699.0, currency: 'inr' },
  { credits: 2500, amount: 4199.0, currency: 'inr' },
  { credits: 6000, amount: 8299.0, currency: 'inr' },
  { credits: 12000, amount: 16499.0, currency: 'inr' },
];

const TOPUP_OPTIONS = computed(() =>
  props.paymentProvider === 'razorpay'
    ? RAZORPAY_TOPUP_OPTIONS
    : STRIPE_TOPUP_OPTIONS
);

const POPULAR_CREDITS_AMOUNT = 6000;
const STEP_SELECT = 'select';
const STEP_CONFIRM = 'confirm';

const dialogRef = ref(null);
const selectedCredits = ref(null);
const isLoading = ref(false);
const currentStep = ref(STEP_SELECT);

const selectedOption = computed(() => {
  return TOPUP_OPTIONS.value.find(o => o.credits === selectedCredits.value);
});

const formattedAmount = computed(() => {
  if (!selectedOption.value) return '';
  return new Intl.NumberFormat(
    selectedOption.value.currency === 'inr' ? 'en-IN' : 'en-US',
    {
      style: 'currency',
      currency: selectedOption.value.currency.toUpperCase(),
    }
  ).format(selectedOption.value.amount);
});

const formattedCredits = computed(() => {
  if (!selectedOption.value) return '';
  return selectedOption.value.credits.toLocaleString();
});

const dialogTitle = computed(() => {
  return currentStep.value === STEP_SELECT
    ? t('BILLING_SETTINGS.TOPUP.MODAL_TITLE')
    : t('BILLING_SETTINGS.TOPUP.CONFIRM.TITLE');
});

const dialogDescription = computed(() => {
  return currentStep.value === STEP_SELECT
    ? t('BILLING_SETTINGS.TOPUP.MODAL_DESCRIPTION')
    : '';
});

const dialogWidth = computed(() => {
  return currentStep.value === STEP_SELECT ? 'xl' : 'md';
});

const handlePackageSelect = credits => {
  selectedCredits.value = credits;
};

const open = () => {
  const popularOption = TOPUP_OPTIONS.value.find(
    o => o.credits === POPULAR_CREDITS_AMOUNT
  );
  selectedCredits.value =
    popularOption?.credits || TOPUP_OPTIONS.value[0]?.credits;
  currentStep.value = STEP_SELECT;
  isLoading.value = false;
  dialogRef.value?.open();
};

const close = () => {
  dialogRef.value?.close();
};

const handleClose = () => {
  emit('close');
};

const goToConfirmStep = () => {
  if (!selectedOption.value) return;
  currentStep.value = STEP_CONFIRM;
};

const goBackToSelectStep = () => {
  currentStep.value = STEP_SELECT;
};

const handlePurchase = async () => {
  if (!selectedOption.value) return;

  isLoading.value = true;
  try {
    const { successUrl, cancelUrl } = buildCheckoutReturnUrls('topup_checkout');
    const response = await EnterpriseAccountAPI.createTopupCheckout(
      selectedOption.value.credits,
      {
        successUrl,
        cancelUrl,
      }
    );

    if (response.data.checkout_url) {
      window.location.href = response.data.checkout_url;
      return;
    }

    useAlert(t('BILLING_SETTINGS.TOPUP.PURCHASE_ERROR'));
  } catch (error) {
    const errorMessage =
      error.response?.data?.error || t('BILLING_SETTINGS.TOPUP.PURCHASE_ERROR');
    useAlert(errorMessage);
  } finally {
    isLoading.value = false;
  }
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="dialogTitle"
    :description="dialogDescription"
    :width="dialogWidth"
    :show-confirm-button="false"
    :show-cancel-button="false"
    @close="handleClose"
  >
    <template v-if="currentStep === 'select'">
      <div class="mb-6 grid grid-cols-2 gap-4">
        <CreditPackageCard
          v-for="option in TOPUP_OPTIONS"
          :key="option.credits"
          name="credit-package"
          :credits="option.credits"
          :amount="option.amount"
          :currency="option.currency"
          :is-popular="option.credits === POPULAR_CREDITS_AMOUNT"
          :is-selected="selectedCredits === option.credits"
          @select="handlePackageSelect(option.credits)"
        />
      </div>

      <div
        class="mb-2 rounded-lg border border-border/60 bg-muted/20 p-4 text-[13.5px] leading-relaxed text-muted-foreground shadow-xs"
      >
        <p>
          <span class="font-bold text-foreground">{{
            $t('BILLING_SETTINGS.TOPUP.NOTE_TITLE')
          }}</span>
          {{ $t('BILLING_SETTINGS.TOPUP.NOTE_DESCRIPTION') }}
        </p>
      </div>
    </template>

    <template v-else>
      <div class="flex flex-col gap-4">
        <p class="text-[14px] leading-relaxed text-foreground">
          {{
            $t('BILLING_SETTINGS.TOPUP.CONFIRM.DESCRIPTION', {
              credits: formattedCredits,
              amount: formattedAmount,
            })
          }}
        </p>
        <div
          class="rounded-lg border border-destructive/20 bg-destructive/10 p-4 shadow-xs"
        >
          <p class="text-[13px] font-medium leading-relaxed text-destructive">
            {{ $t('BILLING_SETTINGS.TOPUP.CONFIRM.INSTANT_DEDUCTION_NOTE') }}
          </p>
        </div>
      </div>
    </template>

    <template #footer>
      <div class="flex w-full items-center gap-3 sm:gap-4">
        <template v-if="currentStep === 'select'">
          <RelayButton
            variant="outline"
            class="h-11 flex-1 border-transparent bg-muted/50 shadow-none hover:bg-muted"
            @click="close"
          >
            {{ $t('BILLING_SETTINGS.TOPUP.CANCEL') }}
          </RelayButton>
          <RelayButton
            class="h-11 flex-1 shadow-sm"
            :disabled="!selectedOption"
            @click="goToConfirmStep"
          >
            {{ $t('BILLING_SETTINGS.TOPUP.CONFIRM.CONFIRM_PURCHASE') }}
          </RelayButton>
        </template>
        <template v-else>
          <RelayButton
            variant="outline"
            class="h-10 flex-1 border-transparent bg-muted/50 shadow-none hover:bg-muted"
            @click="goBackToSelectStep"
          >
            {{ $t('BILLING_SETTINGS.TOPUP.CONFIRM.GO_BACK') }}
          </RelayButton>
          <RelayButton
            class="h-10 flex-1 shadow-sm"
            :disabled="isLoading"
            @click="handlePurchase"
          >
            {{ $t('BILLING_SETTINGS.TOPUP.PURCHASE') }}
          </RelayButton>
        </template>
      </div>
    </template>
  </Dialog>
</template>
