<script setup>
import { computed, ref } from 'vue';
import {
  addHours,
  format,
  getUnixTime,
  isBefore,
  isSameDay,
  parse,
  setHours,
  setMinutes,
  startOfDay,
  subDays,
} from 'date-fns';
import NextButton from 'dashboard/components-next/button/Button.vue';
import {
  RelayCalendar,
  TIME_PICKER_ITEM_CLASS,
  TIME_PICKER_ITEM_SELECTED_CLASS,
} from 'dashboard/components-next/relay';
import { cn } from 'dashboard/components-next/relay/utils/cn';

const emit = defineEmits(['close', 'chooseTime']);

const selectedDate = ref(null);
const selectedTime = ref('');

const minSelectableTime = computed(() => addHours(new Date(), 1));

const disabledDate = date =>
  isBefore(startOfDay(date), startOfDay(subDays(new Date(), 1)));

const isTimeDisabled = slot => {
  if (!selectedDate.value) return false;
  if (!isSameDay(selectedDate.value, new Date())) return false;

  const parsed = parse(slot, 'hh:mm a', new Date());
  const candidate = setMinutes(
    setHours(selectedDate.value, parsed.getHours()),
    parsed.getMinutes()
  );

  return isBefore(candidate, minSelectableTime.value);
};

const timeSlots = computed(() =>
  Array.from({ length: 48 }, (_, index) => {
    const hour = Math.floor(index / 2);
    const minute = (index % 2) * 30;
    const date = setMinutes(setHours(new Date(), hour), minute);
    return format(date, 'hh:mm a');
  })
);

const canSubmit = computed(
  () =>
    selectedDate.value &&
    selectedTime.value &&
    !isTimeDisabled(selectedTime.value)
);

const chooseTime = () => {
  if (!canSubmit.value) return;

  const parsed = parse(selectedTime.value, 'hh:mm a', selectedDate.value);
  emit('chooseTime', getUnixTime(parsed));
};

const selectTime = slot => {
  if (isTimeDisabled(slot)) return;
  selectedTime.value = slot;
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="chooseTime">
    <div class="flex flex-col gap-4 sm:flex-row">
      <RelayCalendar
        v-model="selectedDate"
        :disabled-date="disabledDate"
        show-footer
        class="shrink-0"
      />
      <div
        class="max-h-[280px] min-w-[9rem] overflow-y-auto rounded-md border border-border p-1"
      >
        <button
          v-for="slot in timeSlots"
          :key="slot"
          type="button"
          :disabled="isTimeDisabled(slot)"
          :class="
            cn(
              TIME_PICKER_ITEM_CLASS,
              selectedTime === slot && TIME_PICKER_ITEM_SELECTED_CLASS,
              isTimeDisabled(slot) && 'pointer-events-none opacity-40'
            )
          "
          @click="selectTime(slot)"
        >
          {{ slot }}
        </button>
      </div>
    </div>
    <div class="flex w-full flex-row justify-end gap-2">
      <NextButton
        faded
        slate
        type="reset"
        :label="$t('CONVERSATION.CUSTOM_SNOOZE.CANCEL')"
        @click.prevent="emit('close')"
      />
      <NextButton
        type="submit"
        :disabled="!canSubmit"
        :label="$t('CONVERSATION.CUSTOM_SNOOZE.APPLY')"
      />
    </div>
  </form>
</template>
