<script setup>
import { useAttrs } from 'vue';
import { cn } from '../utils/cn';

const props = defineProps({
  disabled: { type: Boolean, default: false },
});

defineOptions({ inheritAttrs: false });

const attrs = useAttrs();

const modelValue = defineModel({
  type: Boolean,
  default: false,
});

const toggle = () => {
  if (props.disabled) return;
  modelValue.value = !modelValue.value;
};
</script>

<template>
  <button
    v-bind="{ ...attrs, class: undefined }"
    type="button"
    role="switch"
    :aria-checked="modelValue"
    :disabled="disabled"
    :class="
      cn(
        // p-0 overrides legacy @layer base button py-1 px-2.5 that distort h-5 w-9
        'peer inline-flex h-5 w-9 shrink-0 cursor-pointer items-center rounded-full border-2 border-transparent p-0 shadow-xs transition-colors',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background',
        'disabled:cursor-not-allowed disabled:opacity-50',
        modelValue ? 'bg-primary' : 'bg-input',
        attrs.class
      )
    "
    @click="toggle"
  >
    <span
      :class="
        cn(
          'pointer-events-none block size-4 rounded-full bg-background shadow-lg ring-0 transition-transform',
          modelValue ? 'translate-x-4' : 'translate-x-0'
        )
      "
    />
  </button>
</template>
