import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useDealsStore } from 'dashboard/stores/deals';
import { usePipelinesStore } from 'dashboard/stores/pipelines';

export const useCrmPipeline = () => {
  const { t } = useI18n();
  const dealsStore = useDealsStore();
  const pipelinesStore = usePipelinesStore();

  const selectedDeal = ref(null);
  const dealToDelete = ref(null);
  const showDeleteConfirm = ref(false);
  const formDialogRef = ref(null);
  const searchQuery = ref('');

  const deals = computed(() => dealsStore.getDealsList);
  const uiFlags = computed(() => dealsStore.getUIFlags);
  const pipeline = computed(() => pipelinesStore.getDefaultPipeline);
  const stages = computed(() => pipeline.value?.stages || []);

  const filteredDeals = computed(() => {
    const query = searchQuery.value.trim().toLowerCase();
    if (!query) return deals.value;
    return deals.value.filter(deal =>
      [deal.name, deal.pipelineStage?.name, deal.priority]
        .filter(Boolean)
        .some(value => String(value).toLowerCase().includes(query))
    );
  });

  const formatAmount = (amountCents, currency = 'USD') => {
    const amount = Number(amountCents || 0) / 100;
    try {
      return new Intl.NumberFormat(undefined, {
        style: 'currency',
        currency: currency || 'USD',
        maximumFractionDigits: 0,
      }).format(amount);
    } catch {
      return `$${amount.toFixed(0)}`;
    }
  };

  const formatDealAmount = deal =>
    formatAmount(deal.amountCents, deal.currency);

  const formatDate = value => {
    if (!value) return '—';
    return new Date(value).toLocaleDateString();
  };

  const metrics = computed(() => {
    const list = deals.value || [];
    const currency = list[0]?.currency || 'USD';
    const totalDeals = list.length;
    const pipelineValue = list.reduce(
      (sum, deal) => sum + Number(deal.amountCents || 0),
      0
    );
    const weightedValue = list.reduce((sum, deal) => {
      const probability = Number(deal.probability || 0) / 100;
      return sum + Number(deal.amountCents || 0) * probability;
    }, 0);
    const avgDealValue = totalDeals ? pipelineValue / totalDeals : 0;
    const won = list.filter(deal => deal.pipelineStage?.isWon).length;
    const lost = list.filter(deal => deal.pipelineStage?.isLost).length;
    const closed = won + lost;
    const winRate = closed ? Math.round((won / closed) * 100) : 0;

    return [
      {
        key: 'total',
        label: t('DEALS.METRICS.TOTAL'),
        value: String(totalDeals),
      },
      {
        key: 'pipeline',
        label: t('DEALS.METRICS.PIPELINE_VALUE'),
        value: formatAmount(pipelineValue, currency),
      },
      {
        key: 'weighted',
        label: t('DEALS.METRICS.WEIGHTED_VALUE'),
        value: formatAmount(weightedValue, currency),
      },
      {
        key: 'avg',
        label: t('DEALS.METRICS.AVG_DEAL'),
        value: formatAmount(avgDealValue, currency),
      },
      {
        key: 'win',
        label: t('DEALS.METRICS.WIN_RATE'),
        value: `${winRate}%`,
      },
    ];
  });

  const load = async () => {
    await pipelinesStore.get();
    await dealsStore.get(
      pipeline.value?.id ? { pipeline_id: pipeline.value.id } : {}
    );
  };

  const openCreate = () => {
    selectedDeal.value = null;
    formDialogRef.value?.open();
  };

  const openEdit = deal => {
    selectedDeal.value = deal;
    formDialogRef.value?.open(deal);
  };

  const submitDeal = async payload => {
    try {
      const body = {
        ...payload,
        pipelineId: pipeline.value.id,
      };
      if (selectedDeal.value?.id) {
        await dealsStore.update({ id: selectedDeal.value.id, ...body });
        useAlert(t('DEALS.API.UPDATE_SUCCESS'));
      } else {
        await dealsStore.create(body);
        useAlert(t('DEALS.API.CREATE_SUCCESS'));
      }
      formDialogRef.value?.onSuccess();
      selectedDeal.value = null;
    } catch (error) {
      useAlert(error?.message || t('DEALS.API.ERROR'));
    }
  };

  const confirmDelete = deal => {
    dealToDelete.value = deal;
    showDeleteConfirm.value = true;
  };

  const deleteDeal = async () => {
    try {
      await dealsStore.delete(dealToDelete.value.id);
      useAlert(t('DEALS.API.DELETE_SUCCESS'));
    } catch (error) {
      useAlert(error?.message || t('DEALS.API.ERROR'));
    } finally {
      showDeleteConfirm.value = false;
      dealToDelete.value = null;
    }
  };

  const moveDealToStage = async (deal, stageId) => {
    if (!deal || deal.pipelineStageId === stageId) return;
    try {
      await dealsStore.update({
        id: deal.id,
        pipelineId: pipeline.value.id,
        pipelineStageId: stageId,
      });
    } catch (error) {
      useAlert(error?.message || t('DEALS.API.ERROR'));
      await load();
    }
  };

  return {
    dealsStore,
    pipelinesStore,
    selectedDeal,
    dealToDelete,
    showDeleteConfirm,
    formDialogRef,
    searchQuery,
    deals,
    uiFlags,
    pipeline,
    stages,
    filteredDeals,
    metrics,
    formatDealAmount,
    formatAmount,
    formatDate,
    load,
    openCreate,
    openEdit,
    submitDeal,
    confirmDelete,
    deleteDeal,
    moveDealToStage,
  };
};
