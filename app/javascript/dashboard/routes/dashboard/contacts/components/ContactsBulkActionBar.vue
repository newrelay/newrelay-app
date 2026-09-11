<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import { RelayCheckbox } from 'dashboard/components-next/relay';
import BulkLabelActions from 'dashboard/components/widgets/conversation/conversationBulkActions/BulkLabelActions.vue';
import Policy from 'dashboard/components/policy.vue';

const props = defineProps({
  visibleContactIds: {
    type: Array,
    default: () => [],
  },
  selectedContactIds: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'clearSelection',
  'assignLabels',
  'removeLabels',
  'toggleAll',
  'deleteSelected',
]);

const { t } = useI18n();

const selectedCount = computed(() => props.selectedContactIds.length);
const totalVisibleContacts = computed(() => props.visibleContactIds.length);

const selectAllLabel = computed(() => {
  if (!totalVisibleContacts.value) {
    return '';
  }

  return t('CONTACTS_BULK_ACTIONS.SELECT_ALL', {
    count: totalVisibleContacts.value,
  });
});

const selectedCountLabel = computed(() =>
  t('CONTACTS_BULK_ACTIONS.SELECTED_COUNT', {
    count: selectedCount.value,
  })
);

const allSelected = computed(() => {
  if (!props.visibleContactIds.length) return false;
  return props.visibleContactIds.every(id =>
    props.selectedContactIds.includes(id)
  );
});

const isIndeterminate = computed(() => {
  if (!props.visibleContactIds.length) return false;
  const selectedOnPage = props.visibleContactIds.filter(id =>
    props.selectedContactIds.includes(id)
  ).length;
  return selectedOnPage > 0 && selectedOnPage < props.visibleContactIds.length;
});

const toggleSelectAll = () => {
  emit('toggleAll', !allSelected.value);
};

const handleAssignLabels = labels => {
  emit('assignLabels', labels);
};

const handleRemoveLabels = labels => {
  emit('removeLabels', labels);
};
</script>

<template>
  <div
    class="flex shrink-0 items-center justify-between gap-4 border-b border-border bg-accent/50 px-4 py-2.5"
  >
    <div class="flex min-w-0 items-center gap-4">
      <div class="flex items-center gap-2.5">
        <RelayCheckbox
          :model-value="allSelected"
          :indeterminate="isIndeterminate"
          @update:model-value="checked => emit('toggleAll', checked)"
        />
        <button
          type="button"
          class="truncate text-[13px] font-medium text-foreground tabular-nums transition-opacity hover:opacity-80"
          @click="toggleSelectAll"
        >
          {{ selectAllLabel }}
        </button>
      </div>
      <span class="truncate text-[13px] tabular-nums text-muted-foreground">
        {{ selectedCountLabel }}
      </span>
      <button
        type="button"
        class="text-[13px] font-medium text-muted-foreground transition-colors hover:text-foreground"
        @click="emit('clearSelection')"
      >
        {{ t('CONTACTS_BULK_ACTIONS.CLEAR_SELECTION') }}
      </button>
    </div>

    <div class="flex items-center gap-4">
      <BulkLabelActions
        type="contact"
        :is-loading="isLoading"
        :disabled="!selectedCount"
        @assign="handleAssignLabels"
      />
      <BulkLabelActions
        type="contact"
        action="remove"
        :is-loading="isLoading"
        :disabled="!selectedCount"
        @remove="handleRemoveLabels"
      />
      <Policy :permissions="['administrator']">
        <button
          type="button"
          class="flex items-center gap-1.5 text-[13px] font-medium text-destructive transition-opacity hover:opacity-80 disabled:cursor-not-allowed disabled:opacity-40"
          :disabled="!selectedCount || isLoading"
          @click="emit('deleteSelected')"
        >
          <span class="i-lucide-trash size-3.5" />
          {{ t('CONTACTS_BULK_ACTIONS.DELETE_CONTACTS') }}
        </button>
      </Policy>
    </div>
  </div>
</template>
