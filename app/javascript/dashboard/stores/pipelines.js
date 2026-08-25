import camelcaseKeys from 'camelcase-keys';
import PipelineAPI from 'dashboard/api/pipelines';
import { createStore } from 'dashboard/store/storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const camelize = data => camelcaseKeys(data || {}, { deep: true });

export const usePipelinesStore = createStore({
  name: 'pipelines',
  type: 'pinia',
  API: PipelineAPI,
  getters: {
    getPipelinesList: state => state.records,
    getDefaultPipeline: state => state.records[0] || null,
  },
  actions: () => ({
    async get(params = {}) {
      this.setUIFlag({ fetchingList: true });
      try {
        const { data } = await PipelineAPI.get(params);
        this.records = (data.payload || []).map(camelize);
        return this.records;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ fetchingList: false });
      }
    },
  }),
});
