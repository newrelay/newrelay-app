<script setup>
import { computed } from 'vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  options: {
    type: Array,
    default: () => [],
    validator: options =>
      options.every(
        opt => typeof opt === 'object' && 'value' in opt && 'label' in opt
      ),
  },
  groups: {
    type: Array,
    default: () => [],
    validator: groups =>
      groups.every(
        group =>
          'label' in group &&
          Array.isArray(group.options) &&
          group.options.every(opt => 'value' in opt && 'label' in opt)
      ),
  },
  placeholder: {
    type: String,
    default: '',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  error: {
    type: String,
    default: '',
  },
});

const modelValue = defineModel({
  type: [String, Number, Boolean],
  default: '',
});

const comboOptions = computed(() => {
  const source = props.groups.length
    ? props.groups.flatMap(group => group.options)
    : props.options;
  return source.map(option => ({
    value: option.value,
    label: option.label,
  }));
});

const comboValue = computed({
  get() {
    const value = modelValue.value;
    if (typeof value === 'boolean') return String(value);
    return value ?? '';
  },
  set(value) {
    modelValue.value = value;
  },
});
</script>

<template>
  <ComboBox
    v-model="comboValue"
    :options="comboOptions"
    :placeholder="placeholder"
    :disabled="disabled"
    :has-error="Boolean(error)"
    :message="error"
    class="w-full min-w-0"
  />
</template>
