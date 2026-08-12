<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { format } from 'date-fns';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import BillingMeter from './components/BillingMeter.vue';
import BillingCard from './components/BillingCard.vue';
import DetailItem from './components/DetailItem.vue';
import PurchaseCreditsModal from './components/PurchaseCreditsModal.vue';
import EnterpriseInquiryModal from './components/EnterpriseInquiryModal.vue';
import DowngradePlanWarningModal from './components/DowngradePlanWarningModal.vue';
import PlanCheckoutModal from './components/PlanCheckoutModal.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import Input from 'dashboard/components-next/input/Input.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import EnterpriseAccountAPI from 'dashboard/api/enterprise/account';
import { useBillingCheckoutReturn } from 'dashboard/composables/useBillingCheckoutReturn';
import countries from 'shared/constants/countries.js';

const router = useRouter();
const { buildCheckoutReturnUrls, processCheckoutReturn } =
  useBillingCheckoutReturn();
const { t, te } = useI18n();
const { currentAccount, isOnChatwootCloud, isCloudFeatureEnabled } =
  useAccount();
const {
  captainEnabled,
  captainLimits,
  documentLimits,
  responseLimits,
  fetchLimits,
  isFetchingLimits,
} = useCaptain();

const uiFlags = useMapGetter('accounts/getUIFlags');
const store = useStore();

const purchaseCreditsModalRef = ref(null);
const enterpriseInquiryModalRef = ref(null);
const downgradeWarningModalRef = ref(null);
const planCheckoutModalRef = ref(null);
const showPlanPicker = ref(false);
const showPlanDetails = ref(false);
const billingCountry = ref(
  currentAccount.value?.custom_attributes?.billing_country || ''
);
const allCountryOptions = countries.map(country => ({
  value: country.id,
  label: `${country.emoji} ${country.name}`,
}));

const accountSubscription = computed(
  () => currentAccount.value?.subscription || null
);
const hasActiveSubscription = computed(
  () => !!accountSubscription.value?.active
);
const lockedPaymentProvider = computed(() => {
  const sub = accountSubscription.value;
  if (!sub) return null;

  return (
    sub.payment_provider ||
    currentAccount.value?.custom_attributes?.payment_provider ||
    null
  );
});

const planCatalog = ref([]);
const paymentGateways = ref([]);
const supportsAllCountries = ref(true);
const supportedCountryCodes = ref([]);

const resolveProviderForCountry = country => {
  const normalizedCountry = (country || '').toUpperCase();
  if (!normalizedCountry) return null;
  if (!paymentGateways.value.length) {
    return normalizedCountry === 'IN' ? 'razorpay' : 'stripe';
  }

  const countryMatch = paymentGateways.value.find(gateway =>
    (gateway.country_codes || []).includes(normalizedCountry)
  );
  if (countryMatch) return countryMatch.id;

  const fallbackGateway = paymentGateways.value.find(
    gateway => !(gateway.country_codes || []).length
  );
  return fallbackGateway?.id || null;
};

const availableCountryOptions = computed(() => {
  if (supportsAllCountries.value) {
    return allCountryOptions;
  }

  if (!supportedCountryCodes.value.length) {
    return allCountryOptions;
  }

  return allCountryOptions.filter(option =>
    supportedCountryCodes.value.includes(option.value)
  );
});

const gatewayLabel = provider =>
  paymentGateways.value.find(gateway => gateway.id === provider)?.label ||
  (provider === 'razorpay'
    ? t('BILLING_SETTINGS.SELECT_PLAN.PROVIDER_RAZORPAY')
    : t('BILLING_SETTINGS.SELECT_PLAN.PROVIDER_STRIPE'));

// Country picker is only for first-time / inactive accounts. An active plan
// locks the gateway so the customer cannot switch Stripe <-> Razorpay mid-cycle.
const showBillingCountrySelect = computed(() => !hasActiveSubscription.value);
const effectiveBillingCountry = computed(() => {
  if (lockedPaymentProvider.value === 'razorpay') {
    return (
      paymentGateways.value.find(gateway => gateway.id === 'razorpay')
        ?.country_codes?.[0] || 'IN'
    );
  }
  if (lockedPaymentProvider.value === 'stripe') {
    return billingCountry.value || 'US';
  }
  return billingCountry.value;
});
const paymentProviderLabel = computed(() => {
  if (lockedPaymentProvider.value) {
    return gatewayLabel(lockedPaymentProvider.value);
  }
  return gatewayLabel(resolveProviderForCountry(effectiveBillingCountry.value));
});
const usesStripePortal = computed(
  () => lockedPaymentProvider.value === 'stripe'
);
const usesRazorpayBilling = computed(
  () => lockedPaymentProvider.value === 'razorpay'
);

// Order matters here - used to detect downgrades and to show the retention
// window in the downgrade warning. Keep in sync with
// lib/seeders/plan_feature_limit_seeder.rb RESOURCE_LIMITS['data_retention_months'].
const PLAN_RANK = { Hobby: 0, Standard: 1, Business: 2, Enterprise: 3 };
const PLAN_RETENTION_MONTHS = {
  Hobby: 1,
  Standard: 6,
  Business: 12,
  Enterprise: null,
};

// Reseller & Client Billing States
// `is_reseller` alone is not enough - the reseller_dashboard capability
// must also be enabled on the account for the dashboard to be usable.
const isReseller = computed(
  () =>
    !!currentAccount.value.is_reseller &&
    isCloudFeatureEnabled(FEATURE_FLAGS.RESELLER_DASHBOARD)
);
const hasResellerParent = computed(() => !!currentAccount.value.parent_id);

const isFetchingMarketplace = ref(false);
const marketplaceData = ref({
  connected_account: null,
  prices: [],
});

