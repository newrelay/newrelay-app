<script setup>
import { computed, ref, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import BulkActionAuditsAPI from 'dashboard/api/bulkActionAudits';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { RelayBadge, RelayButton } from 'dashboard/components-next/relay';

const { t } = useI18n();

const audits = ref([]);
const isLoading = ref(false);
const openFilter = ref(null);

const statusFilter = ref('');
const operationFilter = ref('');
const dateFromFilter = ref('');
const dateToFilter = ref('');

const OPERATION_META = {
  add_tag: {
    icon: 'i-lucide-tag',
    iconClass: 'bg-primary/10 text-primary',
  },
  remove_tag: {
    icon: 'i-lucide-minus-circle',
    iconClass: 'bg-muted text-foreground',
  },
  delete: {
    icon: 'i-lucide-trash-2',
    iconClass: 'bg-destructive/10 text-destructive',
  },
  send_sms: {
    icon: 'i-lucide-message-square',
    iconClass: 'bg-primary/10 text-primary',
  },
  send_email: {
    icon: 'i-lucide-mail',
    iconClass: 'bg-primary/10 text-primary',
  },
};

const statusOptions = computed(() => [
  { value: '', label: t('CONTACTS_BULK_ACTIONS.AUDIT.FILTER.STATUS') },
  { value: 'pending', label: t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.PENDING') },
  {
    value: 'processing',
    label: t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.PROCESSING'),
  },
  {
    value: 'completed',
    label: t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.COMPLETED'),
  },
  { value: 'failed', label: t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.FAILED') },
]);

const operationOptions = computed(() => [
  { value: '', label: t('CONTACTS_BULK_ACTIONS.AUDIT.FILTER.OPERATION') },
  {
    value: 'add_tag',
    label: t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.ADD_LABEL'),
  },
  {
    value: 'remove_tag',
    label: t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.REMOVE_LABEL'),
  },
  {
    value: 'delete',
    label: t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.DELETE'),
  },
  {
    value: 'send_sms',
    label: t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.SEND_SMS'),
  },
  {
    value: 'send_email',
    label: t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.SEND_EMAIL'),
  },
]);

const statusLabel = computed(
  () =>
    statusOptions.value.find(item => item.value === statusFilter.value)
      ?.label || statusOptions.value[0].label
);

const operationLabel = computed(
  () =>
    operationOptions.value.find(item => item.value === operationFilter.value)
      ?.label || operationOptions.value[0].label
);

const statusLabelMap = computed(() => ({
  pending: t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.PENDING'),
  processing: t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.PROCESSING'),
  completed: t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.COMPLETED'),
  failed: t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.FAILED'),
}));

const hasFilters = computed(
  () =>
    !!(
      statusFilter.value ||
      operationFilter.value ||
      dateFromFilter.value ||
      dateToFilter.value
    )
);

const fetchAudits = async () => {
  isLoading.value = true;
  try {
    const params = {};
    if (statusFilter.value) {
      params.status = statusFilter.value;
    }
    if (operationFilter.value) {
      params.operation_type = operationFilter.value;
    }

    const response = await BulkActionAuditsAPI.get(params);
    let data = response.data || [];

    if (dateFromFilter.value) {
      const fromDate = new Date(dateFromFilter.value);
      data = data.filter(audit => new Date(audit.created_at) >= fromDate);
    }
    if (dateToFilter.value) {
      const toDate = new Date(dateToFilter.value);
      toDate.setHours(23, 59, 59, 999);
      data = data.filter(audit => new Date(audit.created_at) <= toDate);
    }

    audits.value = data;
  } catch {
    // Ignore error
  } finally {
    isLoading.value = false;
  }
};

const closeFilterMenus = () => {
  openFilter.value = null;
};

const toggleFilter = key => {
  openFilter.value = openFilter.value === key ? null : key;
};

const selectStatus = value => {
  statusFilter.value = value;
  closeFilterMenus();
};

const selectOperation = value => {
  operationFilter.value = value;
  closeFilterMenus();
};

const clearFilters = () => {
  statusFilter.value = '';
  operationFilter.value = '';
  dateFromFilter.value = '';
  dateToFilter.value = '';
};

const formatDate = dateString => {
  if (!dateString) return '—';
  return new Date(dateString).toLocaleString(undefined, {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const getStatusClass = status => {
  const classes = {
    pending: 'bg-muted text-muted-foreground',
    processing: 'bg-muted text-foreground',
    completed: 'bg-primary/10 text-primary',
    failed: 'bg-destructive/10 text-destructive',
  };
  return classes[status] || 'bg-muted text-muted-foreground';
};

const getOperationMeta = operation =>
  OPERATION_META[operation] || {
    icon: 'i-lucide-zap',
    iconClass: 'bg-muted text-foreground',
  };

const getOperationLabel = operation => {
  const labels = {
    add_tag: t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.ADD_LABEL'),
    remove_tag: t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.REMOVE_LABEL'),
    delete: t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.DELETE'),
    send_sms: t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.SEND_SMS'),
    send_email: t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.SEND_EMAIL'),
  };
  return labels[operation] || operation;
};

const getProgress = audit => {
  const stats = audit.statistics || {};
  const total = stats.total || 0;
  const success = stats.success || 0;
  if (!total) return null;
  return {
    success,
    total,
    percent: Math.min(100, Math.round((success / total) * 100)),
  };
};

const getProgressBarClass = status => {
  if (status === 'failed') return 'bg-destructive';
  if (status === 'processing') return 'bg-foreground';
  return 'bg-primary';
};

const formatStatistics = audit => {
  if (audit.status === 'pending') {
    return t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.PENDING');
  }
  if (audit.status === 'processing' && !audit.statistics?.total) {
    return t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.PROCESSING');
  }

  const progress = getProgress(audit);
  if (!progress) return '—';
  return t('CONTACTS_BULK_ACTIONS.AUDIT.STATISTICS_SUCCESS', {
    success: progress.success,
    total: progress.total,
  });
};

watch([statusFilter, operationFilter, dateFromFilter, dateToFilter], () => {
  fetchAudits();
});

onMounted(() => {
  fetchAudits();
});
</script>

<template>
  <div
    class="flex h-full flex-1 flex-col overflow-y-auto bg-background p-6 relative"
  >
    <div class="max-w-6xl">
      <h2 class="mb-1 text-base font-semibold tracking-tight text-foreground">
        {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TITLE') }}
      </h2>
      <p class="mb-12 text-[14px] text-muted-foreground">
        {{ t('CONTACTS_BULK_ACTIONS.AUDIT.SUBTITLE') }}
      </p>

      <!-- Filters card -->
      <div
        class="mb-10 space-y-6 rounded-xl border border-border bg-card p-6 shadow-sm"
      >
        <div
          v-on-click-outside="closeFilterMenus"
          class="grid grid-cols-1 gap-4 sm:grid-cols-2"
        >
          <div class="relative">
            <RelayButton
              variant="outline"
              class="h-11 w-full justify-between rounded-md border-border bg-background px-4 text-[14px] font-medium text-foreground hover:bg-muted/50"
              :class="{ 'bg-muted/50': openFilter === 'status' }"
              @click="toggleFilter('status')"
            >
              <span class="flex min-w-0 items-center gap-2">
                <span
                  class="i-lucide-activity size-4 shrink-0 text-muted-foreground"
                />
                <span class="truncate">{{ statusLabel }}</span>
              </span>
              <span
                class="i-lucide-chevron-down size-4 shrink-0 text-muted-foreground"
              />
            </RelayButton>
            <div
              v-if="openFilter === 'status'"
              class="absolute left-0 right-0 top-full z-50 mt-1 overflow-hidden rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
            >
              <button
                v-for="option in statusOptions"
                :key="option.value || 'all-status'"
                type="button"
                class="flex w-full cursor-pointer items-center rounded-sm px-3 py-2 text-left text-[13px] text-foreground hover:bg-muted"
                :class="{ 'bg-muted': statusFilter === option.value }"
                @click="selectStatus(option.value)"
              >
                {{ option.label }}
              </button>
            </div>
          </div>

          <div class="relative">
            <RelayButton
              variant="outline"
              class="h-11 w-full justify-between rounded-md border-border bg-background px-4 text-[14px] font-medium text-foreground hover:bg-muted/50"
              :class="{ 'bg-muted/50': openFilter === 'operation' }"
              @click="toggleFilter('operation')"
            >
              <span class="flex min-w-0 items-center gap-2">
                <span
                  class="i-lucide-zap size-4 shrink-0 text-muted-foreground"
                />
                <span class="truncate">{{ operationLabel }}</span>
              </span>
              <span
                class="i-lucide-chevron-down size-4 shrink-0 text-muted-foreground"
              />
            </RelayButton>
            <div
              v-if="openFilter === 'operation'"
              class="absolute left-0 right-0 top-full z-50 mt-1 overflow-hidden rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
            >
              <button
                v-for="option in operationOptions"
                :key="option.value || 'all-ops'"
                type="button"
                class="flex w-full cursor-pointer items-center rounded-sm px-3 py-2 text-left text-[13px] text-foreground hover:bg-muted"
                :class="{ 'bg-muted': operationFilter === option.value }"
                @click="selectOperation(option.value)"
              >
                {{ option.label }}
              </button>
            </div>
          </div>
        </div>

        <div class="flex flex-wrap items-center gap-4">
          <div class="flex flex-col gap-1.5">
            <span class="text-xs font-semibold text-muted-foreground">
              {{ t('CONTACTS_BULK_ACTIONS.AUDIT.FILTER.DATE_FROM') }}
            </span>
            <input
              v-model="dateFromFilter"
              type="date"
              class="h-[38px] w-[180px] rounded-md border border-border bg-background px-3 text-[13px] font-medium text-foreground shadow-sm focus:outline-none focus:ring-1 focus:ring-primary/30"
            />
          </div>

          <span
            class="i-lucide-arrow-right mx-2 mt-2 size-4 shrink-0 text-muted-foreground"
            aria-hidden="true"
          />

          <div class="flex flex-col gap-1.5">
            <span class="text-xs font-semibold text-muted-foreground">
              {{ t('CONTACTS_BULK_ACTIONS.AUDIT.FILTER.DATE_TO') }}
            </span>
            <input
              v-model="dateToFilter"
              type="date"
              class="h-[38px] w-[180px] rounded-md border border-border bg-background px-3 text-[13px] font-medium text-foreground shadow-sm focus:outline-none focus:ring-1 focus:ring-primary/30"
            />
          </div>

          <RelayButton
            v-if="hasFilters"
            variant="ghost"
            size="sm"
            class="mt-6"
            @click="clearFilters"
          >
            {{ t('CONTACTS_LAYOUT.FILTER.ACTIVE_FILTERS.CLEAR_FILTERS') }}
          </RelayButton>
        </div>
      </div>

      <div
        v-if="isLoading"
        class="flex items-center justify-center py-20 text-muted-foreground"
      >
        <Spinner />
      </div>

      <div
        v-else-if="!audits.length"
        class="flex flex-col items-center justify-center rounded-xl border border-dashed border-border bg-muted/20 py-20"
      >
        <span class="i-lucide-activity mb-4 size-12 text-muted-foreground/50" />
        <h3 class="mb-1 text-lg font-medium text-foreground">
          {{ t('CONTACTS_BULK_ACTIONS.AUDIT.EMPTY.TITLE') }}
        </h3>
        <p class="max-w-sm text-center text-sm text-muted-foreground">
          {{ t('CONTACTS_BULK_ACTIONS.AUDIT.EMPTY.SUBTITLE') }}
        </p>
      </div>

      <!-- Logs table -->
      <div
        v-else
        class="mt-8 w-full overflow-hidden rounded-xl border border-border bg-card shadow-sm"
      >
        <div class="w-full overflow-x-auto">
          <table class="w-full border-collapse text-left">
            <thead>
              <tr class="border-b border-border bg-muted/20">
                <th
                  class="w-[25%] px-6 py-3 text-[13px] font-medium text-muted-foreground"
                >
                  {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.ACTION_NAME') }}
                </th>
                <th
                  class="w-[15%] px-6 py-3 text-[13px] font-medium text-muted-foreground"
                >
                  {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.OPERATION') }}
                </th>
                <th
                  class="w-[15%] px-6 py-3 text-[13px] font-medium text-muted-foreground"
                >
                  {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.CREATED_AT') }}
                </th>
                <th
                  class="w-[15%] px-6 py-3 text-[13px] font-medium text-muted-foreground"
                >
                  {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.COMPLETED_AT') }}
                </th>
                <th
                  class="w-[15%] px-6 py-3 text-[13px] font-medium text-muted-foreground"
                >
                  {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.STATUS') }}
                </th>
                <th
                  class="w-[15%] px-6 py-3 text-[13px] font-medium text-muted-foreground"
                >
                  {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.STATISTICS') }}
                </th>
              </tr>
            </thead>
            <tbody class="text-[13px]">
              <tr
                v-for="audit in audits"
                :key="audit.id"
                class="border-b border-border/40 transition-colors hover:bg-muted/20"
              >
                <td class="px-6 py-4">
                  <div class="flex items-center gap-3">
                    <div
                      class="flex size-9 shrink-0 items-center justify-center rounded-lg"
                      :class="getOperationMeta(audit.operation_type).iconClass"
                    >
                      <span
                        class="size-4"
                        :class="getOperationMeta(audit.operation_type).icon"
                      />
                    </div>
                    <span class="font-medium text-foreground">
                      {{ audit.action_label }}
                    </span>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <RelayBadge
                    variant="outline"
                    class="border-border/60 font-medium text-muted-foreground"
                  >
                    {{ getOperationLabel(audit.operation_type) }}
                  </RelayBadge>
                </td>
                <td class="px-6 py-4 text-muted-foreground">
                  {{ formatDate(audit.created_at) }}
                </td>
                <td class="px-6 py-4 text-muted-foreground">
                  {{ formatDate(audit.completed_at) }}
                </td>
                <td class="px-6 py-4">
                  <span
                    class="rounded-md px-2.5 py-1 text-[11px] font-semibold uppercase"
                    :class="getStatusClass(audit.status)"
                  >
                    {{ statusLabelMap[audit.status] || audit.status }}
                  </span>
                </td>
                <td class="px-6 py-4">
                  <div class="flex w-full max-w-[150px] flex-col gap-1.5">
                    <span class="text-xs font-medium text-muted-foreground">
                      {{ formatStatistics(audit) }}
                    </span>
                    <div
                      v-if="getProgress(audit)"
                      class="h-1.5 w-full overflow-hidden rounded-full bg-muted"
                    >
                      <div
                        class="h-full transition-all"
                        :class="getProgressBarClass(audit.status)"
                        :style="{
                          width: `${getProgress(audit).percent}%`,
                        }"
                      />
                    </div>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
