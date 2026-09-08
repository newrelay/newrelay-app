import { computed, ref } from 'vue';
import { formatDistanceToNow } from 'date-fns';
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

  const formatRelative = value => {
    if (!value) return '—';
    const date =
      typeof value === 'number' && value < 1e12
        ? new Date(value * 1000)
        : new Date(value);
    if (Number.isNaN(date.getTime())) return '—';
    return formatDistanceToNow(date, { addSuffix: true });
  };

  const probabilityBarClass = pct => {
    const widths = [
      'w-0',
      'w-[10%]',
      'w-[20%]',
      'w-[30%]',
      'w-[40%]',
      'w-[50%]',
      'w-[60%]',
      'w-[70%]',
      'w-[80%]',
      'w-[90%]',
      'w-full',
    ];
    return widths[Math.min(10, Math.round(Number(pct || 0) / 10))];
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

  const stageDotClass = stage => {
    if (stage?.isWon) return 'bg-success';
    if (stage?.isLost) return 'bg-destructive';
    return 'bg-primary';
  };

  const stageBadgeClass = stage => {
    if (stage?.isWon) return 'bg-success/10 text-success';
    if (stage?.isLost) return 'bg-destructive/10 text-destructive';
    return 'bg-primary/10 text-primary';
  };

  const priorityBadgeClass = priority => {
    if (priority === 'high') return 'bg-primary/10 text-primary';
    if (priority === 'low') return 'bg-success/10 text-success';
    return 'bg-warning/10 text-warning';
  };

  const companyInitial = name => (name || '?').slice(0, 1).toUpperCase();

  const ownerName = deal =>
    deal?.owner?.availableName || deal?.owner?.name || '';

  const stageMetrics = computed(() => {
    const list = deals.value || [];
    return (stages.value || []).map(stage => {
      const stageDeals = list.filter(deal => deal.pipelineStageId === stage.id);
      const amount = stageDeals.reduce(
        (sum, deal) => sum + Number(deal.amountCents || 0),
        0
      );
      const currency = stageDeals[0]?.currency || 'USD';
      return {
        id: stage.id,
        name: stage.name,
        count: stageDeals.length,
        value: formatAmount(amount, currency),
        dotClass: stageDotClass(stage),
      };
    });
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
    stageMetrics,
    stageDotClass,
    stageBadgeClass,
    priorityBadgeClass,
    companyInitial,
    ownerName,
    formatDealAmount,
    formatAmount,
    formatDate,
    formatRelative,
    probabilityBarClass,
    load,
    openCreate,
    openEdit,
    submitDeal,
    confirmDelete,
    deleteDeal,
    moveDealToStage,
  };
};
