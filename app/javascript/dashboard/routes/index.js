import { createRouter, createWebHistory } from 'vue-router';

import { frontendURL } from '../helper/URLHelper';
import dashboard from './dashboard/dashboard.routes';
import store from 'dashboard/store';
import { validateLoggedInRoutes } from '../helper/routeHelpers';
import { isOnOnboardingView } from 'v3/helpers/RouteHelper';
import AnalyticsHelper from '../helper/AnalyticsHelper';

const ONBOARDING_STEPS = ['account_details', 'enrichment'];
const routes = [...dashboard.routes];

export const router = createRouter({ history: createWebHistory(), routes });

const settingsHomeDestination = to => {
  const accountId = Number(to.params.accountId);
  const accounts = store.getters.getCurrentUser?.accounts || [];
  const currentAccount = accounts.find(
    account => Number(account.id) === accountId
  );
  const isAdmin =
    currentAccount?.role === 'administrator' &&
    currentAccount.custom_role_id == null;

  return {
    name: isAdmin ? 'general_settings_index' : 'canned_list',
    params: { accountId: to.params.accountId },
  };
};

export const validateAuthenticateRoutePermission = async (to, next) => {
  let user = store.getters.getCurrentUser;

  // Re-verify authentication state if user state is uninitialized or stale
  if (!store.getters.isLoggedIn || !user || !user.id) {
    try {
      await store.dispatch('setUser');
      user = store.getters.getCurrentUser;
    } catch (error) {
      window.location.assign('/app/login');
      return next(false);
    }
  }

  if (!store.getters.isLoggedIn || !user) {
    window.location.assign('/app/login');
    return next(false);
  }

  if (to.name === 'settings_home') {
    return next(settingsHomeDestination(to));
  }

  const { accounts = [], account_id: accountId } = user;

  if (!accounts.length) {
    if (to.name === 'no_accounts') {
      return next();
    }
    return next(frontendURL('no-accounts'));
  }

  // Safely resolve routeAccountId: fallback to user account_id or first account ID (avoids NaN)
  const paramAccountId = Number(to.params?.accountId);
  const routeAccountId =
    !Number.isNaN(paramAccountId) && paramAccountId > 0
      ? paramAccountId
      : Number(accountId) || accounts[0]?.id;

  const userAccount =
    accounts.find(a => a.id === routeAccountId) || accounts[0];
  const isAdmin = userAccount?.role === 'administrator';
  const isActive = userAccount?.status === 'active';
  const needsOnboarding =
    ONBOARDING_STEPS.includes(userAccount?.onboarding_step) &&
    isAdmin &&
    isActive;

  if (to.name === 'no_accounts' || !to.name) {
    const target = needsOnboarding ? 'onboarding' : 'dashboard';
    const targetUrl = frontendURL(`accounts/${routeAccountId}/${target}`);
    if (to.path === targetUrl) {
      return next();
    }
    return next(targetUrl);
  }

  if (needsOnboarding && !isOnOnboardingView(to)) {
    const onboardingUrl = frontendURL(`accounts/${routeAccountId}/onboarding`);
    if (to.path === onboardingUrl) {
      return next();
    }
    return next(onboardingUrl);
  }
  if (!needsOnboarding && isOnOnboardingView(to)) {
    const dashboardUrl = frontendURL(`accounts/${routeAccountId}/dashboard`);
    if (to.path === dashboardUrl) {
      return next();
    }
    return next(dashboardUrl);
  }

  const nextRoute = validateLoggedInRoutes(to, user);
  if (nextRoute) {
    const targetUrl = frontendURL(nextRoute);
    if (to.path === targetUrl) {
      return next();
    }
    return next(targetUrl);
  }
  return next();
};

export const initalizeRouter = () => {
  const userAuthentication = store.dispatch('setUser');

  router.beforeEach(async (to, _from, next) => {
    AnalyticsHelper.page(to.name || '', {
      path: to.path,
      name: to.name,
    });

    await userAuthentication;
    await validateAuthenticateRoutePermission(to, next, store);
  });
};

export default router;
