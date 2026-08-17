<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  addMonths,
  eachDayOfInterval,
  endOfMonth,
  endOfWeek,
  format,
  isAfter,
  isBefore,
  isSameDay,
  isSameMonth,
  startOfDay,
  startOfMonth,
  startOfWeek,
  subMonths,
} from 'date-fns';
import { cn } from '../utils/cn';
import {
  CALENDAR_CELL_CLASS,
  CALENDAR_DAY_BUTTON_BASE_CLASS,
  CALENDAR_DAY_DEFAULT_CLASS,
  CALENDAR_DAY_OUTSIDE_CLASS,
  CALENDAR_DAY_SELECTED_CLASS,
  CALENDAR_DAY_TODAY_CLASS,
  CALENDAR_DAY_GRID_CLASS,
  CALENDAR_FOOTER_ACTION_CLASS,
  CALENDAR_FOOTER_CLASS,
  CALENDAR_HEADER_CLASS,
  CALENDAR_MONTH_LABEL_CLASS,
  CALENDAR_NAV_BUTTON_CLASS,
  CALENDAR_RANGE_BG_CLASS,
  CALENDAR_RANGE_END_BG_CLASS,
  CALENDAR_RANGE_START_BG_CLASS,
  CALENDAR_WEEKDAY_GRID_CLASS,
} from './constants';

