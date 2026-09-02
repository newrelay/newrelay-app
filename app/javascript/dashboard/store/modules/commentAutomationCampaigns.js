import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import CommentAutomationCampaignsAPI from '../../api/commentAutomationCampaigns';
import { throwErrorMessage } from '../utils/api';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getCampaigns($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.SET_COMMENT_AUTOMATION_CAMPAIGNS_UI_FLAG, {
      isFetching: true,
    });
    try {
      const response = await CommentAutomationCampaignsAPI.get();
      commit(types.SET_COMMENT_AUTOMATION_CAMPAIGNS, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_COMMENT_AUTOMATION_CAMPAIGNS_UI_FLAG, {
        isFetching: false,
      });
    }
  },
  create: async ({ commit }, campaignObj) => {
    commit(types.SET_COMMENT_AUTOMATION_CAMPAIGNS_UI_FLAG, {
      isCreating: true,
    });
    try {
      const response = await CommentAutomationCampaignsAPI.create(campaignObj);
      commit(types.ADD_COMMENT_AUTOMATION_CAMPAIGN, response.data);
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      return null;
    } finally {
      commit(types.SET_COMMENT_AUTOMATION_CAMPAIGNS_UI_FLAG, {
        isCreating: false,
      });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_COMMENT_AUTOMATION_CAMPAIGNS_UI_FLAG, {
      isUpdating: true,
    });
    try {
      const response = await CommentAutomationCampaignsAPI.update(
        id,
        updateObj
      );
      commit(types.EDIT_COMMENT_AUTOMATION_CAMPAIGN, response.data);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_COMMENT_AUTOMATION_CAMPAIGNS_UI_FLAG, {
        isUpdating: false,
      });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_COMMENT_AUTOMATION_CAMPAIGNS_UI_FLAG, {
      isDeleting: true,
    });
    try {
      await CommentAutomationCampaignsAPI.delete(id);
      commit(types.DELETE_COMMENT_AUTOMATION_CAMPAIGN, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_COMMENT_AUTOMATION_CAMPAIGNS_UI_FLAG, {
        isDeleting: false,
      });
    }
  },
};

export const mutations = {
  [types.SET_COMMENT_AUTOMATION_CAMPAIGNS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.ADD_COMMENT_AUTOMATION_CAMPAIGN]: MutationHelpers.setSingleRecord,
  [types.SET_COMMENT_AUTOMATION_CAMPAIGNS]: MutationHelpers.set,
  [types.EDIT_COMMENT_AUTOMATION_CAMPAIGN]: MutationHelpers.update,
  [types.DELETE_COMMENT_AUTOMATION_CAMPAIGN]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