const normalizeBillingCountrySelection = () => {
  if (supportsAllCountries.value) return;

  const availableCodes = availableCountryOptions.value.map(
    option => option.value
  );
  if (billingCountry.value && !availableCodes.includes(billingCountry.value)) {
    billingCountry.value = availableCodes[0] || '';
  }
};

const fetchPlanCatalog = async () => {
  try {
    const response = await EnterpriseAccountAPI.getPlans();
    planCatalog.value = response.data.plans || response.data;
    const gatewayConfig = response.data.payment_gateways;
    if (Array.isArray(gatewayConfig)) {
      paymentGateways.value = gatewayConfig;
      supportsAllCountries.value = true;
      supportedCountryCodes.value = [];
    } else {
      paymentGateways.value = gatewayConfig?.gateways || [];
      supportsAllCountries.value =
        gatewayConfig?.supports_all_countries !== false;
      supportedCountryCodes.value =
        gatewayConfig?.supported_country_codes || [];
    }
    normalizeBillingCountrySelection();
  } catch (error) {
    // Non-fatal - the plan picker still works without prices shown.
  }
};
const DEFAULT_PLAN_NAMES = ['Hobby', 'Standard', 'Business', 'Enterprise'];

const selectablePlans = computed(() => {
  const enabledPlans = planCatalog.value.filter(plan => plan.enabled !== false);
  if (enabledPlans.length) {
    return enabledPlans.map(plan => plan.name);
  }
  return DEFAULT_PLAN_NAMES;
});

const getPlanPriceForProvider = (plan, provider) => {
  if (!plan) return null;
  const p = provider || 'stripe';
  if (plan.gateway_prices && plan.gateway_prices[p]) {
    return plan.gateway_prices[p].amount;
  }
  return plan.price_per_agent;
};

const agencyPriceInput = ref(0);
const selectedCurrency = ref('usd');

const commissionPercent = computed(() => {
  return marketplaceData.value.connected_account?.commission_percent || 30;
});

const platformFeeAmount = computed(() => {
  const price = parseFloat(agencyPriceInput.value || 0);
  return ((price * commissionPercent.value) / 100).toFixed(2);
});

const totalClientPrice = computed(() => {
  const price = parseFloat(agencyPriceInput.value || 0);
  const fee = parseFloat(platformFeeAmount.value || 0);
  return (price + fee).toFixed(2);
});

const activePlanPrice = computed(() => {
  const preferred =
    marketplaceData.value.connected_account?.payment_provider === 'razorpay'
      ? 'inr'
      : 'usd';
  return (
    marketplaceData.value.prices?.find(
      p => p.currency === preferred && p.active
    ) || marketplaceData.value.prices?.find(p => p.active)
  );
});

const customAttributes = computed(() => {
  return currentAccount.value.custom_attributes || {};
});

const enterpriseInquiry = computed(
  () => customAttributes.value.enterprise_inquiry || null
);

const hasPendingEnterpriseInquiry = computed(() => {
  const inquiry = enterpriseInquiry.value;
  if (!inquiry) return false;

  return !inquiry.processed_at && !inquiry.rejected_at;
});

const planName = computed(() => {
  return customAttributes.value.plan_name;
});

const canPurchaseCredits = computed(() => {
  const plan = planName.value?.toLowerCase();
  // Hobby (and legacy Hacker) are free tiers - top-ups require a paid plan.
  return plan && !['hobby', 'hacker'].includes(plan);
});

const hasABillingPlan = computed(() => {
  return !!planName.value;
});

const accountLimits = computed(() => currentAccount.value?.limits || {});

const agentLimits = computed(() => {
  const limits = accountLimits.value?.agents;
  if (!limits) return null;
  return { consumed: limits.consumed, totalCount: limits.allowed };
});

const inboxLimits = computed(() => {
  const limits = accountLimits.value?.non_web_inboxes;
  if (!limits) return null;
  return { consumed: limits.consumed, totalCount: limits.allowed };
});

const conversationLimits = computed(() => {
  const limits = accountLimits.value?.conversation;
  if (!limits) return null;
  return { consumed: limits.consumed, totalCount: limits.allowed };
});

const contactLimits = computed(() => {
  const limits = accountLimits.value?.contacts;
  if (!limits) return null;
  return { consumed: limits.consumed, totalCount: limits.allowed };
});

const automationLimits = computed(() => {
  const limits = accountLimits.value?.automations;
  if (!limits) return null;
  return { consumed: limits.consumed, totalCount: limits.allowed };
});

const t3SubaccountLimits = computed(() => {
  const limits = accountLimits.value?.t3_subaccounts;
  if (!limits) return null;
  return { consumed: limits.consumed, totalCount: limits.allowed };
});

const dataRetentionLabel = computed(() => {
  const months = accountLimits.value?.data_retention_months;
  return months
    ? t('BILLING_SETTINGS.CURRENT_PLAN.RETENTION_MONTHS', { months })
    : t('BILLING_SETTINGS.CURRENT_PLAN.RETENTION_UNLIMITED');
});

const transactions = ref([]);
const isFetchingTransactions = ref(false);

const formatTransactionDate = value => {
  return value ? format(new Date(value), 'dd MMM, yyyy') : '';
};

const formatBillingDate = value => {
  return value ? format(new Date(value), 'd MMM yyyy') : '—';
};

const isAutoRenewOn = computed(() => {
  if (!hasActiveSubscription.value) return false;
  return !accountSubscription.value?.cancel_at_period_end;
});

const isSubscriptionActiveBadge = computed(() => {
  const status = accountSubscription.value?.status;
  return (
    status === 'active' || status === 'trialing' || hasActiveSubscription.value
  );
});

const formatMoneyAmount = (amount, currency) => {
  const code = (currency || 'usd').toUpperCase();
  const locale = code === 'INR' ? 'en-IN' : 'en-US';
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency: code,
  }).format(Number(amount || 0));
};

