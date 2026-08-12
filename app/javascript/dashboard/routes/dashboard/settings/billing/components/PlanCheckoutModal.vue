<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import EnterpriseAccountAPI from 'dashboard/api/enterprise/account';

const props = defineProps({
  showCountrySelect: {
    type: Boolean,
    default: true,
  },
  lockedPaymentProvider: {
    type: String,
    default: null,
  },
  initialCountry: {
    type: String,
    default: '',
  },
  countryOptions: {
    type: Array,
    default: () => [],
  },
  paymentGateways: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['proceed']);

const { t } = useI18n();

const dialogRef = ref(null);
const selectedPlan = ref('');
const billingCountry = ref('');
const couponInput = ref('');
const appliedCouponCode = ref('');
const pricing = ref(null);
const pricingError = ref('');
const couponError = ref('');
const isLoadingPricing = ref(false);
const isValidatingCoupon = ref(false);
const isProceeding = ref(false);

const resolveProviderForCountry = country => {
  const normalizedCountry = (country || '').toUpperCase();
  if (!normalizedCountry) return null;
  if (!props.paymentGateways.length) {
    return normalizedCountry === 'IN' ? 'razorpay' : 'stripe';
  }

  const countryMatch = props.paymentGateways.find(gateway =>
    (gateway.country_codes || []).includes(normalizedCountry)
  );
  if (countryMatch) return countryMatch.id;

  const fallbackGateway = props.paymentGateways.find(
    gateway => !(gateway.country_codes || []).length
  );
  return fallbackGateway?.id || null;
};

const gatewayLabel = provider => {
  const gateway = props.paymentGateways.find(entry => entry.id === provider);
  if (gateway?.label) return gateway.label;
  if (provider === 'razorpay') {
    return t('BILLING_SETTINGS.SELECT_PLAN.PROVIDER_RAZORPAY');
  }
  return t('BILLING_SETTINGS.SELECT_PLAN.PROVIDER_STRIPE');
};

const effectiveCountry = computed(() => {
  if (props.lockedPaymentProvider === 'razorpay') {
    return (
      props.paymentGateways.find(gateway => gateway.id === 'razorpay')
        ?.country_codes?.[0] || 'IN'
    );
  }
  if (props.lockedPaymentProvider === 'stripe') {
    return billingCountry.value || 'US';
  }
  return billingCountry.value;
});

const isCountrySupported = computed(() => {
  if (!effectiveCountry.value) return true;
  return Boolean(resolveProviderForCountry(effectiveCountry.value));
});

const paymentProviderLabel = computed(() => {
  if (props.lockedPaymentProvider) {
    return gatewayLabel(props.lockedPaymentProvider);
  }
  return gatewayLabel(resolveProviderForCountry(effectiveCountry.value));
});

const canProceed = computed(() => {
  if (!selectedPlan.value) return false;
  if (props.showCountrySelect && !effectiveCountry.value) return false;
  if (!isCountrySupported.value) return false;
  if (effectiveCountry.value && !pricing.value) return false;
  return true;
});

const hasDiscount = computed(() => {
  if (!pricing.value) return false;
  return pricing.value.discounted_amount < pricing.value.original_amount;
});

const formatMoney = (amount, currency) => {
  if (amount == null) return '';
  const code = (currency || 'usd').toUpperCase();
  const locale = code === 'INR' ? 'en-IN' : 'en-US';
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency: code,
  }).format(Number(amount));
};

const apiErrorMessage = (error, fallback) =>
  error.response?.data?.error || error.response?.data?.message || fallback;

const resetState = () => {
  couponInput.value = '';
  appliedCouponCode.value = '';
  pricing.value = null;
  pricingError.value = '';
  couponError.value = '';
  isValidatingCoupon.value = false;
  isProceeding.value = false;
};

const refreshPricing = async ({
  couponCode = appliedCouponCode.value,
  isCouponValidation = false,
} = {}) => {
  if (!selectedPlan.value) return;
  if (props.showCountrySelect && !effectiveCountry.value) {
    pricingError.value = t(
      'BILLING_SETTINGS.PLAN_CHECKOUT.SELECT_COUNTRY_FOR_PRICING'
    );
    return;
  }

  isLoadingPricing.value = true;
  pricingError.value = '';
  try {
    const response = await EnterpriseAccountAPI.validatePlanCoupon({
      planName: selectedPlan.value,
      country: effectiveCountry.value,
      couponCode: couponCode || undefined,
    });

    pricing.value = response.data;
  } catch (error) {
    pricing.value = null;
    if (!isCouponValidation) {
      pricingError.value = apiErrorMessage(
        error,
        t('BILLING_SETTINGS.PLAN_CHECKOUT.PRICING_ERROR')
      );
    }
    throw error;
  } finally {
    isLoadingPricing.value = false;
  }
};

