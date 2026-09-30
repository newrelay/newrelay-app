import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import NumberProvisioningOrdersAPI from '../../api/numberProvisioningOrders';

export const state = {
  records: [],
  providers: {
    telnyx: false,
    exotel: false,
  },
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isSearchingNumbers: false,
  },
};

export const getters = {
  getOrders(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getProviders(_state) {
    return _state.providers;
  },
};

export const actions = {
  get: async function getPhoneNumberOrders({ commit }, { silent } = {}) {
    if (!silent) {
      commit(types.SET_PHONE_NUMBER_ORDER_UI_FLAG, { isFetching: true });
    }
    try {
      const response = await NumberProvisioningOrdersAPI.get();
      commit(types.SET_PHONE_NUMBER_ORDERS, response.data);
    } finally {
      if (!silent) {
        commit(types.SET_PHONE_NUMBER_ORDER_UI_FLAG, { isFetching: false });
      }
    }
  },

  search: async function searchPhoneNumbers({ commit }, { countryCode, type }) {
    commit(types.SET_PHONE_NUMBER_ORDER_UI_FLAG, { isSearchingNumbers: true });
    try {
      // orders#search renders `json.array! @results` -- a bare array, not { data }.
      const response = await NumberProvisioningOrdersAPI.search({
        countryCode,
        type,
      });
      return response.data;
    } finally {
      commit(types.SET_PHONE_NUMBER_ORDER_UI_FLAG, {
        isSearchingNumbers: false,
      });
    }
  },

  fetchConfig: async function fetchNumberProvisioningConfig({ commit }) {
    try {
      const response = await NumberProvisioningOrdersAPI.getConfig();
      commit(
        'globalConfig/SET_NUMBER_PROVISIONING_ENABLED',
        response.data.enabled,
        { root: true }
      );
      commit(types.SET_PHONE_NUMBER_PROVIDERS, response.data.providers || {});
    } catch {
      // silently ignore -- the window.globalConfig value at page load remains authoritative
    }
  },

  create: async function createPhoneNumberOrder(
    { commit },
    { idempotencyKey, ...params }
  ) {
    commit(types.SET_PHONE_NUMBER_ORDER_UI_FLAG, { isCreating: true });
    try {
      const response = await NumberProvisioningOrdersAPI.create(
        params,
        idempotencyKey
      );
      commit(types.ADD_PHONE_NUMBER_ORDER, response.data);
      return response.data;
    } finally {
      commit(types.SET_PHONE_NUMBER_ORDER_UI_FLAG, { isCreating: false });
    }
  },

  submitRequirements: async function submitPhoneNumberRequirements(
    { commit },
    { orderId, file }
  ) {
    commit(types.SET_PHONE_NUMBER_ORDER_UI_FLAG, { isCreating: true });
    try {
      const response = await NumberProvisioningOrdersAPI.submitRequirements(
        orderId,
        file
      );
      commit(types.UPDATE_PHONE_NUMBER_ORDER, response.data);
      return response.data;
    } finally {
      commit(types.SET_PHONE_NUMBER_ORDER_UI_FLAG, { isCreating: false });
    }
  },

  connectVoiceAgent: async function connectVoiceAgent({ commit }, orderId) {
    const response =
      await NumberProvisioningOrdersAPI.connectVoiceAgent(orderId);
    commit(types.UPDATE_PHONE_NUMBER_ORDER, response.data);
    return response.data;
  },
};

export const mutations = {
  [types.SET_PHONE_NUMBER_ORDER_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_PHONE_NUMBER_ORDERS]: MutationHelpers.set,
  [types.ADD_PHONE_NUMBER_ORDER]: MutationHelpers.create,
  [types.UPDATE_PHONE_NUMBER_ORDER]: MutationHelpers.update,
  [types.SET_PHONE_NUMBER_PROVIDERS](_state, providers) {
    _state.providers = {
      telnyx: false,
      exotel: false,
      ...providers,
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