const formatTransactionAmount = transaction => {
  return formatMoneyAmount(transaction.amount, transaction.currency);
};

const PAST_DUE_STATUSES = ['past_due', 'unpaid'];

const subscriptionStatusLabel = computed(() => {
  const status = accountSubscription.value?.status;
  if (!status) return '—';
  const key = `BILLING_SETTINGS.SUBSCRIPTION.STATUS_${status.toUpperCase().replace(/-/g, '_')}`;
  return te(key) ? t(key) : status;
});

const isSubscriptionPaymentPending = computed(() => {
  const status = accountSubscription.value?.status;
  return status && PAST_DUE_STATUSES.includes(status);
});

const subscriptionPeriodEndLabel = computed(() => {
  if (accountSubscription.value?.cancel_at_period_end) {
    return t('BILLING_SETTINGS.SUBSCRIPTION.ACCESS_UNTIL');
  }
  return t('BILLING_SETTINGS.CURRENT_PLAN.RENEWS_ON');
});

const subscriptionPeriodEndValue = computed(() => {
  const endAt =
    accountSubscription.value?.current_period_end ||
    customAttributes.value?.subscription_ends_on;
  return formatBillingDate(endAt);
});

const subscriptionPeriodStartValue = computed(() => {
  return formatBillingDate(accountSubscription.value?.current_period_start);
});

const currencyForProvider = provider => {
  const gateway = paymentGateways.value.find(entry => entry.id === provider);
  return gateway?.currency || (provider === 'razorpay' ? 'inr' : 'usd');
};

const currentPlanPriceLabel = computed(() => {
  const plan = planCatalog.value.find(p => p.name === planName.value);
  const provider = accountSubscription.value?.payment_provider;
  const price = getPlanPriceForProvider(plan, provider);

  if (!plan || price == null || price === '') {
    return t('BILLING_SETTINGS.SELECT_PLAN.CUSTOM_PRICING');
  }
  if (Number(price) === 0) {
    return t('BILLING_SETTINGS.SELECT_PLAN.FREE_PLAN');
  }
  const currency = currencyForProvider(provider);
  return `${formatMoneyAmount(price, currency)}/${t('BILLING_SETTINGS.PLAN_CHECKOUT.PER_MONTH')}`;
});

const paymentProviderDisplay = computed(() => {
  const provider = accountSubscription.value?.payment_provider;
  if (!provider) return '—';
  return gatewayLabel(provider);
});

const cancellationScheduledLabel = computed(() => {
  if (!accountSubscription.value?.cancel_at_period_end) return null;
  return t('BILLING_SETTINGS.SUBSCRIPTION.CANCELLATION_SCHEDULED');
});

const fetchMarketplaceData = async () => {
  if (isReseller.value || hasResellerParent.value) {
    isFetchingMarketplace.value = true;
    try {
      const response = await window.axios.get(
        `/enterprise/api/v1/accounts/${currentAccount.value.id}/marketplace_pricing`
      );
      marketplaceData.value = response.data;
      const preferredCurrency =
        response.data.connected_account?.payment_provider === 'razorpay'
          ? 'inr'
          : 'usd';
      selectedCurrency.value = preferredCurrency;
      const activePrice = response.data.prices?.find(
        p => p.currency === preferredCurrency && p.active
      );
      if (activePrice) {
        agencyPriceInput.value = activePrice.agency_price;
      }
    } catch {
      // Marketplace pricing is optional; keep the billing page usable without it.
    } finally {
      isFetchingMarketplace.value = false;
    }
  }
};

const handleConnectStripe = async () => {
  try {
    const country =
      currentAccount.value?.custom_attributes?.billing_country ||
      billingCountry.value ||
      'US';
    const response = await window.axios.post(
      `/enterprise/api/v1/accounts/${currentAccount.value.id}/connected_account`,
      {
        country,
        refresh_url: window.location.href,
        return_url: window.location.href,
      }
    );
    if (response.data.onboarding_url) {
      window.location.href = response.data.onboarding_url;
    }
  } catch (error) {
    useAlert(
      error.response?.data?.error || 'Payment onboarding request failed'
    );
  }
};

const handleSavePricing = async () => {
  try {
    await window.axios.post(
      `/enterprise/api/v1/accounts/${currentAccount.value.id}/marketplace_pricing`,
      {
        marketplace_plan_price: {
          currency: selectedCurrency.value,
          agency_price: agencyPriceInput.value,
        },
      }
    );
    useAlert(t('BILLING_SETTINGS.RESELLER.SAVE_SUCCESS'));
    fetchMarketplaceData();
  } catch (error) {
    useAlert(error.response?.data?.error || 'Failed to save pricing');
  }
};

const handleSubscribe = async () => {
  try {
    const currency =
      marketplaceData.value.connected_account?.payment_provider === 'razorpay'
        ? 'inr'
        : 'usd';
    const { successUrl, cancelUrl } = buildCheckoutReturnUrls(
      'marketplace_checkout'
    );
    const response = await window.axios.post(
      `/enterprise/api/v1/accounts/${currentAccount.value.id}/marketplace_checkout`,
      {
        currency,
        success_url: successUrl,
        cancel_url: cancelUrl,
      }
    );
    if (response.data.checkout_url) {
      window.location.href = response.data.checkout_url;
    }
  } catch (error) {
    useAlert(error.response?.data?.error || 'Checkout initialization failed');
  }
};

const openEnterpriseInquiryModal = () => {
  enterpriseInquiryModalRef.value?.open();
};

const isCancelingEnterpriseInquiry = ref(false);

const handleEnterpriseInquirySuccess = async () => {
  await store.dispatch('accounts/get', currentAccount.value.id);
};

