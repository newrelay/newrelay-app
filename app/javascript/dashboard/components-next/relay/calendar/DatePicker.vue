<script setup>
import { computed } from 'vue';
import { format, isValid, parse, startOfDay } from 'date-fns';
import { cn } from '../utils/cn';
import RelayDropdownMenu from '../dropdown-menu/DropdownMenu.vue';
import RelayDropdownMenuTrigger from '../dropdown-menu/DropdownMenuTrigger.vue';
import RelayDropdownMenuContent from '../dropdown-menu/DropdownMenuContent.vue';
import RelayCalendar from './Calendar.vue';
import { CALENDAR_CONTENT_CLASS, DATE_PICKER_TRIGGER_CLASS } from './constants';

const props = defineProps({
  modelValue: {
    type: [Date, String, null],
    default: null,
  },
  placeholder: {
    type: String,
    default: '',
  },
  displayFormat: {
    type: String,
    default: 'dd-MM-yyyy',
  },
  valueFormat: {
    type: String,
    default: '',
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
  align: {
    type: String,
    default: 'start',
  },
  side: {
    type: String,
    default: 'bottom',
  },
  showFooter: {
    type: Boolean,
    default: true,
  },
  triggerClass: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:modelValue']);

const parsedValue = computed(() => {
  if (!props.modelValue) return null;
  if (props.modelValue instanceof Date) {
    return isValid(props.modelValue) ? startOfDay(props.modelValue) : null;
  }
  if (props.valueFormat) {
    const parsed = parse(props.modelValue, props.valueFormat, new Date());
    return isValid(parsed) ? startOfDay(parsed) : null;
  }
  const parsed = new Date(props.modelValue);
  return isValid(parsed) ? startOfDay(parsed) : null;
});

const displayLabel = computed(() => {
  if (!parsedValue.value) return props.placeholder;
  return format(parsedValue.value, props.displayFormat);
});

const updateValue = date => {
  if (!date) {
    emit('update:modelValue', '');
    return;
  }

  if (props.valueFormat) {
    emit('update:modelValue', format(date, props.valueFormat));
    return;
  }

  emit('update:modelValue', date);
};
</script>

<template>
  <RelayDropdownMenu modal>
    <RelayDropdownMenuTrigger as-child>
      <slot name="trigger">
        <button
          type="button"
          :class="cn(DATE_PICKER_TRIGGER_CLASS, triggerClass)"
        >
          <span
            :class="
              !parsedValue ? 'text-muted-foreground/60' : 'text-foreground'
            "
          >
            {{ displayLabel || placeholder }}
          </span>
          <span class="i-lucide-calendar size-4 text-muted-foreground" />
        </button>
      </slot>
    </RelayDropdownMenuTrigger>
    <RelayDropdownMenuContent
      portal-to="body"
      :align="align"
      :side="side"
      :side-offset="8"
      :collision-padding="16"
      :class="CALENDAR_CONTENT_CLASS"
    >
      <RelayCalendar
        :model-value="parsedValue"
        :min-date="minDate"
        :max-date="maxDate"
        :disabled-date="disabledDate"
        :show-footer="showFooter"
        @update:model-value="updateValue"
        @select="updateValue"
        @clear="updateValue(null)"
      />
    </RelayDropdownMenuContent>
  </RelayDropdownMenu>
</template>
