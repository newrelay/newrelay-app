<script setup>
import { cn } from '../utils/cn';
import { RELAY_FORM_INPUT_FULL_CLASS } from '../form/constants';

const props = defineProps({
  type: { type: String, default: 'text' },
  placeholder: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
  id: { type: String, default: undefined },
  className: { type: String, default: '' },
});

const model = defineModel({ type: [String, Number], default: '' });
</script>

<template>
  <input
    :id="id"
    v-model="model"
    data-slot="input"
    :type="type"
    :placeholder="placeholder"
    :disabled="disabled"
    :class="cn(RELAY_FORM_INPUT_FULL_CLASS, props.className)"
  />
</template>