const props = defineProps({
  modelValue: {
    type: Date,
    default: null,
  },
  rangeStart: {
    type: Date,
    default: null,
  },
  rangeEnd: {
    type: Date,
    default: null,
  },
  hoverEnd: {
    type: Date,
    default: null,
  },
  minDate: {
    type: Date,
    default: null,
  },
  maxDate: {
    type: Date,
    default: null,
  },
  disabledDate: {
    type: Function,
    default: null,
  },
  weekStartsOn: {
    type: Number,
    default: 1,
  },
  showFooter: {
    type: Boolean,
    default: true,
  },
  compact: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:modelValue', 'select', 'clear', 'today']);

const { t } = useI18n();

const viewDate = ref(
  startOfMonth(props.modelValue || props.rangeStart || new Date())
);

watch(
  () => props.modelValue,
  value => {
    if (value) viewDate.value = startOfMonth(value);
  }
);

watch(
  () => props.rangeStart,
  value => {
    if (value && !props.modelValue) viewDate.value = startOfMonth(value);
  }
);

const weekdayLabels = computed(() => {
  const labels = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
  if (props.weekStartsOn === 0) {
    return ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];
  }
  return labels;
});

const monthLabel = computed(() => format(viewDate.value, 'MMMM yyyy'));

const calendarDays = computed(() => {
  const monthStart = startOfMonth(viewDate.value);
  const monthEnd = endOfMonth(viewDate.value);
  const gridStart = startOfWeek(monthStart, {
    weekStartsOn: props.weekStartsOn,
  });
  const gridEnd = endOfWeek(monthEnd, { weekStartsOn: props.weekStartsOn });

  return eachDayOfInterval({ start: gridStart, end: gridEnd });
});

const effectiveRangeEnd = computed(() => {
  if (props.rangeEnd) return props.rangeEnd;
  if (props.hoverEnd) return props.hoverEnd;
  return null;
});

const isDisabledDay = day => {
  const normalizedDay = startOfDay(day);
  if (props.disabledDate?.(normalizedDay)) return true;
  if (props.minDate && isBefore(normalizedDay, startOfDay(props.minDate))) {
    return true;
  }
  if (props.maxDate && isAfter(normalizedDay, startOfDay(props.maxDate))) {
    return true;
  }
  return false;
};

const isSelectedDay = day => {
  if (props.modelValue) return isSameDay(day, props.modelValue);
  return false;
};

const isRangeEdge = day => {
  if (props.rangeStart && isSameDay(day, props.rangeStart)) return true;
  if (effectiveRangeEnd.value && isSameDay(day, effectiveRangeEnd.value)) {
    return true;
  }
  return false;
};

const isInSelectedRange = day => {
  if (!props.rangeStart || !effectiveRangeEnd.value) return false;

  const start = startOfDay(props.rangeStart);
  const end = startOfDay(effectiveRangeEnd.value);
  const normalizedDay = startOfDay(day);

  if (start <= end) {
    return normalizedDay >= start && normalizedDay <= end;
  }

  return normalizedDay >= end && normalizedDay <= start;
};

const isRangeStartEdge = day =>
  props.rangeStart && isSameDay(day, props.rangeStart);

const isRangeEndEdge = day =>
  effectiveRangeEnd.value && isSameDay(day, effectiveRangeEnd.value);

const showRangeBackground = day => isInSelectedRange(day) && !isRangeEdge(day);

const dayButtonClass = day => {
  const inCurrentMonth = isSameMonth(day, viewDate.value);
  const selected = isSelectedDay(day) || (isRangeEdge(day) && inCurrentMonth);
  const today = isSameDay(day, new Date());

  return cn(
    CALENDAR_DAY_BUTTON_BASE_CLASS,
    !inCurrentMonth && CALENDAR_DAY_OUTSIDE_CLASS,
    inCurrentMonth &&
      !selected &&
      !isDisabledDay(day) &&
      CALENDAR_DAY_DEFAULT_CLASS,
    inCurrentMonth && selected && CALENDAR_DAY_SELECTED_CLASS,
    inCurrentMonth && today && !selected && CALENDAR_DAY_TODAY_CLASS,
    isDisabledDay(day) && 'pointer-events-none opacity-40'
  );
};

const prevMonth = () => {
  viewDate.value = subMonths(viewDate.value, 1);
};

const nextMonth = () => {
  viewDate.value = addMonths(viewDate.value, 1);
};

const selectDay = day => {
  if (!isSameMonth(day, viewDate.value) || isDisabledDay(day)) return;
  emit('update:modelValue', startOfDay(day));
  emit('select', startOfDay(day));
};

const clearSelection = () => {
  emit('update:modelValue', null);
  emit('clear');
};

const selectToday = () => {
  const today = startOfDay(new Date());
  viewDate.value = startOfMonth(today);
  emit('update:modelValue', today);
  emit('select', today);
  emit('today', today);
};
</script>

<template>
  <div :class="compact ? 'w-[220px]' : 'w-[252px]'">
    <div :class="CALENDAR_HEADER_CLASS">
      <button
        type="button"
        :class="CALENDAR_NAV_BUTTON_CLASS"
        :aria-label="t('DATE_PICKER.PREVIOUS_PERIOD')"
        @click="prevMonth"
      >
        <span class="i-lucide-chevron-left size-4" />
      </button>
      <div :class="CALENDAR_MONTH_LABEL_CLASS">{{ monthLabel }}</div>
      <button
        type="button"
        :class="CALENDAR_NAV_BUTTON_CLASS"
        :aria-label="t('DATE_PICKER.NEXT_PERIOD')"
        @click="nextMonth"
      >
        <span class="i-lucide-chevron-right size-4" />
      </button>
    </div>

    <div :class="CALENDAR_WEEKDAY_GRID_CLASS">
      <div v-for="label in weekdayLabels" :key="label">{{ label }}</div>
    </div>

    <div :class="CALENDAR_DAY_GRID_CLASS">
      <div
        v-for="day in calendarDays"
        :key="day.getTime()"
        :class="CALENDAR_CELL_CLASS"
      >
        <div
          v-if="isRangeStartEdge(day)"
          :class="CALENDAR_RANGE_START_BG_CLASS"
        />
        <div
          v-else-if="isRangeEndEdge(day)"
          :class="CALENDAR_RANGE_END_BG_CLASS"
        />
        <div
          v-else-if="showRangeBackground(day)"
          :class="CALENDAR_RANGE_BG_CLASS"
        />

        <button
          type="button"
          :class="dayButtonClass(day)"
          :disabled="isDisabledDay(day)"
          @click="selectDay(day)"
        >
          {{ day.getDate() }}
        </button>
      </div>
    </div>

    <div v-if="showFooter" :class="CALENDAR_FOOTER_CLASS">
      <button
        type="button"
        :class="CALENDAR_FOOTER_ACTION_CLASS"
        @click="clearSelection"
      >
        {{ t('DATE_PICKER.CLEAR_BUTTON') }}
      </button>
      <button
        type="button"
        :class="CALENDAR_FOOTER_ACTION_CLASS"
        @click="selectToday"
      >
        {{ t('DATE_PICKER.TODAY_BUTTON') }}
      </button>
    </div>
  </div>
</template>
