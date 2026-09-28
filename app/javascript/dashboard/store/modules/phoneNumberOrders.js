import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import NumberProvisioningOrdersAPI from '../../api/numberProvisioningOrders';

export const state = {
  records: [],
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
};

export const actions = {
  get: async function getPhoneNumberOrders({ commit }) {
    commit(types.SET_PHONE_NUMBER_ORDER_UI_FLAG, { isFetching: true });
    try {
      const response = await NumberProvisioningOrdersAPI.get();
      commit(types.SET_PHONE_NUMBER_ORDERS, response.data);
    } finally {
      commit(types.SET_PHONE_NUMBER_ORDER_UI_FLAG, { isFetching: false });
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
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
