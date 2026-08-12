<script setup>
import { computed } from 'vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  allItems: {
    type: Array,
    required: true,
  },
  selectAllLabel: {
    type: String,
    default: '',
  },
  selectedCountLabel: {
    type: String,
    default: '',
  },
  deleteLabel: {
    type: String,
    default: 'Delete',
  },
});

const emit = defineEmits(['bulkDelete']);

const modelValue = defineModel({
  type: Set,
  default: () => new Set(),
});

const selectedCount = computed(() => modelValue.value.size);
const visibleItemIds = computed(() => props.allItems.map(item => item.id));
const visibleItemCount = computed(() => visibleItemIds.value.length);
const selectedVisibleCount = computed(
  () => visibleItemIds.value.filter(id => modelValue.value.has(id)).length
);
const hasSelected = computed(() => selectedCount.value > 0);
const isIndeterminate = computed(
  () =>
    selectedVisibleCount.value > 0 &&
    selectedVisibleCount.value < visibleItemCount.value
);
const allSelected = computed(
  () =>
    visibleItemCount.value > 0 &&
    selectedVisibleCount.value === visibleItemCount.value
);

const toggleSelectAll = () => {
  if (!visibleItemCount.value) {
    return;
  }

  const updatedSelection = new Set(modelValue.value);
  if (allSelected.value) {
    visibleItemIds.value.forEach(id => updatedSelection.delete(id));
  } else {
    visibleItemIds.value.forEach(id => updatedSelection.add(id));
  }
  modelValue.value = updatedSelection;
};
</script>

<template>
  <transition
    name="slide-fade"
    enter-active-class="transition-all duration-200 ease-out"
    enter-from-class="opacity-0"
    enter-to-class="opacity-100"
    leave-active-class="hidden opacity-0"
  >
    <div
      v-if="hasSelected"
      class="mb-6 flex w-full items-center justify-between rounded-xl border border-border bg-card px-4 py-3 shadow-xs"
    >
      <div class="flex min-w-0 items-center gap-4">
        <button
          type="button"
          class="flex items-center gap-2.5 text-[13.5px] font-medium text-foreground transition-opacity hover:opacity-80"
          @click="toggleSelectAll"
        >
          <div
            class="flex size-5 shrink-0 items-center justify-center rounded-full border transition-colors"
            :class="
              allSelected
                ? 'border-primary bg-primary text-primary-foreground shadow-xs'
                : isIndeterminate
                  ? 'border-primary bg-primary/20 text-primary'
                  : 'border-border/80 bg-background/50'
            "
          >
            <span
              v-if="isIndeterminate && !allSelected"
              class="i-lucide-minus size-3 stroke-[3]"
            />
            <span
              v-else-if="allSelected"
              class="i-lucide-check size-3 stroke-[3]"
            />
          </div>
          <span class="truncate tabular-nums">{{ selectAllLabel }}</span>
        </button>
        <span class="truncate text-[13.5px] tabular-nums text-muted-foreground">
          {{ selectedCountLabel }}
        </span>
        <div v-if="$slots.primaryActions" class="h-4 w-px bg-border" />
        <slot v-if="$slots.primaryActions" name="primaryActions" />
      </div>
      <div class="flex items-center gap-3">
        <slot v-if="$slots.secondaryActions" name="secondaryActions" />
        <div v-if="$slots.secondaryActions" class="h-4 w-px bg-border" />
        <div class="flex items-center gap-3">
          <slot name="actions" :selected-count="selectedCount">
            <RelayButton
              variant="ghost"
              size="sm"
              class="h-8 rounded-md border border-border px-3 text-[13px] text-destructive hover:border-transparent hover:bg-destructive/10 hover:text-destructive"
              @click="emit('bulkDelete')"
            >
              <span class="i-lucide-trash-2 mr-1.5 size-3.5" />
              {{ deleteLabel }}
            </RelayButton>
          </slot>
        </div>
      </div>
    </div>
    <div v-else class="flex items-center gap-3">
      <slot name="default-actions" />
    </div>
  </transition>
</template>
