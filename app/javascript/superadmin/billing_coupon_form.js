// Billing coupon Super Admin form: toggle percent vs amount fields.
window.toggleBillingCouponDiscountFields =
  function toggleBillingCouponDiscountFields(value) {
    const percentFields = document.getElementById(
      'billing-coupon-percent-fields'
    );
    const amountFields = document.getElementById(
      'billing-coupon-amount-fields'
    );
    if (!percentFields || !amountFields) return;

    const isAmount = value === 'amount';
    percentFields.classList.toggle('hidden', isAmount);
    amountFields.classList.toggle('hidden', !isAmount);
  };

document.addEventListener('DOMContentLoaded', () => {
  const select = document.getElementById('billing_coupon_discount_type');
  if (!select) return;

  select.addEventListener('change', event => {
    window.toggleBillingCouponDiscountFields(event.target.value);
  });

  window.toggleBillingCouponDiscountFields(select.value);
});
