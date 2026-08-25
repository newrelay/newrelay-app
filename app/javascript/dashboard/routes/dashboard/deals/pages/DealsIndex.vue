<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useDealsStore } from 'dashboard/stores/deals';
import { usePipelinesStore } from 'dashboard/stores/pipelines';
import {
  RelayButton,
  RelayInput,
  RelayConfirmModal,
} from 'dashboard/components-next/relay';
import Spinner from 'shared/components/Spinner.vue';
import DealFormDialog from 'dashboard/components-next/Deals/DealFormDialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineOptions({ name: 'DealsIndex' });

const { t } = useI18n();
const dealsStore = useDealsStore();
const pipelinesStore = usePipelinesStore();

const searchQuery = ref('');
const selectedDeal = ref(null);
const dealToDelete = ref(null);
const showDeleteConfirm = ref(false);
const formDialogRef = ref(null);

const deals = computed(() => dealsStore.getDealsList);
const uiFlags = computed(() => dealsStore.getUIFlags);
const pipeline = computed(() => pipelinesStore.getDefaultPipeline);
const stages = computed(() => pipeline.value?.stages || []);

const filteredDeals = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return deals.value;
  return deals.value.filter(deal =>
    [deal.name, deal.pipelineStage?.name]
      .filter(Boolean)
      .some(value => String(value).toLowerCase().includes(query))
  );
});

const formatAmount = deal => {
  const amount = Number(deal.amountCents || 0) / 100;
  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: deal.currency || 'USD',
      maximumFractionDigits: 0,
    }).format(amount);
  } catch {
    return `$${amount.toFixed(0)}`;
  }
};

const formatDate = value => {
  if (!value) return '—';
  return new Date(value).toLocaleDateString();
};

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

onMounted(load);
</script>

<template>
  <div class="flex h-full min-h-0 flex-col bg-background">
    <div
      class="flex flex-wrap items-start justify-between gap-4 border-b border-border bg-card px-6 py-6"
    >
      <div>
        <h1 class="text-base font-medium text-foreground">
          {{ $t('DEALS.HEADER') }}
        </h1>
        <p class="mt-1 text-[13px] font-medium text-muted-foreground">
          {{ $t('DEALS.DESCRIPTION') }}
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

    <div class="flex items-center gap-3 border-b border-border bg-card px-6 py-3">
      <div class="relative w-full max-w-xs">
        <Icon
          icon="i-lucide-search"
          class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
        />
        <RelayInput
          v-model="searchQuery"
          class="pl-9 text-[13px]"
          :placeholder="$t('DEALS.SEARCH_PLACEHOLDER')"
        />
      </div>
    </div>

    <div class="min-h-0 flex-1 overflow-auto p-6">
      <div
        v-if="uiFlags.fetchingList"
        class="flex items-center justify-center py-20"
      >
        <Spinner />
      </div>

      <div
        v-else-if="!filteredDeals.length"
        class="flex flex-col items-center justify-center gap-3 rounded-xl border border-border/60 bg-card px-6 py-16 text-center"
      >
        <h2 class="text-[20px] font-[600] text-foreground">
          {{ $t('DEALS.EMPTY.TITLE') }}
        </h2>
        <p class="max-w-md text-[14px] text-muted-foreground">
          {{ $t('DEALS.EMPTY.DESCRIPTION') }}
        </p>
        <RelayButton class="mt-2 h-9 px-4 text-[13px]" @click="openCreate">
          {{ $t('DEALS.NEW') }}
        </RelayButton>
      </div>

      <div
        v-else
        class="overflow-hidden rounded-xl border border-border/60 bg-card"
      >
        <table class="min-w-full table-auto">
          <thead>
            <tr class="border-b border-border text-left">
              <th
                class="px-4 py-3 text-[12px] font-medium text-muted-foreground"
              >
                {{ $t('DEALS.TABLE.NAME') }}
              </th>
              <th
                class="px-4 py-3 text-[12px] font-medium text-muted-foreground"
              >
                {{ $t('DEALS.TABLE.STAGE') }}
              </th>
              <th
                class="px-4 py-3 text-[12px] font-medium text-muted-foreground"
              >
                {{ $t('DEALS.TABLE.AMOUNT') }}
              </th>
              <th
                class="px-4 py-3 text-[12px] font-medium text-muted-foreground"
              >
                {{ $t('DEALS.TABLE.CLOSE_ON') }}
              </th>
              <th
                class="px-4 py-3 text-[12px] font-medium text-muted-foreground"
              >
                {{ $t('DEALS.TABLE.PRIORITY') }}
              </th>
              <th
                class="px-4 py-3 text-[12px] font-medium text-muted-foreground"
              >
                {{ $t('DEALS.TABLE.UPDATED') }}
              </th>
              <th class="px-4 py-3" />
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="deal in filteredDeals"
              :key="deal.id"
              class="border-b border-border/60 last:border-0 hover:bg-muted/40"
            >
              <td class="px-4 py-3 text-[14px] font-medium text-foreground">
                {{ deal.name }}
              </td>
              <td class="px-4 py-3">
                <span
                  class="inline-flex rounded-md bg-primary/10 px-2 py-0.5 text-[12px] font-medium text-primary"
                >
                  {{ deal.pipelineStage?.name || '—' }}
                </span>
              </td>
              <td class="px-4 py-3 text-[14px] text-foreground">
                {{ formatAmount(deal) }}
              </td>
              <td class="px-4 py-3 text-[13px] text-muted-foreground">
                {{ formatDate(deal.closeOn) }}
              </td>
              <td class="px-4 py-3 text-[13px] capitalize text-foreground">
                {{ deal.priority }}
              </td>
              <td class="px-4 py-3 text-[13px] text-muted-foreground">
                {{ formatDate(deal.updatedAt) }}
              </td>
              <td class="px-4 py-3">
                <div class="flex justify-end gap-1">
                  <RelayButton
                    variant="ghost"
                    size="sm"
                    class="h-8 border border-border px-2 hover:border-transparent"
                    @click="openEdit(deal)"
                  >
                    <Icon icon="i-lucide-pencil" class="size-3.5" />
                  </RelayButton>
                  <RelayButton
                    variant="ghost"
                    size="sm"
                    class="h-8 border border-border px-2 text-destructive hover:border-transparent"
                    @click="confirmDelete(deal)"
                  >
                    <Icon icon="i-lucide-trash-2" class="size-3.5" />
                  </RelayButton>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <DealFormDialog
      ref="formDialogRef"
      :deal="selectedDeal"
      :stages="stages"
      :is-loading="uiFlags.creatingItem || uiFlags.updatingItem"
      @submit="submitDeal"
    />

    <RelayConfirmModal
      :show="showDeleteConfirm"
      :title="$t('DEALS.DELETE.TITLE')"
      :message="$t('DEALS.DELETE.DESCRIPTION')"
      :confirm-text="$t('DEALS.DELETE.CONFIRM')"
      :cancel-text="$t('DEALS.DELETE.CANCEL')"
      @confirm="deleteDeal"
      @close="showDeleteConfirm = false"
    />
  </div>
</template>
