<script setup>
import { computed, ref, watch } from 'vue';
import { cn } from '../utils/cn';
import RelayDropdownMenu from '../dropdown-menu/DropdownMenu.vue';
import RelayDropdownMenuTrigger from '../dropdown-menu/DropdownMenuTrigger.vue';
import RelayDropdownMenuContent from '../dropdown-menu/DropdownMenuContent.vue';
import {
  DATE_PICKER_TRIGGER_CLASS,
  TIME_PICKER_COLUMN_CLASS,
  TIME_PICKER_CONTENT_CLASS,
  TIME_PICKER_ITEM_CLASS,
  TIME_PICKER_ITEM_SELECTED_CLASS,
} from './constants';

const props = defineProps({
  modelValue: {
    type: String,
    default: '',
  },
  placeholder: {
    type: String,
    default: '--:-- --',
  },
  align: {
    type: String,
    default: 'start',
  },
  side: {
    type: String,
    default: 'bottom',
  },
  triggerClass: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:modelValue']);

const HOURS = Array.from({ length: 12 }, (_, index) => index + 1);
const MINUTES = Array.from({ length: 60 }, (_, index) => index);
const PERIODS = ['AM', 'PM'];

const selectedHour = ref(12);
const selectedMinute = ref(0);
const selectedPeriod = ref('AM');

const pad = value => String(value).padStart(2, '0');

const formattedValue = computed(
  () =>
    `${pad(selectedHour.value)}:${pad(selectedMinute.value)} ${selectedPeriod.value}`
);

const parseValue = value => {
  if (!value?.trim()) return;

  const match = value.trim().match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
  if (!match) return;

  selectedHour.value = Number(match[1]) || 12;
  selectedMinute.value = Number(match[2]) || 0;
  selectedPeriod.value = match[3].toUpperCase();
};

watch(
  () => props.modelValue,
  value => parseValue(value),
  { immediate: true }
);

const emitValue = () => {
  emit('update:modelValue', formattedValue.value);
};

const selectHour = hour => {
  selectedHour.value = hour;
  emitValue();
};

const selectMinute = minute => {
  selectedMinute.value = minute;
  emitValue();
};

const selectPeriod = period => {
  selectedPeriod.value = period;
  emitValue();
};

const columnItemClass = (isSelected, extraClass = '') =>
  cn(
    TIME_PICKER_ITEM_CLASS,
    'justify-center px-2 py-1.5 text-center',
    isSelected && TIME_PICKER_ITEM_SELECTED_CLASS,
    extraClass
  );
</script>

<template>
  <RelayDropdownMenu>
    <RelayDropdownMenuTrigger as-child>
      <slot name="trigger">
        <button
          type="button"
          :class="cn(DATE_PICKER_TRIGGER_CLASS, triggerClass)"
        >
          <span
            :class="
              !modelValue ? 'text-muted-foreground/60' : 'text-foreground'
            "
          >
            {{ modelValue || placeholder }}
          </span>
          <span class="i-lucide-clock size-4 text-muted-foreground" />
        </button>
      </slot>
    </RelayDropdownMenuTrigger>
    <RelayDropdownMenuContent
      :align="align"
      :side="side"
      :class="TIME_PICKER_CONTENT_CLASS"
    >
      <div class="grid grid-cols-3 gap-1">
        <div :class="TIME_PICKER_COLUMN_CLASS">
          <button
            v-for="hour in HOURS"
            :key="`hour-${hour}`"
            type="button"
            :class="columnItemClass(selectedHour === hour)"
            @click="selectHour(hour)"
          >
            {{ pad(hour) }}
          </button>
        </div>
        <div :class="TIME_PICKER_COLUMN_CLASS">
          <button
            v-for="minute in MINUTES"
            :key="`minute-${minute}`"
            type="button"
            :class="columnItemClass(selectedMinute === minute)"
            @click="selectMinute(minute)"
          >
            {{ pad(minute) }}
          </button>
        </div>
        <div :class="TIME_PICKER_COLUMN_CLASS">
          <button
            v-for="period in PERIODS"
            :key="period"
            type="button"
            :class="columnItemClass(selectedPeriod === period)"
            @click="selectPeriod(period)"
          >
            {{ period }}
          </button>
        </div>
      </div>
    </RelayDropdownMenuContent>
  </RelayDropdownMenu>
</template>
