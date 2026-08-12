<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { usePolicy } from 'dashboard/composables/usePolicy';
import {
  isSafeHttpLink,
  formatDocumentLink,
  getDocumentDisplayPath,
} from 'shared/helpers/documentHelper';

import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import DocumentSyncStatus from 'dashboard/components-next/captain/assistant/DocumentSyncStatus.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  name: {
    type: String,
    default: '',
  },
  assistant: {
    type: Object,
    default: () => ({}),
  },
  externalLink: {
    type: String,
    required: true,
  },
  pdfDocument: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Number,
    required: true,
  },
  status: {
    type: String,
    default: null,
  },
  syncStatus: {
    type: String,
    default: null,
  },
  lastSyncedAt: {
    type: Number,
    default: null,
  },
  lastSyncErrorCode: {
    type: String,
    default: null,
  },
  syncInProgress: {
    type: Boolean,
    default: false,
  },
  syncStaleAfterHours: {
    type: Number,
    default: null,
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
  selectable: {
    type: Boolean,
    default: false,
  },
  showSelectionControl: {
    type: Boolean,
    default: false,
  },
  showMenu: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['action', 'select', 'hover']);
const { checkPermissions } = usePolicy();

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const isPdf = computed(() => props.pdfDocument);
const hasSafeLink = computed(() => isSafeHttpLink(props.externalLink));
const canManage = computed(() => checkPermissions(['administrator']));
const isAvailable = computed(() => props.status === 'available');
const canSync = computed(
  () => canManage.value && !isPdf.value && isAvailable.value
);
const isSyncing = computed(() => props.syncStatus === 'syncing');
const isFailed = computed(() => props.syncStatus === 'failed');
const isRetryableSync = computed(
  () => isFailed.value || (isSyncing.value && !props.syncInProgress)
);
const showSyncStatus = computed(() => !isPdf.value);

const menuItems = computed(() => {
  const allOptions = [
    {
      label: t('CAPTAIN.DOCUMENTS.OPTIONS.VIEW_RELATED_RESPONSES'),
      value: 'viewRelatedQuestions',
      action: 'viewRelatedQuestions',
      icon: 'i-lucide-file-text',
    },
  ];

  if (canSync.value) {
    allOptions.push({
      label: isRetryableSync.value
        ? t('CAPTAIN.DOCUMENTS.OPTIONS.RETRY_SYNC')
        : t('CAPTAIN.DOCUMENTS.OPTIONS.SYNC_NOW'),
      value: 'sync',
      action: 'sync',
      icon: 'i-lucide-refresh-cw',
    });
  }

  if (canManage.value) {
    allOptions.push({
      label: t('CAPTAIN.DOCUMENTS.OPTIONS.DELETE_DOCUMENT'),
      value: 'delete',
      action: 'delete',
      icon: 'i-lucide-trash',
    });
  }

  return allOptions;
});

const createdAtLabel = computed(() => dynamicTime(props.createdAt));

const displayLink = computed(() =>
  isPdf.value
    ? formatDocumentLink(props.externalLink)
    : getDocumentDisplayPath(props.externalLink)
);
const linkIcon = computed(() =>
  isPdf.value ? 'i-lucide-file-text' : 'i-lucide-link'
);

const handleAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};

const handleRetry = () => {
  emit('action', { action: 'sync', id: props.id });
};

const handleCardClick = () => {
  if (props.selectable) {
    emit('select', props.id);
  }
};
</script>

<template>
  <div
    class="group flex cursor-pointer select-none flex-col justify-between rounded-xl border bg-card p-4 transition-all hover:shadow-sm sm:flex-row sm:items-center"
    :class="
      isSelected
        ? 'border-primary/50 bg-primary/[0.02]'
        : 'border-border hover:border-border'
    "
    @click="handleCardClick"
    @mouseenter="emit('hover', true)"
    @mouseleave="emit('hover', false)"
  >
    <div class="flex min-w-0 flex-1 items-center gap-4 pr-4">
      <div
        v-if="showSelectionControl"
        class="flex size-5 shrink-0 items-center justify-center rounded-full border transition-colors"
        :class="
          isSelected
            ? 'border-primary bg-primary text-primary-foreground shadow-xs'
            : 'border-border/80 bg-background/50'
        "
      >
        <span v-if="isSelected" class="i-lucide-check size-3 stroke-[3]" />
      </div>

      <div class="min-w-0 flex-1">
        <h3 class="mb-1 truncate text-[14.5px] font-medium text-foreground">
          {{ name }}
        </h3>
        <div
          class="flex flex-wrap items-center gap-4 text-[12px] text-muted-foreground"
        >
          <div class="flex items-center gap-1.5">
            <span class="i-lucide-brain-circuit size-3.5" />
            {{ assistant?.name || '' }}
          </div>
          <a
            v-if="!isPdf && hasSafeLink"
            :href="externalLink"
            :title="externalLink"
            target="_blank"
            rel="noopener noreferrer"
            class="flex max-w-[200px] items-center gap-1.5 truncate hover:text-foreground hover:underline"
            @click.stop
          >
            <span class="size-3.5 shrink-0" :class="[linkIcon]" />
            <span class="truncate">{{ displayLink }}</span>
          </a>
          <div v-else class="flex max-w-[200px] items-center gap-1.5 truncate">
            <span class="size-3.5 shrink-0" :class="[linkIcon]" />
            <span class="truncate">{{ displayLink }}</span>
          </div>
        </div>
      </div>
    </div>

    <div class="mt-4 flex shrink-0 items-center gap-4 sm:mt-0" @click.stop>
      <DocumentSyncStatus
        v-if="showSyncStatus"
        :status="syncStatus"
        :last-synced-at="lastSyncedAt"
        :error-code="lastSyncErrorCode"
        :sync-in-progress="syncInProgress"
        :stale-after-hours="syncStaleAfterHours"
        :show-retry="canSync && isRetryableSync"
        @retry="handleRetry"
      />
      <div v-else class="text-[12px] text-muted-foreground/60">
        {{ createdAtLabel }}
      </div>

      <div
        v-if="showMenu"
        v-on-clickaway="() => toggleDropdown(false)"
        class="relative"
      >
        <RelayButton
          variant="ghost"
          size="icon"
          class="size-8 rounded-md text-muted-foreground opacity-0 hover:bg-muted hover:text-foreground group-hover:opacity-100 focus:opacity-100"
          @click="toggleDropdown()"
        >
          <span class="i-lucide-ellipsis-vertical size-4" />
        </RelayButton>
        <DropdownMenu
          v-if="showActionsDropdown"
          :menu-items="menuItems"
          class="top-full mt-1 ltr:right-0 rtl:left-0"
          @action="handleAction($event)"
        />
      </div>
    </div>
  </div>
</template>
