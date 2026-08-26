<script setup>
import { computed } from 'vue';
import { RelayCheckbox } from 'dashboard/components-next/relay';
import { ALERT_EVENTS, EVENT_TYPES } from './constants';

const props = defineProps({
  label: {
    type: String,
    default: '',
  },
  value: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update']);

const alertEvents = ALERT_EVENTS;
const alertEventValues = Object.values(EVENT_TYPES);

const selectedValue = computed({
  get: () => {
    // maintain backward compatibility
    if (props.value === 'none') return [];
    if (props.value === 'mine') return [EVENT_TYPES.ASSIGNED];
    if (props.value === 'all') return [...alertEventValues];

    const validValues = props.value
      .split('+')
      .filter(value => alertEventValues.includes(value));

    return [...new Set(validValues)];
  },
  set: value => {
    const sortedValues = value.filter(Boolean).sort();
    const uniqueValues = [...new Set(sortedValues)];

    if (uniqueValues.length === 0) {
      emit('update', 'none');
      return;
    }

    emit('update', uniqueValues.join('+'));
  },
});

const setValue = (isChecked, value) => {
  let updatedValue = selectedValue.value;
  if (isChecked) {
    updatedValue.push(value);
  } else {
    updatedValue = updatedValue.filter(item => item !== value);
  }

  selectedValue.value = updatedValue;
};

const alertDescription = computed(() => {
  const base =
    'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_COMBINATIONS.';

  if (props.value === '' || props.value === 'none') {
    return base + 'NONE';
  }

  return base + selectedValue.value.join('+').toUpperCase();
});
</script>

<template>
  <div>
    <label class="pb-1 text-sm font-medium text-foreground">
      {{ label }}
    </label>
    <div class="mt-2.5 flex flex-col gap-3">
      <div
        v-for="option in alertEvents"
        :key="option.value"
        class="flex items-center gap-3"
      >
        <RelayCheckbox
          :id="`checkbox-${option.value}`"
          :model-value="selectedValue.includes(option.value)"
          @update:model-value="isChecked => setValue(isChecked, option.value)"
        />
        <label
          :for="`checkbox-${option.value}`"
          class="cursor-pointer text-xs font-medium text-foreground"
        >
          {{
            $t(
              `PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPES.${option.label.toUpperCase()}`
            )
          }}
        </label>
      </div>
      <div class="mt-1 text-xs text-muted-foreground">
        {{ $t(alertDescription) }}
      </div>
    </div>
  </div>
</template>
