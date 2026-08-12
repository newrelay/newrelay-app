import { useRoute, useRouter } from 'vue-router';
import EnterpriseAccountAPI from 'dashboard/api/enterprise/account';

export const buildCheckoutReturnUrls = checkoutType => {
  const checkoutRef = crypto.randomUUID();
  const base = `${window.location.origin}${window.location.pathname}`;
  const sharedParams = new URLSearchParams({
    checkout_ref: checkoutRef,
    checkout_type: checkoutType,
  });

  return {
    successUrl: `${base}?checkout_return=success&${sharedParams}`,
    cancelUrl: `${base}?checkout_return=cancel&${sharedParams}`,
    checkoutRef,
  };
};

export function useBillingCheckoutReturn() {
  const route = useRoute();
  const router = useRouter();

  const processCheckoutReturn = async () => {
    const returnType = route.query.checkout_return;
    const checkoutType = route.query.checkout_type;
    const checkoutRef = route.query.checkout_ref;
    if (!returnType || !checkoutType) return;

    try {
      await EnterpriseAccountAPI.recordCheckoutReturn({
        returnType,
        checkoutType,
        checkoutRef,
      });
    } catch {
      // Non-fatal — billing page should still load normally.
    }

    const query = { ...route.query };
    delete query.checkout_return;
    delete query.checkout_type;
    delete query.checkout_ref;
    router.replace({ query });
  };

  return {
    buildCheckoutReturnUrls,
    processCheckoutReturn,
  };
}
