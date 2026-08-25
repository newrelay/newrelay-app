<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import Draggable from 'vuedraggable';
import { useCrmPipeline } from 'dashboard/composables/useCrmPipeline';
import { RelayButton } from 'dashboard/components-next/relay';
import Spinner from 'shared/components/Spinner.vue';
import DealFormDialog from 'dashboard/components-next/Deals/DealFormDialog.vue';
import DealMetricsRow from 'dashboard/components-next/Deals/DealMetricsRow.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineOptions({ name: 'PipelinesIndex' });

const {
  selectedDeal,
  formDialogRef,
  uiFlags,
  stages,
  deals,
  metrics,
  formatDealAmount,
  formatAmount,
  load,
  openCreate,
  openEdit,
  submitDeal,
  moveDealToStage,
} = useCrmPipeline();

const columns = ref({});

const syncColumns = () => {
  const next = {};
  stages.value.forEach(stage => {
    next[stage.id] = [];
  });
  deals.value.forEach(deal => {
    const stageId = deal.pipelineStageId;
    if (!next[stageId]) next[stageId] = [];
    next[stageId].push(deal);
  });
  columns.value = next;
};

watch([deals, stages], syncColumns, { immediate: true, deep: true });

const stageTotals = computed(() => {
  const totals = {};
  stages.value.forEach(stage => {
    const list = columns.value[stage.id] || [];
    totals[stage.id] = {
      count: list.length,
      amount: list.reduce((sum, deal) => sum + Number(deal.amountCents || 0), 0),
      currency: list[0]?.currency || 'USD',
    };
  });
  return totals;
});

const onColumnChange = async (stage, event) => {
  if (!event?.added?.element) return;
  await moveDealToStage(event.added.element, stage.id);
};

onMounted(load);
</script>

<template>
  <div class="flex h-full min-h-0 flex-col bg-background">
    <div
      class="flex flex-wrap items-start justify-between gap-4 border-b border-border bg-card px-6 py-6"
    >
      <div>
        <h1 class="text-base font-medium text-foreground">
          {{ $t('PIPELINES.HEADER') }}
        </h1>
        <p class="mt-1 text-[13px] font-medium text-muted-foreground">
          {{ $t('PIPELINES.DESCRIPTION') }}
        </p>
      </div>
      <RelayButton
        class="h-9 px-4 text-[13px] font-medium"
        @click="openCreate"
      >
        <Icon icon="i-lucide-plus" class="size-4" />
        {{ $t('DEALS.NEW') }}
      </RelayButton>
    </div>

    <DealMetricsRow :metrics="metrics" />

    <div class="min-h-0 flex-1 overflow-auto p-6">
      <div
        v-if="uiFlags.fetchingList"
        class="flex items-center justify-center py-20"
      >
        <Spinner />
      </div>

      <div v-else class="flex h-full min-h-[28rem] gap-4 overflow-x-auto pb-2">
        <div
          v-for="stage in stages"
          :key="stage.id"
          class="flex w-72 shrink-0 flex-col rounded-xl border border-border/60 bg-card"
        >
          <div class="border-b border-border/60 px-4 py-3">
            <div class="flex items-center justify-between gap-2">
              <h2 class="text-[13px] font-medium text-foreground">
                {{ stage.name }}
              </h2>
              <span class="text-[12px] text-muted-foreground">
                {{ stageTotals[stage.id]?.count || 0 }}
              </span>
            </div>
            <p class="mt-1 text-[12px] text-muted-foreground">
              {{
                formatAmount(
                  stageTotals[stage.id]?.amount || 0,
                  stageTotals[stage.id]?.currency
                )
              }}
            </p>
          </div>

          <Draggable
            v-model="columns[stage.id]"
            group="pipeline-deals"
            item-key="id"
            class="flex min-h-[12rem] flex-1 flex-col gap-2 overflow-y-auto p-3"
            :animation="180"
            @change="onColumnChange(stage, $event)"
          >
            <template #item="{ element: deal }">
              <button
                type="button"
                class="w-full rounded-lg border border-border/60 bg-background p-3 text-left shadow-sm transition-colors hover:border-border"
                @click="openEdit(deal)"
              >
                <div class="text-[13px] font-medium text-foreground">
                  {{ deal.name }}
                </div>
                <div
                  v-if="deal.company?.name"
                  class="mt-1 text-[12px] text-muted-foreground"
                >
                  {{ deal.company.name }}
                </div>
                <div class="mt-2 flex items-center justify-between gap-2">
                  <span class="text-[13px] text-foreground">
                    {{ formatDealAmount(deal) }}
                  </span>
                  <span class="text-[11px] capitalize text-muted-foreground">
                    {{ deal.priority }}
                  </span>
                </div>
              </button>
            </template>
          </Draggable>

          <p
            v-if="!(columns[stage.id] || []).length"
            class="px-3 pb-3 text-center text-[12px] text-muted-foreground"
          >
            {{ $t('PIPELINES.EMPTY_COLUMN') }}
          </p>
        </div>
      </div>
    </div>

    <DealFormDialog
      ref="formDialogRef"
      :deal="selectedDeal"
      :stages="stages"
      :is-loading="uiFlags.creatingItem || uiFlags.updatingItem"
      @submit="submitDeal"
    />

  </div>
</template>
