<script setup>
import { CALENDAR_PERIODS } from '../helpers/DatePickerHelper';

defineProps({
  calendarType: {
    type: String,
    default: 'start',
  },
  firstButtonLabel: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
  viewMode: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['prev', 'next', 'setView']);

const { YEAR } = CALENDAR_PERIODS;
</script>

<template>
  <div class="mb-6 flex w-full items-center justify-between px-2">
    <button
      type="button"
      class="rounded-full p-1 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
      @click.stop="emit('prev', calendarType)"
    >
      <span class="i-lucide-chevron-left size-4 rtl:rotate-180" />
    </button>
    <div class="flex items-center gap-1">
      <button
        v-if="firstButtonLabel"
        type="button"
        class="p-0 text-sm font-medium text-foreground hover:text-primary"
        @click.stop="emit('setView', calendarType, viewMode)"
      >
        {{ firstButtonLabel }}
      </button>
      <button
        v-if="buttonLabel"
        type="button"
        class="p-0 text-sm font-medium text-foreground"
        :class="{ 'hover:text-primary': viewMode }"
        @click.stop="emit('setView', calendarType, YEAR)"
      >
        {{ buttonLabel }}
      </button>
      <span
        v-if="!firstButtonLabel && buttonLabel"
        class="text-sm font-medium text-foreground"
      >
        {{ buttonLabel }}
      </span>
    </div>
    <button
      type="button"
      class="rounded-full p-1 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
      @click.stop="emit('next', calendarType)"
    >
      <span class="i-lucide-chevron-right size-4 rtl:rotate-180" />
    </button>
  </div>
</template>