const restoreBasePricing = async () => {
  try {
    await refreshPricing({ couponCode: '' });
  } catch {
    // pricingError is set in refreshPricing
  }
};

const handleCouponValidationFailure = async error => {
  appliedCouponCode.value = '';
  couponError.value = apiErrorMessage(
    error,
    t('BILLING_SETTINGS.PLAN_CHECKOUT.COUPON_INVALID')
  );
  pricingError.value = '';
  await restoreBasePricing();
};

const open = async plan => {
  selectedPlan.value = plan;
  billingCountry.value = props.initialCountry || '';
  resetState();
  dialogRef.value?.open();
  await nextTick();
  if (effectiveCountry.value) {
    try {
      await refreshPricing({ couponCode: '' });
    } catch {
      // pricingError is set in refreshPricing
    }
  } else if (props.showCountrySelect) {
    pricingError.value = t(
      'BILLING_SETTINGS.PLAN_CHECKOUT.SELECT_COUNTRY_FOR_PRICING'
    );
  }
};

const close = () => {
  dialogRef.value?.close();
};

const handleApplyCoupon = async () => {
  const code = couponInput.value.trim();
  if (!code) {
    couponError.value = t('BILLING_SETTINGS.PLAN_CHECKOUT.COUPON_REQUIRED');
    return;
  }

  if (props.showCountrySelect && !effectiveCountry.value) {
    useAlert(t('BILLING_SETTINGS.SELECT_PLAN.COUNTRY_REQUIRED'));
    return;
  }

  isValidatingCoupon.value = true;
  couponError.value = '';
  pricingError.value = '';
  try {
    await refreshPricing({ couponCode: code, isCouponValidation: true });
    appliedCouponCode.value = code.toUpperCase();
  } catch (error) {
    await handleCouponValidationFailure(error);
  } finally {
    isValidatingCoupon.value = false;
  }
};

const handleRemoveCoupon = async () => {
  couponInput.value = '';
  appliedCouponCode.value = '';
  couponError.value = '';
  try {
    await refreshPricing({ couponCode: '' });
  } catch (error) {
    pricing.value = null;
  }
};

const handleProceed = async () => {
  if (!canProceed.value) return;

  isProceeding.value = true;
  try {
    emit('proceed', {
      planName: selectedPlan.value,
      country: effectiveCountry.value,
      couponCode: appliedCouponCode.value || undefined,
    });
  } finally {
    isProceeding.value = false;
  }
};

watch(couponInput, () => {
  if (couponError.value) {
    couponError.value = '';
  }
});

watch(effectiveCountry, async (country, previousCountry) => {
  if (!selectedPlan.value || !country || country === previousCountry) return;
  if (appliedCouponCode.value) {
    try {
      await refreshPricing({ isCouponValidation: true });
      couponError.value = '';
    } catch (error) {
      couponInput.value = '';
      await handleCouponValidationFailure(error);
    }
    return;
  }

  try {
    await refreshPricing({ couponCode: '' });
  } catch {
    pricing.value = null;
  }
});

