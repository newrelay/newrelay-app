<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import Draggable from 'vuedraggable';
import { useCrmPipeline } from 'dashboard/composables/useCrmPipeline';
import { RelayButton } from 'dashboard/components-next/relay';
import Spinner from 'shared/components/Spinner.vue';
import DealFormDialog from 'dashboard/components-next/Deals/DealFormDialog.vue';
import DealMetricsRow from 'dashboard/components-next/Deals/DealMetricsRow.vue';
import CrmTableBoardToggle from 'dashboard/components-next/Deals/CrmTableBoardToggle.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

defineOptions({ name: 'PipelinesIndex' });

const {
  selectedDeal,
  formDialogRef,
  uiFlags,
  stages,
  deals,
  metrics,
  stageDotClass,
  companyInitial,
  ownerName,
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
      amount: list.reduce(
        (sum, deal) => sum + Number(deal.amountCents || 0),
        0
      ),
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
  <div class="flex h-full min-h-0 flex-col bg-muted/10 dark:bg-background">
    <div
      class="flex flex-col justify-between gap-4 border-b border-border bg-card px-6 py-6 md:flex-row md:items-start"
    >
      <div>
        <h1 class="mb-1.5 text-base font-medium tracking-tight text-foreground">
          {{ $t('PIPELINES.HEADER') }}
        </h1>
        <p class="text-[13px] font-medium text-muted-foreground">
          {{ $t('PIPELINES.DESCRIPTION') }}
        </p>
      </div>
      <div class="flex flex-wrap items-center gap-3">
        <CrmTableBoardToggle />
        <RelayButton
          class="h-9 gap-2 px-4 text-[13px] font-medium"
          @click="openCreate"
        >
          <Icon icon="i-lucide-plus" class="size-4" />
          {{ $t('DEALS.NEW') }}
        </RelayButton>
      </div>
    </div>

    <DealMetricsRow :metrics="metrics" />

    <div
      class="min-h-0 flex-1 overflow-x-auto overflow-y-hidden px-6 pb-2 pt-5"
    >
      <div
        v-if="uiFlags.fetchingList"
        class="flex items-center justify-center py-20"
      >
        <Spinner />
      </div>

      <div v-else class="flex h-full min-h-[28rem] min-w-max gap-4 pb-4">
        <div
          v-for="stage in stages"
          :key="stage.id"
          class="flex w-[320px] shrink-0 flex-col rounded-2xl bg-transparent"
        >
          <div class="flex shrink-0 flex-col gap-1.5 px-1 pb-4 pt-1">
            <div class="flex items-center gap-2.5">
              <div
                class="size-2.5 rounded-full"
                :class="stageDotClass(stage)"
              />
              <h2
                class="text-[15px] font-semibold tracking-tight text-foreground"
              >
                {{ stage.name }}
              </h2>
              <span
                class="ml-auto rounded-full bg-muted px-2 py-0.5 text-[11px] font-semibold text-muted-foreground"
              >
                {{ stageTotals[stage.id]?.count || 0 }}
              </span>
            </div>
            <span class="ml-5 text-[13px] font-medium text-muted-foreground">
              {{
                formatAmount(
                  stageTotals[stage.id]?.amount || 0,
                  stageTotals[stage.id]?.currency
                )
              }}
            </span>
          </div>

          <Draggable
            v-model="columns[stage.id]"
            group="pipeline-deals"
            item-key="id"
            class="flex min-h-[12rem] flex-1 flex-col gap-3 overflow-y-auto px-1 pb-4"
            :animation="180"
            @change="onColumnChange(stage, $event)"
          >
            <template #item="{ element: deal }">
              <button
                type="button"
                class="group flex w-full cursor-pointer flex-col gap-4 rounded-[14px] border border-border/60 bg-card p-4 text-left shadow-sm transition-all duration-200 hover:border-border hover:shadow-md"
                @click="openEdit(deal)"
              >
                <div class="flex w-full gap-3">
                  <div
                    class="flex size-10 shrink-0 items-center justify-center rounded-[10px] bg-primary text-[15px] font-bold text-primary-foreground shadow-sm"
                  >
                    {{ companyInitial(deal.company?.name || deal.name) }}
                  </div>
                  <div class="flex min-w-0 flex-1 flex-col pt-0.5">
                    <span
                      class="truncate text-[14px] font-semibold leading-snug text-foreground"
                    >
                      {{ deal.name }}
                    </span>
                    <span class="truncate text-[13px] text-muted-foreground">
                      {{ deal.company?.name || '—' }}
                    </span>
                  </div>
                </div>
                <div class="mt-0.5 flex items-center justify-between">
                  <span
                    class="text-[14.5px] font-semibold tracking-tight text-foreground"
                  >
                    {{ formatDealAmount(deal) }}
                  </span>
                  <div class="flex items-center gap-2">
                    <span
                      v-if="deal.pipelineStage?.isWon"
                      class="rounded-[4px] bg-success/10 px-1.5 py-0 text-[10px] font-bold uppercase tracking-widest text-success"
                    >
                      {{ $t('PIPELINES.WON') }}
                    </span>
                    <Avatar
                      v-if="ownerName(deal)"
                      :src="deal.owner?.thumbnail"
                      :name="ownerName(deal)"
                      :size="24"
                      rounded-full
                    />
                  </div>
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
