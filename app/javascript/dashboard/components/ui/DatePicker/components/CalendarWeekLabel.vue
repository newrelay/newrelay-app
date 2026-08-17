<script setup>
import { calendarWeeks } from '../helpers/DatePickerHelper';
</script>

<template>
  <div class="mb-3 grid grid-cols-7">
    <div
      v-for="day in calendarWeeks"
      :key="day.id"
      class="text-center text-[12px] font-medium text-muted-foreground"
    >
      {{ day.label }}
    </div>
  </div>
</template>
