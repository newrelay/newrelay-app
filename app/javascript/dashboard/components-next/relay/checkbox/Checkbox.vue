<script setup>
import { computed, useAttrs } from 'vue';
import { cn } from '../utils/cn';

const props = defineProps({
  disabled: { type: Boolean, default: false },
  indeterminate: { type: Boolean, default: false },
});

defineOptions({ inheritAttrs: false });

const attrs = useAttrs();

const modelValue = defineModel({
  type: [Boolean, String],
  default: false,
});

const isIndeterminate = computed(
  () => props.indeterminate || modelValue.value === 'indeterminate'
);
const isChecked = computed(
  () => modelValue.value === true || isIndeterminate.value
);

const toggle = () => {
  if (props.disabled) return;
  if (isIndeterminate.value) {
    modelValue.value = true;
    return;
  }
  modelValue.value = !modelValue.value;
};
</script>

<template>
  <button
    v-bind="{ ...attrs, class: undefined }"
    type="button"
    role="checkbox"
    :aria-checked="isIndeterminate ? 'mixed' : isChecked"
    :disabled="disabled"
    :class="
      cn(
        // p-0 overrides legacy @layer base button py-1 px-2.5 that crush size-4
        'peer inline-flex size-4 shrink-0 items-center justify-center rounded-sm border border-input p-0 shadow-sm transition-colors',
        'focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring',
        'disabled:cursor-not-allowed disabled:opacity-50',
        isChecked
          ? 'border-primary bg-primary text-primary-foreground'
          : 'bg-background text-transparent',
        attrs.class
      )
    "
    @click="toggle"
  >
    <span v-if="isIndeterminate" class="i-lucide-minus size-3.5 shrink-0" />
    <span v-else-if="isChecked" class="i-lucide-check size-3.5 shrink-0" />
  </button>
</template>
