<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import BulkSelectBar from 'dashboard/components-next/captain/assistant/BulkSelectBar.vue';
import { RelayButton } from 'dashboard/components-next/relay';
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

const allItems = computed(() =>
  props.visibleContactIds.map(id => ({
    id,
  }))
);

const selectionModel = computed({
  get: () => new Set(props.selectedContactIds),
  set: newSet => {
    if (!props.visibleContactIds.length) {
      emit('toggleAll', false);
      return;
    }

    const shouldSelectAll = props.visibleContactIds.every(id => newSet.has(id));
    emit('toggleAll', shouldSelectAll);
  },
});

const handleAssignLabels = labels => {
  emit('assignLabels', labels);
};

const handleRemoveLabels = labels => {
  emit('removeLabels', labels);
};
</script>

<template>
  <div
    class="mb-4 flex shrink-0 items-center justify-between border-b border-border/40 bg-muted/30 px-0 py-3 animate-in fade-in duration-200"
  >
    <BulkSelectBar
      v-model="selectionModel"
      :all-items="allItems"
      :select-all-label="selectAllLabel"
      :selected-count-label="selectedCountLabel"
      class="!mb-0 w-full justify-between !rounded-none !border-0 !bg-transparent !px-0 !py-0 !shadow-none"
    >
      <template #primaryActions>
        <RelayButton
          variant="ghost"
          size="sm"
          class="ml-2 h-8 border border-border/60 text-muted-foreground hover:border-transparent hover:text-foreground"
          @click="emit('clearSelection')"
        >
          {{ t('CONTACTS_BULK_ACTIONS.CLEAR_SELECTION') }}
        </RelayButton>
      </template>
      <template #actions>
        <div class="ml-auto flex items-center gap-2">
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
            <RelayButton
              variant="outline"
              size="sm"
              class="h-8 gap-2 border-border/80 bg-background font-medium text-destructive shadow-sm hover:bg-destructive/10 hover:text-destructive"
              :disabled="!selectedCount || isLoading"
              :aria-label="t('CONTACTS_BULK_ACTIONS.DELETE_CONTACTS')"
              @click="emit('deleteSelected')"
            >
              <span class="i-lucide-trash size-3.5" />
              <span class="hidden md:inline">
                {{ t('CONTACTS_BULK_ACTIONS.DELETE_CONTACTS') }}
              </span>
            </RelayButton>
          </Policy>
        </div>
      </template>
    </BulkSelectBar>
  </div>
</template>