const onCancelEnterpriseInquiry = async () => {
  isCancelingEnterpriseInquiry.value = true;
  try {
    await EnterpriseAccountAPI.cancelEnterpriseInquiry();
    useAlert(t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.CANCEL_SUCCESS'));
    await store.dispatch('accounts/get', currentAccount.value.id);
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.CANCEL_ERROR')
    );
  } finally {
    isCancelingEnterpriseInquiry.value = false;
  }
};

const fetchAccountDetails = async () => {
  await store.dispatch('accounts/get', currentAccount.value.id);
  fetchLimits();
};

const handleBillingPageLogic = async () => {
  // If self-hosted, redirect to dashboard
  if (!isOnChatwootCloud.value) {
    router.push({ name: 'home' });
    return;
  }

  // Load marketplace data if reseller or client
  if (isReseller.value || hasResellerParent.value) {
    await fetchMarketplaceData();
  } else {
    await fetchPlanCatalog();
  }

  await fetchAccountDetails();
  await processCheckoutReturn();
};

const onClickBillingPortal = () => {
  if (usesRazorpayBilling.value) {
    useAlert(t('BILLING_SETTINGS.SELECT_PLAN.RAZORPAY_MANAGE_HINT'));
    return;
  }
  store.dispatch('accounts/checkout');
};

const onClickCaptainUpgrade = () => {
  if (usesStripePortal.value) {
    onClickBillingPortal();
    return;
  }
  showPlanPicker.value = true;
};

const isCancelingSubscription = ref(false);
const onCancelRazorpaySubscription = async () => {
  isCancelingSubscription.value = true;
  try {
    await EnterpriseAccountAPI.cancelSubscription({ cancelAtCycleEnd: true });
    useAlert(t('BILLING_SETTINGS.SELECT_PLAN.CANCEL_SUBSCRIPTION_SUCCESS'));
    await store.dispatch('accounts/get', currentAccount.value.id);
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        t('BILLING_SETTINGS.SELECT_PLAN.CANCEL_SUBSCRIPTION_ERROR')
    );
  } finally {
    isCancelingSubscription.value = false;
  }
};

const topupPaymentProvider = computed(() => {
  return (
    lockedPaymentProvider.value ||
    resolveProviderForCountry(effectiveBillingCountry.value)
  );
});

const isCheckingOut = ref(false);
const handlePlanCheckoutProceed = async ({
  planName: selectedPlanName,
  country,
  couponCode,
}) => {
  isCheckingOut.value = true;
  planCheckoutModalRef.value?.setProceeding(true);
  try {
    const { successUrl, cancelUrl } = buildCheckoutReturnUrls('plan_checkout');
    const response = await EnterpriseAccountAPI.planCheckout({
      planName: selectedPlanName,
      country,
      couponCode,
      successUrl,
      cancelUrl,
    });
    if (response.data.checkout_url) {
      const checkoutUrl = response.data.checkout_url;
      if (checkoutUrl === window.location.href) {
        useAlert(
          'Could not open the payment page. Please try again or contact support.'
        );
        return;
      }
      window.location.href = checkoutUrl;
      return;
    }
    useAlert('Failed to start checkout');
  } catch (error) {
    useAlert(error.response?.data?.error || 'Failed to start checkout');
  } finally {
    isCheckingOut.value = false;
    planCheckoutModalRef.value?.setProceeding(false);
  }
};

const openPlanCheckoutModal = selectedPlan => {
  planCheckoutModalRef.value?.open(selectedPlan);
};

const handlePlanSelection = selectedPlan => {
  if (selectedPlan === 'Enterprise') {
    openEnterpriseInquiryModal();
    return;
  }

  const isDowngrade =
    planName.value &&
    PLAN_RANK[selectedPlan] != null &&
    PLAN_RANK[planName.value] != null &&
    PLAN_RANK[selectedPlan] < PLAN_RANK[planName.value];
  if (isDowngrade) {
    downgradeWarningModalRef.value?.open(
      selectedPlan,
      PLAN_RETENTION_MONTHS[selectedPlan]
    );
    return;
  }

  openPlanCheckoutModal(selectedPlan);
};

const handleDowngradeConfirm = selectedPlan => {
  downgradeWarningModalRef.value?.close();
  openPlanCheckoutModal(selectedPlan);
};

const onToggleChatWindow = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggle();
  }
};

const openPurchaseCreditsModal = () => {
  purchaseCreditsModalRef.value?.open();
};

const fetchTransactions = async () => {
  isFetchingTransactions.value = true;
  try {
    const response = await EnterpriseAccountAPI.getTransactions();
    transactions.value = response.data;
  } catch (error) {
    // Silently ignore - payment history is supplementary, not critical to the page.
  } finally {
    isFetchingTransactions.value = false;
  }
};

const planPriceLabel = selectablePlanName => {
  const plan = planCatalog.value.find(p => p.name === selectablePlanName);
  if (!plan) {
    return t('BILLING_SETTINGS.SELECT_PLAN.CUSTOM_PRICING');
  }
  const provider =
    lockedPaymentProvider.value ||
    resolveProviderForCountry(effectiveBillingCountry.value);
  const price = getPlanPriceForProvider(plan, provider);

  if (price == null || price === '') {
    return t('BILLING_SETTINGS.SELECT_PLAN.CUSTOM_PRICING');
  }
  if (Number(price) === 0) {
    return t('BILLING_SETTINGS.SELECT_PLAN.FREE_PLAN');
  }
  const currency = currencyForProvider(provider);
  return `${formatMoneyAmount(price, currency)}/${t('BILLING_SETTINGS.PLAN_CHECKOUT.PER_MONTH')}`;
};

const formatPlanPrice = planKey => {
  const label = planPriceLabel(planKey);
  if (label.includes('/')) {
    const parts = label.split('/');
    return { amount: parts[0], suffix: `/${parts[1]}` };
  }
  return { amount: label, suffix: '' };
};