defineExpose({
  open,
  close,
  setProceeding: value => {
    isProceeding.value = value;
  },
});
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    width="md"
    :title="$t('BILLING_SETTINGS.PLAN_CHECKOUT.TITLE', { plan: selectedPlan })"
    :description="$t('BILLING_SETTINGS.PLAN_CHECKOUT.DESCRIPTION')"
    :show-confirm-button="false"
    :show-cancel-button="false"
    overflow-y-auto
  >
    <div class="flex flex-col gap-4">
      <div v-if="showCountrySelect">
        <label class="block text-sm font-medium text-n-slate-12 mb-1">
          {{ $t('BILLING_SETTINGS.SELECT_PLAN.COUNTRY_LABEL') }}
        </label>
        <ComboBox
          :model-value="billingCountry"
          :options="countryOptions"
          :placeholder="$t('BILLING_SETTINGS.SELECT_PLAN.COUNTRY_PLACEHOLDER')"
          :search-placeholder="
            $t('BILLING_SETTINGS.SELECT_PLAN.COUNTRY_SEARCH_PLACEHOLDER')
          "
          @update:model-value="billingCountry = $event"
        />
      </div>

      <p v-else class="text-sm text-n-slate-11">
        {{
          $t('BILLING_SETTINGS.SELECT_PLAN.PROVIDER_LOCKED_HINT', {
            provider: paymentProviderLabel,
          })
        }}
      </p>

      <p
        v-if="effectiveCountry && isCountrySupported"
        class="text-xs text-n-slate-11"
      >
        {{
          $t('BILLING_SETTINGS.SELECT_PLAN.PROVIDER_HINT', {
            provider: paymentProviderLabel,
          })
        }}
      </p>

      <p
        v-else-if="effectiveCountry && !isCountrySupported"
        class="text-xs text-n-ruby-11"
      >
        {{ $t('BILLING_SETTINGS.SELECT_PLAN.UNSUPPORTED_COUNTRY') }}
      </p>

      <div class="flex flex-col gap-2">
        <Input
          v-model="couponInput"
          :label="$t('BILLING_SETTINGS.SELECT_PLAN.COUPON_LABEL')"
          :placeholder="$t('BILLING_SETTINGS.SELECT_PLAN.COUPON_PLACEHOLDER')"
          :disabled="!!appliedCouponCode"
        />
        <div class="flex gap-2">
          <Button
            v-if="!appliedCouponCode"
            type="button"
            variant="faded"
            color="slate"
            :label="$t('BILLING_SETTINGS.PLAN_CHECKOUT.APPLY_COUPON')"
            :is-loading="isValidatingCoupon"
            :disabled="!couponInput.trim() || isValidatingCoupon"
            @click="handleApplyCoupon"
          />
          <Button
            v-else
            type="button"
            variant="faded"
            color="slate"
            :label="$t('BILLING_SETTINGS.PLAN_CHECKOUT.REMOVE_COUPON')"
            @click="handleRemoveCoupon"
          />
        </div>
        <p v-if="couponError" class="text-xs text-n-ruby-10">
          {{ couponError }}
        </p>
        <p v-else class="text-xs text-n-slate-11">
          {{ $t('BILLING_SETTINGS.PLAN_CHECKOUT.COUPON_OPTIONAL_HINT') }}
        </p>
      </div>

      <p v-if="pricingError" class="text-xs text-n-ruby-11">
        {{ pricingError }}
      </p>
      <p v-else-if="isLoadingPricing" class="text-xs text-n-slate-11">
        {{ $t('BILLING_SETTINGS.PLAN_CHECKOUT.LOADING_PRICING') }}
      </p>

      <div
        v-if="pricing"
        class="rounded-lg border border-n-weak bg-n-solid-1 p-4 space-y-3"
      >
        <div class="flex items-center justify-between text-sm">
          <span class="text-n-slate-11">
            {{ $t('BILLING_SETTINGS.PLAN_CHECKOUT.ORIGINAL_PRICE') }}
          </span>
          <span class="text-n-slate-12">
            {{ formatMoney(pricing.original_amount, pricing.currency) }}/{{
              $t('BILLING_SETTINGS.PLAN_CHECKOUT.PER_MONTH')
            }}
          </span>
        </div>

        <div
          v-if="hasDiscount && pricing.coupon"
          class="flex items-center justify-between text-sm"
        >
          <span class="text-n-slate-11">
            {{ $t('BILLING_SETTINGS.PLAN_CHECKOUT.DISCOUNT') }}
            ({{ pricing.coupon.discount_label }})
          </span>
          <span class="text-n-teal-10">
            -{{
              formatMoney(
                pricing.original_amount - pricing.discounted_amount,
                pricing.currency
              )
            }}
          </span>
        </div>

        <div
          v-if="pricing.coupon"
          class="text-xs text-n-slate-11 border-t border-n-weak pt-3"
        >
          <p class="font-medium text-n-slate-12 mb-1">
            {{ $t('BILLING_SETTINGS.PLAN_CHECKOUT.COUPON_APPLIED') }}
          </p>
          <p>{{ pricing.coupon.code }} — {{ pricing.coupon.name }}</p>
        </div>

        <div
          class="flex items-center justify-between text-base font-semibold border-t border-n-weak pt-3"
        >
          <span class="text-n-slate-12">
            {{ $t('BILLING_SETTINGS.PLAN_CHECKOUT.TOTAL') }}
          </span>
          <span class="text-n-slate-12">
            {{ formatMoney(pricing.discounted_amount, pricing.currency) }}/{{
              $t('BILLING_SETTINGS.PLAN_CHECKOUT.PER_MONTH')
            }}
          </span>
        </div>
      </div>

      <div class="flex gap-3 pt-2">
        <Button
          type="button"
          variant="faded"
          color="slate"
          class="w-full"
          :label="$t('DIALOG.BUTTONS.CANCEL')"
          @click="close"
        />
        <Button
          type="button"
          variant="solid"
          color="blue"
          class="w-full"
          :label="$t('BILLING_SETTINGS.PLAN_CHECKOUT.PROCEED')"
          :disabled="!canProceed"
          :is-loading="isProceeding"
          @click="handleProceed"
        />
      </div>
    </div>
  </Dialog>
</template>
