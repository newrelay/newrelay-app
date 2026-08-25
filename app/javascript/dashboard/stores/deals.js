import camelcaseKeys from 'camelcase-keys';
import snakecaseKeys from 'snakecase-keys';
import DealAPI from 'dashboard/api/deals';
import { createStore } from 'dashboard/store/storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const camelize = data => camelcaseKeys(data || {}, { deep: true });

export const useDealsStore = createStore({
  name: 'deals',
  type: 'pinia',
  API: DealAPI,
  getters: {
    getDealsList: state => state.records,
  },
  actions: () => ({
    async get(params = {}) {
      this.setUIFlag({ fetchingList: true });
      try {
        const { data } = await DealAPI.get(params);
        this.records = (data.payload || []).map(camelize);
        return this.records;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ fetchingList: false });
      }
    },

    async create(attrs) {
      this.setUIFlag({ creatingItem: true });
      try {
        const { data } = await DealAPI.create(
          snakecaseKeys(attrs, { deep: true })
        );
        const record = camelize(data.payload || data);
        this.records.unshift(record);
        return record;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ creatingItem: false });
      }
    },

    async update({ id, ...attrs }) {
      this.setUIFlag({ updatingItem: true });
      try {
        const { data } = await DealAPI.update(
          id,
          snakecaseKeys(attrs, { deep: true })
        );
        const record = camelize(data.payload || data);
        const index = this.records.findIndex(item => item.id === record.id);
        if (index !== -1) this.records[index] = record;
        else this.records.unshift(record);
        return record;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ updatingItem: false });
      }
    },

    async delete(id) {
      this.setUIFlag({ deletingItem: true });
      try {
        await DealAPI.delete(id);
        this.records = this.records.filter(item => item.id !== Number(id));
        return id;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ deletingItem: false });
      }
    },
  }),
});