onMounted(() => {
  handleBillingPageLogic();
  fetchTransactions();
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetchingItem || isFetchingMarketplace"
    :loading-message="$t('ATTRIBUTES_MGMT.LOADING')"
  >
    <template #body>
      <div class="flex w-full max-w-3xl flex-col gap-6 ltr:mr-auto rtl:ml-auto">
        <!-- Marketplace client: subscribes to the pricing their reseller parent
           published, instead of picking a direct platform plan. -->
        <section v-if="hasResellerParent" class="grid gap-6">
          <BillingCard
            :title="$t('BILLING_SETTINGS.CLIENT.TITLE')"
            :description="$t('BILLING_SETTINGS.CLIENT.DESCRIPTION')"
          >
            <template v-if="activePlanPrice">
              <div class="mb-4 grid gap-4 sm:grid-cols-2">
                <DetailItem
                  :label="$t('BILLING_SETTINGS.RESELLER.TOTAL_PRICE')"
                  :value="`$${activePlanPrice.total_amount}/mo`"
                />
              </div>
              <RelayButton class="shadow-sm" @click="handleSubscribe">
                {{ $t('BILLING_SETTINGS.CLIENT.SUBSCRIBE_BTN') }}
              </RelayButton>
            </template>
            <p v-else class="text-sm text-muted-foreground">
              {{ $t('BILLING_SETTINGS.CLIENT.NO_ACTIVE_PRICE') }}
            </p>
          </BillingCard>
        </section>

        <!-- Reseller: manage Stripe Connect onboarding and publish client pricing. -->
        <section v-if="isReseller" class="grid gap-6">
          <BillingCard
            :title="$t('BILLING_SETTINGS.RESELLER.TITLE')"
            :description="$t('BILLING_SETTINGS.RESELLER.DESCRIPTION')"
          >
            <div class="space-y-4">
              <div class="flex items-center justify-between gap-3">
                <span
                  class="text-sm font-medium"
                  :class="
                    marketplaceData.connected_account?.charges_enabled
                      ? 'text-emerald-600'
                      : 'text-amber-600'
                  "
                >
                  {{
                    marketplaceData.connected_account?.charges_enabled
                      ? $t('BILLING_SETTINGS.RESELLER.STATUS_ONBOARDED')
                      : $t('BILLING_SETTINGS.RESELLER.STATUS_NOT_ONBOARDED')
                  }}
                </span>
                <RelayButton
                  v-if="!marketplaceData.connected_account?.charges_enabled"
                  size="sm"
                  class="shadow-sm"
                  @click="handleConnectStripe"
                >
                  {{ $t('BILLING_SETTINGS.RESELLER.CONNECT_STRIPE') }}
                </RelayButton>
              </div>
              <p
                v-if="!marketplaceData.connected_account?.charges_enabled"
                class="text-sm text-muted-foreground"
              >
                {{ $t('BILLING_SETTINGS.RESELLER.CONNECT_DESC') }}
              </p>

              <template
                v-if="marketplaceData.connected_account?.charges_enabled"
              >
                <h4 class="text-sm font-medium text-foreground">
                  {{ $t('BILLING_SETTINGS.RESELLER.SET_PRICE') }}
                </h4>
                <div class="grid gap-4 sm:grid-cols-3">
                  <Input
                    v-model="agencyPriceInput"
                    type="number"
                    min="1"
                    :label="$t('BILLING_SETTINGS.RESELLER.AGENCY_PRICE')"
                  />
                  <DetailItem
                    :label="
                      $t('BILLING_SETTINGS.RESELLER.COMMISSION', {
                        percent: commissionPercent,
                      })
                    "
                    :value="`$${platformFeeAmount}`"
                  />
                  <DetailItem
                    :label="$t('BILLING_SETTINGS.RESELLER.TOTAL_PRICE')"
                    :value="`$${totalClientPrice}`"
                  />
                </div>
                <RelayButton class="shadow-sm" @click="handleSavePricing">
                  {{ $t('BILLING_SETTINGS.RESELLER.SAVE_PRICING') }}
                </RelayButton>
              </template>
            </div>
          </BillingCard>
        </section>

        <!-- Direct Plan Selection Flow (Replaces Stripe Flows for Testing) -->
        <!-- Marketplace clients subscribe via their reseller's pricing above, not here. -->
        <section v-if="hasPendingEnterpriseInquiry" class="grid gap-6">
          <BillingCard
            :title="$t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.TITLE')"
            :description="
              $t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.PENDING_BANNER')
            "
          >
            <RelayButton
              variant="outline"
              size="sm"
              class="h-9"
              :is-loading="isCancelingEnterpriseInquiry"
              @click="onCancelEnterpriseInquiry"
            >
              {{ $t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.CANCEL_REQUEST') }}
            </RelayButton>
          </BillingCard>
        </section>
        <section class="grid gap-6">
          <BillingCard
            v-if="!hasResellerParent && (!planName || showPlanPicker)"
            :title="$t('BILLING_SETTINGS.SELECT_PLAN.TITLE')"
            :description="$t('BILLING_SETTINGS.SELECT_PLAN.DESCRIPTION')"
          >
            <template v-if="planName" #action>
              <RelayButton
                variant="outline"
                size="sm"
                class="h-9"
                @click="showPlanPicker = false"
              >
                {{ $t('BILLING_SETTINGS.SELECT_PLAN.CANCEL_BUTTON') }}
              </RelayButton>
            </template>
            <p
              v-if="lockedPaymentProvider"
              class="mb-2 text-xs text-muted-foreground"
            >
              {{
                $t('BILLING_SETTINGS.SELECT_PLAN.PROVIDER_LOCKED_HINT', {
                  provider: paymentProviderLabel,
                })
              }}
            </p>
            <div
              v-if="
                lockedPaymentProvider === 'razorpay' && hasActiveSubscription
              "
              class="mb-4"
            >
              <RelayButton
                variant="outline"
                size="sm"
                class="h-9 text-destructive hover:bg-destructive/10 hover:text-destructive hover:border-destructive/30"
                :is-loading="isCancelingSubscription"
                @click="onCancelRazorpaySubscription"
              >
                {{
                  $t('BILLING_SETTINGS.SELECT_PLAN.CANCEL_SUBSCRIPTION_BUTTON')
                }}
              </RelayButton>
            </div>
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-2">
              <div
                v-for="plan in selectablePlans"
                :key="plan"
                class="flex flex-col justify-between gap-6 rounded-xl border border-border/60 bg-card p-6 shadow-xs relative"
              >
                <div class="flex items-start justify-between w-full">
                  <div>
                    <h3 class="text-sm font-semibold text-foreground">
                      {{
                        $t('BILLING_SETTINGS.SELECT_PLAN.PLAN_LABEL', { plan })
                      }}
                    </h3>
                    <div class="mt-2 flex items-baseline gap-1 text-foreground">
                      <span class="text-[27px] font-semibold tracking-tight">
                        {{ formatPlanPrice(plan).amount }}
                      </span>
                      <span class="text-xs text-muted-foreground">
                        {{ formatPlanPrice(plan).suffix }}
                      </span>
                    </div>
                  </div>
                  <div class="flex flex-col gap-1 items-end">
                    <span
                      v-if="plan === 'Standard'"
                      class="rounded-md bg-primary/10 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-primary"
                    >
                      {{ $t('BILLING_SETTINGS.SELECT_PLAN.POPULAR') }}
                    </span>
                    <span
                      v-if="plan === planName"
                      class="rounded-md bg-muted px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground"
                    >
                      {{ $t('BILLING_SETTINGS.SELECT_PLAN.CURRENT') }}
                    </span>
                  </div>
                </div>
                <RelayButton
                  :variant="plan === 'Standard' ? 'default' : 'outline'"
                  class="w-full justify-center h-10 text-sm font-medium"
                  :class="plan === 'Standard' ? 'shadow-sm' : ''"
                  :is-loading="plan !== 'Enterprise' && isCheckingOut"
                  @click="handlePlanSelection(plan)"
                >
                  {{
                    plan === 'Enterprise'
                      ? $t('BILLING_SETTINGS.SELECT_PLAN.CONTACT_SALES_BUTTON')
                      : $t('BILLING_SETTINGS.SELECT_PLAN.SELECT_BUTTON')
                  }}
                </RelayButton>
              </div>
            </div>
          </BillingCard>

          <!-- Current Plan (new-ui hero layout) -->
          <BillingCard
            v-if="!hasResellerParent && planName"
            variant="hero"
            :title="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
          >
            <template #action>
              <!-- If collapsed, show 'View Plan Details' dropdown button -->
              <RelayButton
                v-if="!showPlanDetails"
                variant="outline"
                class="gap-1.5 font-medium h-9 text-sm"
                @click="showPlanDetails = true"
              >
                {{ $t('BILLING_SETTINGS.CURRENT_PLAN.VIEW_PLAN_DETAILS') }}
                <span class="i-lucide-chevron-down size-4" />
              </RelayButton>

              <!-- If expanded, show action buttons (Cancel subscription, Change plan) -->
              <div v-else class="flex items-center gap-3">
                <RelayButton
                  v-if="usesStripePortal && accountSubscription"
                  variant="outline"
                  size="sm"
                  class="h-9"
                  @click="onClickBillingPortal"
                >
                  {{ $t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT') }}
                </RelayButton>
                <RelayButton
                  v-if="usesRazorpayBilling && hasActiveSubscription"
                  variant="outline"
                  size="sm"
                  class="h-9 text-destructive hover:bg-destructive/10 hover:text-destructive hover:border-destructive/30"
                  :is-loading="isCancelingSubscription"
                  @click="onCancelRazorpaySubscription"
                >
                  {{
                    $t(
                      'BILLING_SETTINGS.SELECT_PLAN.CANCEL_SUBSCRIPTION_BUTTON'
                    )
                  }}
                </RelayButton>
                <RelayButton
                  size="sm"
                  class="h-9 shadow-sm"
                  @click="showPlanPicker = true"
                >
                  {{ $t('BILLING_SETTINGS.CURRENT_PLAN.CHANGE_PLAN_BUTTON') }}
                </RelayButton>
              </div>
            </template>

            <div>
              <div class="mb-4 flex flex-wrap items-center gap-3">
                <h2
                  class="text-[27px] font-semibold tracking-tight text-foreground"
                >
                  {{ planName }}
                </h2>
                <div
                  v-if="isSubscriptionActiveBadge"
                  class="rounded-lg bg-primary/10 px-3 py-1 text-[13px] font-semibold leading-none text-primary"
                >
                  {{ subscriptionStatusLabel }}
                </div>
                <div
                  v-else-if="accountSubscription"
                  class="rounded-lg bg-muted px-3 py-1 text-[13px] font-semibold leading-none text-muted-foreground"
                >
                  {{ subscriptionStatusLabel }}
                </div>
              </div>

              <div
                v-if="subscriptionPeriodEndValue !== '—'"
                class="flex flex-wrap items-center gap-1.5 text-[14px] font-medium text-muted-foreground"
              >
                <span>{{ subscriptionPeriodEndLabel }}</span>
                <span
                  class="i-lucide-calendar mx-0.5 size-4 text-muted-foreground"
                />
                <span class="font-semibold text-foreground">
                  {{ subscriptionPeriodEndValue }}
                </span>
                <template v-if="accountSubscription">
                  <span class="mx-1.5 text-border">•</span>
                  <span>{{
                    $t('BILLING_SETTINGS.CURRENT_PLAN.AUTO_RENEW')
                  }}</span>
                  <div
                    class="ml-0.5 rounded-md px-2 py-0.5 text-[12px] font-semibold leading-none"
                    :class="
                      isAutoRenewOn
                        ? 'bg-primary/10 text-primary'
                        : 'bg-muted text-muted-foreground'
                    "
                  >
                    {{
                      isAutoRenewOn
                        ? $t('BILLING_SETTINGS.CURRENT_PLAN.AUTO_RENEW_ON')
                        : $t('BILLING_SETTINGS.CURRENT_PLAN.AUTO_RENEW_OFF')
                    }}
                  </div>
                </template>
              </div>

              <p
                v-if="cancellationScheduledLabel"
                class="mt-3 text-sm text-amber-600"
              >
                {{ cancellationScheduledLabel }}
              </p>
              <p
                v-if="isSubscriptionPaymentPending"
                class="mt-3 text-sm text-destructive"
              >
                {{ $t('BILLING_SETTINGS.SUBSCRIPTION.PAYMENT_FAILED_HINT') }}
              </p>
            </div>

            <div v-if="showPlanDetails" class="mt-4 space-y-4">
              <div class="grid grid-cols-2 gap-4 sm:grid-cols-4">
                <DetailItem
                  :label="$t('BILLING_SETTINGS.SUBSCRIPTION.PLAN_PRICE')"
                  :value="currentPlanPriceLabel"
                />
                <DetailItem
                  :label="$t('BILLING_SETTINGS.SUBSCRIPTION.PAYMENT_PROVIDER')"
                  :value="paymentProviderDisplay"
                />
                <DetailItem
                  :label="$t('BILLING_SETTINGS.SUBSCRIPTION.PERIOD_START')"
                  :value="subscriptionPeriodStartValue"
                />
                <DetailItem
                  :label="
                    $t('BILLING_SETTINGS.CURRENT_PLAN.DATA_RETENTION_LABEL')
                  "
                  :value="dataRetentionLabel"
                />
              </div>

              <button
                type="button"
                class="flex items-center text-xs font-medium text-muted-foreground hover:text-foreground gap-1 transition-colors"
                @click="showPlanDetails = false"
              >
                <span class="i-lucide-chevron-up size-4" />
                {{ $t('BILLING_SETTINGS.CURRENT_PLAN.HIDE_PLAN_DETAILS') }}
              </button>
            </div>
          </BillingCard>

          <!-- Resource Limits -->
          <BillingCard
            v-if="hasABillingPlan"
            :title="$t('BILLING_SETTINGS.RESOURCE_LIMITS.TITLE')"
            :description="$t('BILLING_SETTINGS.RESOURCE_LIMITS.DESCRIPTION')"
          >
            <div class="flex flex-col gap-1">
              <BillingMeter
                v-if="agentLimits"
                icon="i-lucide-users"
                :title="$t('BILLING_SETTINGS.RESOURCE_LIMITS.SEATS')"
                v-bind="agentLimits"
              />
              <BillingMeter
                v-if="inboxLimits"
                icon="i-lucide-inbox"
                :title="$t('BILLING_SETTINGS.RESOURCE_LIMITS.INBOXES')"
                v-bind="inboxLimits"
              />
              <BillingMeter
                v-if="contactLimits"
                icon="i-lucide-users-round"
                :title="$t('BILLING_SETTINGS.RESOURCE_LIMITS.CONTACTS')"
                v-bind="contactLimits"
              />
              <BillingMeter
                v-if="conversationLimits"
                icon="i-lucide-message-square"
                :title="$t('BILLING_SETTINGS.RESOURCE_LIMITS.CONVERSATIONS')"
                v-bind="conversationLimits"
              />
              <BillingMeter
                v-if="t3SubaccountLimits"
                icon="i-lucide-network"
                :title="$t('BILLING_SETTINGS.RESOURCE_LIMITS.T3_SUBACCOUNTS')"
                v-bind="t3SubaccountLimits"
              />
              <BillingMeter
                v-if="automationLimits"
                icon="i-lucide-zap"
                :title="$t('BILLING_SETTINGS.RESOURCE_LIMITS.AUTOMATIONS')"
                v-bind="automationLimits"
              />
            </div>
          </BillingCard>

          <!-- Captain AI Billing -->
          <BillingCard
            v-if="captainEnabled"
            :title="$t('BILLING_SETTINGS.CAPTAIN.TITLE')"
            :description="$t('BILLING_SETTINGS.CAPTAIN.DESCRIPTION')"
          >
            <template #action>
              <div class="flex flex-wrap items-center gap-3">
                <RelayButton
                  variant="outline"
                  size="sm"
                  class="h-9 px-4 text-[14px] font-medium"
                  :disabled="isFetchingLimits"
                  @click="fetchLimits"
                >
                  <span class="i-lucide-refresh-cw size-4" />
                  {{ $t('BILLING_SETTINGS.CAPTAIN.REFRESH_CREDITS') }}
                </RelayButton>
                <RelayButton
                  v-if="canPurchaseCredits"
                  size="sm"
                  class="h-9 px-4 text-[14px] font-medium shadow-sm"
                  @click="openPurchaseCreditsModal"
                >
                  {{ $t('BILLING_SETTINGS.TOPUP.BUY_CREDITS') }}
                </RelayButton>
              </div>
            </template>
            <div class="flex flex-col gap-1">
              <BillingMeter
                v-if="captainLimits && responseLimits"
                icon="i-lucide-coins"
                :title="$t('BILLING_SETTINGS.CAPTAIN.RESPONSES')"
                v-bind="responseLimits"
              />
              <BillingMeter
                v-if="captainLimits && documentLimits"
                icon="i-lucide-file-text"
                :title="$t('BILLING_SETTINGS.CAPTAIN.DOCUMENTS')"
                v-bind="documentLimits"
              />
            </div>
          </BillingCard>

          <BillingCard
            v-else
            :title="$t('BILLING_SETTINGS.CAPTAIN.TITLE')"
            :description="$t('BILLING_SETTINGS.CAPTAIN.UPGRADE')"
          >
            <template #action>
              <RelayButton
                variant="outline"
                size="sm"
                @click="onClickCaptainUpgrade"
              >
                {{ $t('CAPTAIN.PAYWALL.UPGRADE_NOW') }}
              </RelayButton>
            </template>
          </BillingCard>

          <!-- Payment History -->
          <BillingCard
            v-if="hasABillingPlan"
            :title="$t('BILLING_SETTINGS.TRANSACTIONS.TITLE')"
            :description="$t('BILLING_SETTINGS.TRANSACTIONS.DESCRIPTION')"
          >
            <div class="overflow-x-auto">
              <p
                v-if="isFetchingTransactions"
                class="py-2 text-sm text-muted-foreground"
              >
                {{ $t('BILLING_SETTINGS.TRANSACTIONS.LOADING') }}
              </p>
              <p
                v-else-if="!transactions.length"
                class="py-2 text-sm text-muted-foreground"
              >
                {{ $t('BILLING_SETTINGS.TRANSACTIONS.EMPTY') }}
              </p>
              <table v-else class="w-full text-sm">
                <thead>
                  <tr
                    class="border-b border-border/40 text-left text-muted-foreground"
                  >
                    <th
                      class="py-2 pr-4 text-[11px] font-semibold uppercase tracking-wider"
                    >
                      {{ $t('BILLING_SETTINGS.TRANSACTIONS.DATE') }}
                    </th>
                    <th
                      class="py-2 pr-4 text-[11px] font-semibold uppercase tracking-wider"
                    >
                      {{ $t('BILLING_SETTINGS.TRANSACTIONS.DESCRIPTION_COL') }}
                    </th>
                    <th
                      class="py-2 pr-4 text-[11px] font-semibold uppercase tracking-wider"
                    >
                      {{ $t('BILLING_SETTINGS.TRANSACTIONS.AMOUNT') }}
                    </th>
                    <th
                      class="py-2 pr-4 text-[11px] font-semibold uppercase tracking-wider"
                    >
                      {{ $t('BILLING_SETTINGS.TRANSACTIONS.STATUS') }}
                    </th>
                    <th
                      class="py-2 text-[11px] font-semibold uppercase tracking-wider"
                    >
                      {{ $t('BILLING_SETTINGS.TRANSACTIONS.RECEIPT') }}
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="transaction in transactions"
                    :key="transaction.id"
                    class="border-b border-border/40 last:border-0"
                  >
                    <td class="whitespace-nowrap py-3 pr-4 text-foreground">
                      {{
                        formatTransactionDate(
                          transaction.paid_at || transaction.created_at
                        )
                      }}
                    </td>
                    <td class="py-3 pr-4 text-foreground">
                      {{ transaction.description || '—' }}
                    </td>
                    <td class="whitespace-nowrap py-3 pr-4 text-foreground">
                      {{ formatTransactionAmount(transaction) }}
                    </td>
                    <td class="py-3 pr-4">
                      <span
                        class="rounded-md px-2 py-0.5 text-xs font-medium"
                        :class="
                          transaction.status === 'succeeded'
                            ? 'bg-primary/10 text-primary'
                            : 'bg-destructive/10 text-destructive'
                        "
                      >
                        {{
                          transaction.status === 'succeeded'
                            ? $t(
                                'BILLING_SETTINGS.TRANSACTIONS.STATUS_SUCCEEDED'
                              )
                            : $t('BILLING_SETTINGS.TRANSACTIONS.STATUS_FAILED')
                        }}
                      </span>
                    </td>
                    <td class="py-3">
                      <a
                        v-if="transaction.hosted_invoice_url"
                        :href="transaction.hosted_invoice_url"
                        target="_blank"
                        rel="noopener noreferrer"
                        class="text-primary hover:underline"
                      >
                        {{ $t('BILLING_SETTINGS.TRANSACTIONS.VIEW') }}
                      </a>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </BillingCard>

          <div
            class="flex flex-col justify-between gap-4 py-4 sm:flex-row sm:items-center"
          >
            <div>
              <h3 class="text-base font-medium text-foreground">
                {{ $t('BILLING_SETTINGS.CHAT_WITH_US.TITLE') }}
              </h3>
              <p class="mt-1 text-sm text-muted-foreground">
                {{ $t('BILLING_SETTINGS.CHAT_WITH_US.DESCRIPTION') }}
              </p>
            </div>
            <RelayButton variant="outline" @click="onToggleChatWindow">
              <span class="i-lucide-message-square size-4" />
              {{ $t('BILLING_SETTINGS.CHAT_WITH_US.BUTTON_TXT') }}
            </RelayButton>
          </div>
        </section>

        <PurchaseCreditsModal
          ref="purchaseCreditsModalRef"
          :payment-provider="topupPaymentProvider"
        />
        <EnterpriseInquiryModal
          ref="enterpriseInquiryModalRef"
          @success="handleEnterpriseInquirySuccess"
        />
        <DowngradePlanWarningModal
          ref="downgradeWarningModalRef"
          @confirm="handleDowngradeConfirm"
        />
        <PlanCheckoutModal
          ref="planCheckoutModalRef"
          :show-country-select="showBillingCountrySelect"
          :locked-payment-provider="lockedPaymentProvider"
          :initial-country="billingCountry"
          :country-options="availableCountryOptions"
          :payment-gateways="paymentGateways"
          @proceed="handlePlanCheckoutProceed"
        />
      </div>
    </template>
  </SettingsLayout>
</template>
