<script setup>
import { cn } from '../utils/cn';
import { RELAY_FORM_TEXTAREA_CLASS } from '../form/constants';

const props = defineProps({
  placeholder: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
  id: { type: String, default: undefined },
  rows: { type: Number, default: undefined },
  maxlength: { type: [Number, String], default: undefined },
  className: { type: String, default: '' },
});

const model = defineModel({ type: String, default: '' });
</script>

<template>
  <textarea
    :id="id"
    v-model="model"
    data-slot="textarea"
    :rows="rows"
    :placeholder="placeholder"
    :disabled="disabled"
    :maxlength="maxlength"
    :class="cn(RELAY_FORM_TEXTAREA_CLASS, props.className)"
  />
</template>
