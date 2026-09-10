<script setup>
import { computed, useAttrs } from 'vue';
import { cn } from '../utils/cn';

const props = defineProps({
  disabled: { type: Boolean, default: false },
  indeterminate: { type: Boolean, default: false },
  circle: { type: Boolean, default: false },
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

const dataState = computed(() => {
  if (isIndeterminate.value) return 'indeterminate';
  return isChecked.value ? 'checked' : 'unchecked';
});

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
    :data-state="dataState"
    :disabled="disabled"
    :class="
      cn(
        // p-0 / !rounded-* beat leaked `button { py-1 px-2.5 rounded-lg }`
        // (16px + 8px radius = circle). Default matches NewRelay rounded-[4px].
        'peer inline-flex size-4 shrink-0 items-center justify-center border border-input p-0 shadow-sm transition-colors cursor-pointer',
        props.circle ? '!rounded-full' : '!rounded-[4px]',
        'data-[state=checked]:border-primary data-[state=checked]:bg-primary data-[state=checked]:text-primary-foreground',
        'data-[state=indeterminate]:border-primary data-[state=indeterminate]:bg-primary data-[state=indeterminate]:text-primary-foreground',
        'focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring',
        'disabled:cursor-not-allowed disabled:opacity-50',
        !isChecked && 'bg-background',
        attrs.class
      )
    "
    @click.stop="toggle"
  >
    <span
      v-if="isIndeterminate"
      class="shrink-0 text-current"
      :class="circle ? 'i-lucide-minus size-3' : 'i-lucide-minus size-3.5'"
    />
    <span
      v-else-if="isChecked"
      class="shrink-0 text-current"
      :class="circle ? 'i-lucide-check size-3' : 'i-lucide-check size-3.5'"
    />
  </button>
</template>
