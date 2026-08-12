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

  const userAccount = accounts.find(a => a.id === routeAccountId) || accounts[0];
  const isAdmin = userAccount?.role === 'administrator';
  const isActive = userAccount?.status === 'active';
  const needsOnboarding =
    ONBOARDING_STEPS.includes(userAccount?.onboarding_step) &&
    isAdmin &&
    isActive;

  if (to.name === 'no_accounts' || !to.name) {
    const target = needsOnboarding ? 'onboarding' : 'dashboard';
    return next(frontendURL(`accounts/${routeAccountId}/${target}`));
  }

  if (needsOnboarding && !isOnOnboardingView(to)) {
    return next(frontendURL(`accounts/${routeAccountId}/onboarding`));
  }
  if (!needsOnboarding && isOnOnboardingView(to)) {
    return next(frontendURL(`accounts/${routeAccountId}/dashboard`));
  }

  const nextRoute = validateLoggedInRoutes(to, user);
  return nextRoute ? next(frontendURL(nextRoute)) : next();
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
