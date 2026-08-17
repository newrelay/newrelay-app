<script setup>
import { dateRanges } from '../helpers/DatePickerHelper';

defineProps({
  selectedRange: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['setRange']);

const setDateRange = range => {
  emit('setRange', range);
};
</script>

<template>
  <div class="flex w-48 flex-col items-start bg-transparent py-6">
    <h4
      class="mb-2 w-full px-5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground"
    >
      {{ $t('DATE_PICKER.DATE_RANGE_OPTIONS.TITLE') }}
    </h4>
    <div class="flex w-full flex-col items-start">
      <template v-for="range in dateRanges" :key="range.label">
        <div v-if="range.separator" class="w-full border-t border-border/40" />
        <button
          type="button"
          class="w-full truncate px-5 py-2.5 text-left text-[13px] font-medium transition-colors hover:bg-muted/40 hover:text-foreground"
          :class="
            range.value === selectedRange
              ? 'bg-muted/60 font-semibold text-foreground'
              : 'text-muted-foreground'
          "
          @click="setDateRange(range)"
        >
          {{ $t(range.label) }}
        </button>
      </template>
    </div>
  </div>
</template>
