<script setup>
import { computed, onMounted, ref } from 'vue';
import { useCrmPipeline } from 'dashboard/composables/useCrmPipeline';
import {
  RelayButton,
  RelayInput,
  RelayConfirmModal,
} from 'dashboard/components-next/relay';
import Spinner from 'shared/components/Spinner.vue';
import DealFormDialog from 'dashboard/components-next/Deals/DealFormDialog.vue';
import DealEmptyState from 'dashboard/components-next/Deals/EmptyState/DealEmptyState.vue';
import mockDeals from 'dashboard/components-next/Deals/EmptyState/dealEmptyStateContent';
import CrmTableBoardToggle from 'dashboard/components-next/Deals/CrmTableBoardToggle.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

defineOptions({ name: 'DealsIndex' });

const showMockDeals = ref(false);

const {
  selectedDeal,
  showDeleteConfirm,
  formDialogRef,
  searchQuery,
  uiFlags,
  deals,
  stages,
  filteredDeals,
  stageMetrics,
  stageBadgeClass,
  companyInitial,
  ownerName,
  formatDealAmount,
  formatDate,
  formatRelative,
  load,
  openCreate,
  openEdit,
  submitDeal,
  confirmDelete,
  deleteDeal,
} = useCrmPipeline();

const displayedDeals = computed(() => {
  if (!showMockDeals.value) return filteredDeals.value;
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return mockDeals;
  return mockDeals.filter(deal =>
    [deal.name, deal.pipelineStage?.name, deal.priority, deal.company?.name]
      .filter(Boolean)
      .some(value => String(value).toLowerCase().includes(query))
  );
});

const showOnboardingEmpty = computed(
  () =>
    !uiFlags.value.fetchingList && !deals.value.length && !showMockDeals.value
);

const showSearchEmpty = computed(
  () =>
    !uiFlags.value.fetchingList &&
    !showOnboardingEmpty.value &&
    !displayedDeals.value.length
);

const onDealClick = deal => {
  if (showMockDeals.value) return;
  openEdit(deal);
};

const clearSearch = () => {
  searchQuery.value = '';
};

onMounted(load);
</script>

