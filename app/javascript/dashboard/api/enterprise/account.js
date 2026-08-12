/* global axios */
import ApiClient from '../ApiClient';

class EnterpriseAccountAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true, enterprise: true });
  }

  checkout() {
    return axios.post(`${this.url}checkout`);
  }

  subscription() {
    return axios.post(`${this.url}subscription`);
  }

  getLimits() {
    return axios.get(`${this.url}limits`);
  }

  toggleDeletion(action) {
    return axios.post(`${this.url}toggle_deletion`, {
      action_type: action,
    });
  }

  createTopupCheckout(credits, { successUrl, cancelUrl } = {}) {
    return axios.post(`${this.url}topup_checkout`, {
      credits,
      success_url: successUrl,
      cancel_url: cancelUrl,
    });
  }

  submitEnterpriseInquiry(inquiry) {
    return axios.post(`${this.url}enterprise_inquiry`, inquiry);
  }

  cancelEnterpriseInquiry() {
    return axios.post(`${this.url}cancel_enterprise_inquiry`);
  }

  getTransactions() {
    return axios.get(`${this.url}transactions`);
  }

  getPlans() {
    return axios.get(`${this.url}plans`);
  }

  cancelSubscription({ cancelAtCycleEnd = true } = {}) {
    return axios.post(`${this.url}cancel_subscription`, {
      cancel_at_cycle_end: cancelAtCycleEnd,
    });
  }

  validatePlanCoupon({ planName, country, couponCode } = {}) {
    return axios.post(`${this.url}validate_coupon`, {
      plan_name: planName,
      country,
      coupon_code: couponCode,
    });
  }

  recordCheckoutReturn({ returnType, checkoutType, checkoutRef } = {}) {
    return axios.post(`${this.url}checkout_return`, {
      return_type: returnType,
      checkout_type: checkoutType,
      checkout_ref: checkoutRef,
    });
  }

  planCheckout({ planName, country, couponCode, successUrl, cancelUrl } = {}) {
    return axios.post(`${this.url}plan_checkout`, {
      plan_name: planName,
      country,
      coupon_code: couponCode,
      success_url: successUrl,
      cancel_url: cancelUrl,
    });
  }
}

export default new EnterpriseAccountAPI();
