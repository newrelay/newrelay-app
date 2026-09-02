import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import CommentAutomationMessageLogsAPI from '../../api/commentAutomationMessageLogs';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
  },
};

export const getters = {
  getMessageLogs($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.SET_COMMENT_AUTOMATION_MESSAGE_LOGS_UI_FLAG, {
      isFetching: true,
    });
    try {
      const response = await CommentAutomationMessageLogsAPI.get();
      commit(types.SET_COMMENT_AUTOMATION_MESSAGE_LOGS, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_COMMENT_AUTOMATION_MESSAGE_LOGS_UI_FLAG, {
        isFetching: false,
      });
    }
  },
};

export const mutations = {
  [types.SET_COMMENT_AUTOMATION_MESSAGE_LOGS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.SET_COMMENT_AUTOMATION_MESSAGE_LOGS]: MutationHelpers.set,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