<template>
  <div class="flex h-full min-h-0 flex-col bg-muted/10 dark:bg-background">
    <div
      class="flex flex-wrap items-center justify-between gap-4 bg-card px-6 py-4"
    >
      <div class="flex flex-wrap items-center gap-4">
        <div>
          <h1 class="text-base font-medium tracking-tight text-foreground">
            {{ $t('DEALS.HEADER') }}
          </h1>
          <p class="mt-1 text-[13px] font-medium text-muted-foreground">
            {{ $t('DEALS.DESCRIPTION') }}
          </p>
        </div>
        <CrmTableBoardToggle />
      </div>
      <RelayButton
        class="h-9 gap-2 px-4 text-[13px] font-medium"
        @click="openCreate"
      >
        <Icon icon="i-lucide-plus" class="size-4" />
        {{ $t('DEALS.NEW') }}
      </RelayButton>
    </div>

    <div
      v-if="stageMetrics.length && !showOnboardingEmpty && !showMockDeals"
      class="grid grid-cols-2 gap-4 p-6 pb-0 md:grid-cols-3 lg:grid-cols-5"
    >
      <div
        v-for="metric in stageMetrics"
        :key="metric.id"
        class="relative flex flex-col overflow-hidden rounded-xl border border-border/60 bg-card p-4 shadow-sm transition-colors hover:border-border"
      >
        <div class="mb-4 flex items-center justify-between">
          <div class="flex items-center gap-2">
            <div class="size-2 rounded-full" :class="metric.dotClass" />
            <span class="text-sm font-semibold text-foreground">
              {{ metric.name }}
            </span>
          </div>
          <span class="text-xs font-semibold text-muted-foreground">
            {{ metric.count }}
          </span>
        </div>
        <div class="mt-auto flex flex-col">
          <span class="mb-0.5 text-xs text-muted-foreground">
            {{ $t('DEALS.METRICS.VALUE') }}
          </span>
          <span class="text-lg font-semibold tracking-tight text-foreground">
            {{ metric.value }}
          </span>
        </div>
      </div>
    </div>

    <div v-if="!showOnboardingEmpty" class="flex items-center gap-3 px-6 py-4">
      <div class="relative w-full max-w-xs">
        <Icon
          icon="i-lucide-search"
          class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
        />
        <RelayInput
          v-model="searchQuery"
          class-name="h-9 rounded-lg border-border/60 bg-background pl-9 text-[14px] shadow-sm"
          :placeholder="$t('DEALS.SEARCH_PLACEHOLDER')"
        />
      </div>
    </div>

    <div class="flex min-h-0 flex-1 flex-col overflow-auto px-6 pb-6">
      <div
        v-if="uiFlags.fetchingList"
        class="flex items-center justify-center py-20"
      >
        <Spinner />
      </div>

      <div
        v-else-if="showOnboardingEmpty"
        class="m-auto flex w-full flex-1 justify-center px-4 py-12"
      >
        <DealEmptyState
          @create="openCreate"
          @load-mock="showMockDeals = true"
        />
      </div>

      <div
        v-else-if="showSearchEmpty"
        class="m-auto flex w-full flex-1 flex-col items-center justify-center gap-3 rounded-xl border border-border/60 bg-card px-6 py-16 text-center"
      >
        <div
          class="flex size-12 items-center justify-center rounded-full bg-muted"
        >
          <span class="i-lucide-search size-6 text-muted-foreground" />
        </div>
        <h2 class="text-[20px] font-[600] text-foreground">
          {{ $t('DEALS.EMPTY.SEARCH_EMPTY_TITLE') }}
        </h2>
        <p class="max-w-md text-[14px] text-muted-foreground">
          {{
            $t('DEALS.EMPTY.SEARCH_EMPTY_SUBTITLE', {
              query: searchQuery,
            })
          }}
        </p>
        <div class="mt-2 flex items-center gap-3">
          <RelayButton
            v-if="searchQuery"
            variant="outline"
            @click="clearSearch"
          >
            {{ $t('DEALS.EMPTY.CLEAR_SEARCH') }}
          </RelayButton>
          <RelayButton class="h-9 px-4 text-[13px]" @click="openCreate">
            {{ $t('DEALS.NEW') }}
          </RelayButton>
        </div>
      </div>

      <div
        v-else
        class="flex flex-col overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm"
      >
        <div class="overflow-x-auto">
          <table class="w-full text-left text-sm">
            <thead
              class="border-b border-border/60 bg-muted/30 text-muted-foreground"
            >
              <tr>
                <th class="px-5 py-3.5 font-medium">
                  {{ $t('DEALS.TABLE.NAME') }}
                </th>
                <th class="px-5 py-3.5 font-medium">
                  {{ $t('DEALS.TABLE.COMPANY') }}
                </th>
                <th class="px-5 py-3.5 font-medium">
                  {{ $t('DEALS.TABLE.STAGE') }}
                </th>
                <th class="px-5 py-3.5 font-medium">
                  {{ $t('DEALS.TABLE.AMOUNT') }}
                </th>
                <th class="px-5 py-3.5 font-medium">
                  {{ $t('DEALS.TABLE.CLOSE_ON') }}
                </th>
                <th class="px-5 py-3.5 font-medium">
                  {{ $t('DEALS.TABLE.OWNER') }}
                </th>
                <th class="px-5 py-3.5 font-medium">
                  {{ $t('DEALS.TABLE.UPDATED') }}
                </th>
                <th class="px-5 py-3.5" />
              </tr>
            </thead>
            <tbody class="divide-y divide-border/40">
              <tr
                v-for="deal in displayedDeals"
                :key="deal.id"
                class="group transition-colors hover:bg-muted/30"
                :class="showMockDeals ? '' : 'cursor-pointer'"
                @click="onDealClick(deal)"
              >
                <td class="px-5 py-4 align-middle font-medium text-foreground">
                  {{ deal.name }}
                </td>
                <td class="px-5 py-4 align-middle">
                  <div class="flex items-center gap-2">
                    <div
                      class="flex size-6 shrink-0 items-center justify-center rounded-md bg-primary/10 text-[10px] font-bold text-primary"
                    >
                      {{ companyInitial(deal.company?.name) }}
                    </div>
                    <span
                      class="text-muted-foreground transition-colors group-hover:text-foreground"
                    >
                      {{ deal.company?.name || '—' }}
                    </span>
                  </div>
                </td>
                <td class="px-5 py-4 align-middle">
                  <span
                    class="inline-flex rounded-md px-2.5 py-0.5 text-xs font-medium"
                    :class="stageBadgeClass(deal.pipelineStage)"
                  >
                    {{ deal.pipelineStage?.name || '—' }}
                  </span>
                </td>
                <td class="px-5 py-4 align-middle font-medium text-foreground">
                  {{ formatDealAmount(deal) }}
                </td>
                <td class="px-5 py-4 align-middle text-muted-foreground">
                  {{ formatDate(deal.closeOn) }}
                </td>
                <td class="px-5 py-4 align-middle">
                  <Avatar
                    v-if="ownerName(deal)"
                    :src="deal.owner?.thumbnail"
                    :name="ownerName(deal)"
                    :size="28"
                    rounded-full
                  />
                  <span v-else class="text-[13px] text-muted-foreground">
                    —
                  </span>
                </td>
                <td
                  class="px-5 py-4 align-middle text-xs font-medium text-muted-foreground"
                >
                  {{ formatRelative(deal.updatedAt) }}
                </td>
                <td class="px-5 py-4 align-middle" @click.stop>
                  <div
                    v-if="!showMockDeals"
                    class="flex justify-end gap-1 opacity-0 group-hover:opacity-100"
                  >
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
