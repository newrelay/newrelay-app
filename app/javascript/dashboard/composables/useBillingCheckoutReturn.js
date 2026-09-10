import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import EnterpriseAccountAPI from 'dashboard/api/enterprise/account';

const PLAN_READY_POLL_MS = 2000;
const PLAN_READY_ATTEMPTS = 10;
const PLAN_CHECKOUT_TYPES = ['plan_checkout', 'marketplace_checkout'];

export const accountHasActivePlan = account =>
  Boolean(
    account?.custom_attributes?.plan_name && account?.subscription?.active
  );

export const buildCheckoutReturnUrls = checkoutType => {
  const checkoutRef = crypto.randomUUID();
  const base = `${window.location.origin}${window.location.pathname}`;
  const sharedParams = new URLSearchParams({
    checkout_ref: checkoutRef,
    checkout_type: checkoutType,
  });

  return {
    successUrl: `${base}?checkout_return=success&checkout_session_id={CHECKOUT_SESSION_ID}&${sharedParams}`,
    cancelUrl: `${base}?checkout_return=cancel&${sharedParams}`,
    checkoutRef,
  };
};

export function useBillingCheckoutReturn() {
  const route = useRoute();
  const router = useRouter();
  const store = useStore();

  const waitForActivePlan = async () => {
    /* eslint-disable no-await-in-loop -- poll until the checkout webhook writes plan_name */
    for (let attempt = 0; attempt < PLAN_READY_ATTEMPTS; attempt += 1) {
      await store.dispatch('accounts/get', { silent: true });
      const accountId = store.getters.getCurrentAccountId;
      const account = store.getters['accounts/getAccount'](accountId);
      if (accountHasActivePlan(account)) return true;
      await new Promise(resolve => {
        setTimeout(resolve, PLAN_READY_POLL_MS);
      });
    }
    /* eslint-enable no-await-in-loop */
    return false;
  };

  const processCheckoutReturn = async () => {
    const returnType = route.query.checkout_return;
    const checkoutType = route.query.checkout_type;
    const checkoutRef = route.query.checkout_ref;
    const checkoutSessionId = route.query.checkout_session_id;
    if (!returnType || !checkoutType) return;

    try {
      await EnterpriseAccountAPI.recordCheckoutReturn({
        returnType,
        checkoutType,
        checkoutRef,
        checkoutSessionId,
      });
    } catch {
      // Non-fatal — billing page should still load normally.
    }

    if (
      returnType === 'success' &&
      PLAN_CHECKOUT_TYPES.includes(checkoutType)
    ) {
      await waitForActivePlan();
    }

    const query = { ...route.query };
    delete query.checkout_return;
    delete query.checkout_type;
    delete query.checkout_ref;
    delete query.checkout_session_id;
    router.replace({ query });
  };

  return {
    buildCheckoutReturnUrls,
    processCheckoutReturn,
  };
}
