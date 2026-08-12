<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  status: {
    type: String,
    default: null,
  },
  lastSyncedAt: {
    type: Number,
    default: null,
  },
  errorCode: {
    type: String,
    default: null,
  },
  syncInProgress: {
    type: Boolean,
    default: false,
  },
  staleAfterHours: {
    type: Number,
    default: null,
  },
  showRetry: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['retry']);
const { t } = useI18n();

const SECONDS_PER_HOUR = 3600;

const SYNCING = 'syncing';
const FAILED = 'failed';

const ERROR_CODE_LABELS = {
  not_found: 'CAPTAIN.DOCUMENTS.SYNC_ERRORS.NOT_FOUND',
  access_denied: 'CAPTAIN.DOCUMENTS.SYNC_ERRORS.ACCESS_DENIED',
  timeout: 'CAPTAIN.DOCUMENTS.SYNC_ERRORS.TIMEOUT',
  content_empty: 'CAPTAIN.DOCUMENTS.SYNC_ERRORS.CONTENT_EMPTY',
  fetch_failed: 'CAPTAIN.DOCUMENTS.SYNC_ERRORS.FETCH_FAILED',
  sync_error: 'CAPTAIN.DOCUMENTS.SYNC_ERRORS.SYNC_ERROR',
};
const DEFAULT_ERROR_LABEL = 'CAPTAIN.DOCUMENTS.SYNC_ERRORS.DEFAULT';

const hasSyncingStatus = computed(() => props.status === SYNCING);
const isSyncing = computed(
  () => hasSyncingStatus.value && props.syncInProgress
);
const isStaleSync = computed(
  () => hasSyncingStatus.value && !props.syncInProgress
);
const isFailed = computed(() => props.status === FAILED);
const canRetry = computed(() => isFailed.value || isStaleSync.value);
const hasBeenSynced = computed(() => Boolean(props.lastSyncedAt));

const ageInHours = computed(() => {
  if (!props.lastSyncedAt) return null;
  const nowSeconds = Date.now() / 1000;
  return (nowSeconds - props.lastSyncedAt) / SECONDS_PER_HOUR;
});

const staleAfterHours = computed(() => Number(props.staleAfterHours));
const hasStaleThreshold = computed(
  () => Number.isFinite(staleAfterHours.value) && staleAfterHours.value > 0
);
const isStale = computed(
  () =>
    hasStaleThreshold.value &&
    ageInHours.value !== null &&
    ageInHours.value >= staleAfterHours.value
);

const errorLabel = computed(() =>
  t(ERROR_CODE_LABELS[props.errorCode] || DEFAULT_ERROR_LABEL)
);

const label = computed(() => {
  if (isSyncing.value) return t('CAPTAIN.DOCUMENTS.SYNC_STATUS.SYNCING');
  if (isStaleSync.value) return t('CAPTAIN.DOCUMENTS.SYNC_STATUS.STALE_SYNC');
  if (isFailed.value) return t('CAPTAIN.DOCUMENTS.SYNC_STATUS.FAILED');
  if (hasBeenSynced.value)
    return t('CAPTAIN.DOCUMENTS.SYNC_STATUS.SYNCED', {
      time: dynamicTime(props.lastSyncedAt),
    });
  return t('CAPTAIN.DOCUMENTS.SYNC_STATUS.NEVER_SYNCED');
});

const fullLabel = computed(() => {
  if (isSyncing.value) return t('CAPTAIN.DOCUMENTS.SYNC_STATUS.SYNCING');
  if (isStaleSync.value) return t('CAPTAIN.DOCUMENTS.SYNC_STATUS.STALE_SYNC');
  if (isFailed.value)
    return t('CAPTAIN.DOCUMENTS.SYNC_STATUS.FAILED', {
      error: errorLabel.value,
    });
  if (hasBeenSynced.value)
    return t('CAPTAIN.DOCUMENTS.SYNC_STATUS.SYNCED', {
      time: dynamicTime(props.lastSyncedAt),
    });
  return t('CAPTAIN.DOCUMENTS.SYNC_STATUS.NEVER_SYNCED');
});

const tone = computed(() => {
  if (isSyncing.value) return 'amber';
  if (isStaleSync.value) return 'amber';
  if (isFailed.value) return 'ruby';
  if (isStale.value) return 'amber';
  return 'slate';
});

const textClass = computed(() => {
  if (tone.value === 'amber') return 'text-amber-500';
  if (tone.value === 'ruby') return 'text-destructive';
  return 'text-muted-foreground/60';
});

const statusIcon = computed(() => {
  if (isFailed.value || isStale.value || isStaleSync.value) {
    return 'i-lucide-circle-alert';
  }
  return 'i-lucide-refresh-cw';
});
</script>

<template>
  <span
    class="flex shrink-0 items-center gap-1.5 truncate text-[12px] tabular-nums"
    :class="textClass"
    :title="fullLabel"
  >
    <Spinner v-if="isSyncing" class="size-3 text-amber-500" />
    <Icon v-else :icon="statusIcon" class="size-3.5 shrink-0" />
    <span class="truncate">{{ label }}</span>
    <RelayButton
      v-if="showRetry && canRetry"
      variant="link"
      size="sm"
      class="ms-1 !gap-1 text-primary hover:!no-underline"
      @click.stop="emit('retry')"
    >
      <span class="i-lucide-refresh-cw size-3.5" />
      {{ t('CAPTAIN.DOCUMENTS.OPTIONS.RETRY_SYNC') }}
    </RelayButton>
  </span>
</template>
