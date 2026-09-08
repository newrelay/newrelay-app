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
import DealMetricsRow from 'dashboard/components-next/Deals/DealMetricsRow.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

defineOptions({ name: 'OpportunitiesIndex' });

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
  metrics,
  stageBadgeClass,
  priorityBadgeClass,
  companyInitial,
  ownerName,
  formatDealAmount,
  formatDate,
  formatRelative,
  probabilityBarClass,
  load,
  openCreate,
  openEdit,
  submitDeal,
  confirmDelete,
  deleteDeal,
} = useCrmPipeline();

const priorityLabel = priority => {
  const key = String(priority || '').toUpperCase();
  return ['LOW', 'MEDIUM', 'HIGH'].includes(key) ? `DEALS.PRIORITY.${key}` : '';
};

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
      class="flex flex-col justify-between gap-4 border-b border-border bg-card px-6 py-6 md:flex-row md:items-start"
    >
      <div>
        <h1 class="mb-1.5 text-base font-medium tracking-tight text-foreground">
          {{ $t('OPPORTUNITIES.HEADER') }}
        </h1>
        <p class="text-[13px] font-medium text-muted-foreground">
          {{ $t('OPPORTUNITIES.DESCRIPTION') }}
        </p>
      </div>
      <RelayButton
        class="h-9 gap-2 px-4 text-[13px] font-medium"
        @click="openCreate"
      >
        <Icon icon="i-lucide-plus" class="size-4" />
        {{ $t('OPPORTUNITIES.NEW') }}
      </RelayButton>
    </div>

    <DealMetricsRow
      v-if="!showOnboardingEmpty && !showMockDeals"
      :metrics="metrics"
    />

    <div
      v-if="!showOnboardingEmpty"
      class="flex items-center gap-3 border-b border-border bg-card px-6 py-3"
    >
      <div class="relative w-full max-w-xs">
        <Icon
          icon="i-lucide-search"
          class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
        />
        <RelayInput
          v-model="searchQuery"
          class="h-9 rounded-lg border-border/60 bg-background pl-9 text-[13px] shadow-sm"
          :placeholder="$t('OPPORTUNITIES.SEARCH_PLACEHOLDER')"
        />
      </div>
    </div>

    <div
      class="min-h-0 flex-1 overflow-auto"
      :class="showOnboardingEmpty ? 'bg-muted/10' : 'bg-card'"
    >
      <div
        v-if="uiFlags.fetchingList"
        class="flex items-center justify-center py-20"
      >
        <Spinner />
      </div>

      <div
        v-else-if="showOnboardingEmpty"
        class="flex flex-1 justify-center px-4 py-12"
      >
        <DealEmptyState
          variant="opportunities"
          @create="openCreate"
          @load-mock="showMockDeals = true"
        />
      </div>

      <div
        v-else-if="showSearchEmpty"
        class="flex flex-col items-center justify-center gap-3 px-6 py-16 text-center"
      >
        <div
          class="flex size-12 items-center justify-center rounded-full bg-muted"
        >
          <span class="i-lucide-search size-6 text-muted-foreground" />
        </div>
        <h2 class="text-[20px] font-[600] text-foreground">
          {{ $t('OPPORTUNITIES.EMPTY.SEARCH_EMPTY_TITLE') }}
        </h2>
        <p class="max-w-md text-[14px] text-muted-foreground">
          {{
            $t('OPPORTUNITIES.EMPTY.SEARCH_EMPTY_SUBTITLE', {
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
            {{ $t('OPPORTUNITIES.EMPTY.CLEAR_SEARCH') }}
          </RelayButton>
          <RelayButton class="h-9 px-4 text-[13px]" @click="openCreate">
            {{ $t('OPPORTUNITIES.NEW') }}
          </RelayButton>
        </div>
      </div>

      <table
        v-else
        class="w-full min-w-max whitespace-nowrap text-left text-sm"
      >
        <thead
          class="sticky top-0 z-10 border-b border-border/60 bg-card text-[12px] font-medium text-muted-foreground shadow-sm"
        >
          <tr>
            <th class="px-4 py-3 font-medium">
              {{ $t('DEALS.TABLE.NAME') }}
            </th>
            <th class="px-4 py-3 font-medium">
              {{ $t('DEALS.TABLE.COMPANY') }}
            </th>
            <th class="px-4 py-3 font-medium">
              {{ $t('DEALS.TABLE.STAGE') }}
            </th>
            <th class="px-4 py-3 font-medium">
              {{ $t('DEALS.TABLE.AMOUNT') }}
            </th>
            <th class="px-4 py-3 font-medium">
              {{ $t('DEALS.TABLE.CLOSE_ON') }}
            </th>
            <th class="px-4 py-3 font-medium">
              {{ $t('DEALS.TABLE.OWNER') }}
            </th>
            <th class="px-4 py-3 font-medium">
              {{ $t('DEALS.TABLE.PRIORITY') }}
            </th>
            <th class="px-4 py-3 font-medium">
              {{ $t('DEALS.TABLE.PROBABILITY') }}
            </th>
            <th class="px-4 py-3 font-medium">
              {{ $t('DEALS.TABLE.UPDATED') }}
            </th>
            <th class="px-6 py-3 text-center font-medium" />
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
            <td class="px-4 py-4">
              <div class="flex flex-col gap-0.5">
                <span
                  class="cursor-pointer text-[13.5px] font-semibold text-foreground transition-colors hover:text-primary"
                >
                  {{ deal.name }}
                </span>
                <span
                  class="text-[11px] font-medium uppercase tracking-wide text-muted-foreground"
                >
                  {{ $t('OPPORTUNITIES.ID', { id: deal.id }) }}
                </span>
              </div>
            </td>
            <td class="px-4 py-4">
              <div class="flex items-center gap-2.5">
                <div
                  class="flex size-6 items-center justify-center rounded-md bg-primary text-[10px] font-bold text-primary-foreground"
                >
                  {{ companyInitial(deal.company?.name) }}
                </div>
                <span class="text-[13px] text-muted-foreground">
                  {{ deal.company?.name || '—' }}
                </span>
              </div>
            </td>
            <td class="px-4 py-4">
              <span
                class="inline-flex rounded-[6px] px-2.5 py-0.5 text-[11px] font-semibold"
                :class="stageBadgeClass(deal.pipelineStage)"
              >
                {{ deal.pipelineStage?.name || '—' }}
              </span>
            </td>
            <td class="px-4 py-4 text-[13.5px] font-semibold text-foreground">
              {{ formatDealAmount(deal) }}
            </td>
            <td class="px-4 py-4 text-[13px] text-muted-foreground">
              {{ formatDate(deal.closeOn) }}
            </td>
            <td class="px-4 py-4">
              <div class="flex items-center gap-2">
                <Avatar
                  v-if="ownerName(deal)"
                  :src="deal.owner?.thumbnail"
                  :name="ownerName(deal)"
                  :size="24"
                  rounded-full
                />
                <span class="text-[13px] text-muted-foreground">
                  {{ ownerName(deal) || '—' }}
                </span>
              </div>
            </td>
            <td class="px-4 py-4">
              <span
                v-if="priorityLabel(deal.priority)"
                class="inline-flex rounded-[6px] px-2.5 py-0.5 text-[11px] font-semibold capitalize"
                :class="priorityBadgeClass(deal.priority)"
              >
                {{ $t(priorityLabel(deal.priority)) }}
              </span>
              <span
                v-else
                class="pl-3 text-[13px] font-medium text-muted-foreground"
              >
                —
              </span>
            </td>
            <td class="min-w-[140px] px-4 py-4">
              <div class="flex items-center gap-3">
                <span class="w-8 text-right text-[13px] text-muted-foreground">
                  {{ deal.probability || 0 }}%
                </span>
                <div class="h-1.5 w-16 overflow-hidden rounded-full bg-muted">
                  <div
                    class="h-full rounded-full bg-primary"
                    :class="probabilityBarClass(deal.probability)"
                  />
                </div>
              </div>
            </td>
            <td class="px-4 py-4 text-[13px] text-muted-foreground">
              {{ formatRelative(deal.updatedAt) }}
            </td>
            <td class="px-6 py-4 text-center" @click.stop>
              <div
                v-if="!showMockDeals"
                class="flex justify-center gap-1 opacity-0 group-hover:opacity-100"
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
