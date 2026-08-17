<script setup>
import { computed } from 'vue';
import { cn } from '../utils/cn';
import RelayDropdownMenu from '../dropdown-menu/DropdownMenu.vue';
import RelayDropdownMenuTrigger from '../dropdown-menu/DropdownMenuTrigger.vue';
import RelayDropdownMenuContent from '../dropdown-menu/DropdownMenuContent.vue';
import {
  DATE_PICKER_TRIGGER_CLASS,
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
  intervalMinutes: {
    type: Number,
    default: 30,
  },
  startHour: {
    type: Number,
    default: 9,
  },
  endHour: {
    type: Number,
    default: 17,
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

const timeSlots = computed(() => {
  const slots = [];
  const startMinutes = props.startHour * 60;
  const endMinutes = props.endHour * 60;

  for (
    let minutes = startMinutes;
    minutes <= endMinutes;
    minutes += props.intervalMinutes
  ) {
    const hour24 = Math.floor(minutes / 60);
    const minute = minutes % 60;
    const period = hour24 >= 12 ? 'PM' : 'AM';
    const hour12 = hour24 % 12 || 12;
    slots.push(
      `${hour12.toString().padStart(2, '0')}:${minute
        .toString()
        .padStart(2, '0')} ${period}`
    );
  }

  return slots;
});

const selectTime = slot => {
  emit('update:modelValue', slot);
};
</script>

<template>
  <RelayDropdownMenu>
    <RelayDropdownMenuTrigger as-child>
      <slot name="trigger">
        <button
          type="button"
          :class="cn(DATE_PICKER_TRIGGER_CLASS, triggerClass)"
        >
          <span :class="!modelValue ? 'text-muted-foreground' : ''">
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
      <button
        v-for="slot in timeSlots"
        :key="slot"
        type="button"
        :class="
          cn(
            TIME_PICKER_ITEM_CLASS,
            modelValue === slot && TIME_PICKER_ITEM_SELECTED_CLASS
          )
        "
        @click="selectTime(slot)"
      >
        {{ slot }}
      </button>
    </RelayDropdownMenuContent>
  </RelayDropdownMenu>
</template>
