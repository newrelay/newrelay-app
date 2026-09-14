<script setup>
import { computed } from 'vue';
import { isSameDay } from 'date-fns';
import {
  monthName,
  yearName,
  getWeeksForMonth,
  isToday,
  dayIsInRange,
  isCurrentMonth,
  CALENDAR_TYPES,
  CALENDAR_PERIODS,
} from '../helpers/DatePickerHelper';

import CalendarWeekLabel from './CalendarWeekLabel.vue';
import CalendarAction from './CalendarAction.vue';

const props = defineProps({
  calendarType: {
    type: String,
    default: 'start',
  },
  currentDate: Date,
  startCurrentDate: Date,
  endCurrentDate: Date,
  selectedStartDate: Date,
  selectingEndDate: Boolean,
  selectedEndDate: Date,
  hoveredEndDate: Date,
});

const emit = defineEmits([
  'updateHoveredEndDate',
  'selectDate',
  'prev',
  'next',
  'setView',
]);

const { START_CALENDAR } = CALENDAR_TYPES;
const { MONTH } = CALENDAR_PERIODS;

const referenceDate = calendarType =>
  calendarType === START_CALENDAR
    ? props.startCurrentDate
    : props.endCurrentDate;

const effectiveEndDate = computed(() => {
  if (props.selectedEndDate) return props.selectedEndDate;
  if (props.selectingEndDate && props.hoveredEndDate) {
    return props.hoveredEndDate;
  }
  return null;
});

const setViewMode = (type, mode) => {
  emit('setView', type, mode);
};

const onClickPrev = () => {
  emit('prev');
};

const onClickNext = () => {
  emit('next');
};

const weeks = calendarType => getWeeksForMonth(referenceDate(calendarType));

const isInCurrentMonth = (day, calendarType) =>
  isCurrentMonth(day, referenceDate(calendarType));

const isStartEdge = day =>
  props.selectedStartDate && isSameDay(day, props.selectedStartDate);

const isEndEdge = day =>
  effectiveEndDate.value && isSameDay(day, effectiveEndDate.value);

const isInRange = day => {
  if (!props.selectedStartDate || !effectiveEndDate.value) return false;
  return dayIsInRange(day, props.selectedStartDate, effectiveEndDate.value);
};

const isRangeBackgroundDay = (day, calendarType) => {
  if (!isInCurrentMonth(day, calendarType)) return false;
  if (isStartEdge(day) || isEndEdge(day)) return false;
  return isInRange(day);
};

const dayButtonClass = (day, calendarType) => {
  const inCurrentMonth = isInCurrentMonth(day, calendarType);
  const edge = (isStartEdge(day) || isEndEdge(day)) && inCurrentMonth;
  const today = isToday(props.currentDate, day) && inCurrentMonth && !edge;

  return [
    'relative z-10 flex size-8 items-center justify-center rounded-full text-[13px] transition-colors',
    !inCurrentMonth && 'pointer-events-none text-muted-foreground/30',
    inCurrentMonth && !edge && 'text-foreground hover:bg-accent',
    edge && 'bg-primary font-semibold text-primary-foreground shadow-sm',
    today && 'ring-1 ring-primary/40',
  ];
};
</script>

<template>
  <div class="flex w-full max-h-[312px] flex-col gap-2">
    <CalendarAction
      :view-mode="MONTH"
      :calendar-type="calendarType"
      :first-button-label="
        monthName(
          calendarType === START_CALENDAR ? startCurrentDate : endCurrentDate
        )
      "
      :button-label="
        yearName(
          calendarType === START_CALENDAR ? startCurrentDate : endCurrentDate
        )
      "
      @prev="onClickPrev"
      @next="onClickNext"
      @set-view="setViewMode"
    />
    <CalendarWeekLabel />
    <div
      v-for="week in weeks(calendarType)"
      :key="week[0].getTime()"
      class="grid grid-cols-7 gap-y-2"
    >
      <div
        v-for="day in week"
        :key="day.getTime()"
        class="relative flex h-9 items-center justify-center"
        @mouseenter="emit('updateHoveredEndDate', day)"
        @mouseleave="emit('updateHoveredEndDate', null)"
        @click="emit('selectDate', day)"
      >
        <div
          v-if="isStartEdge(day) && isInCurrentMonth(day, calendarType)"
          class="absolute inset-y-0 right-0 w-[85%] rounded-l-full bg-primary/10"
        />
        <div
          v-else-if="isEndEdge(day) && isInCurrentMonth(day, calendarType)"
          class="absolute inset-y-0 left-0 w-[85%] rounded-r-full bg-primary/10"
        />
        <div
          v-else-if="isRangeBackgroundDay(day, calendarType)"
          class="absolute inset-y-0 w-full bg-primary/10"
        />

        <button type="button" :class="dayButtonClass(day, calendarType)">
          {{ day.getDate() }}
        </button>
      </div>
    </div>
  </div>
</template>
