<script setup>
import { provide } from 'vue';
import { cn } from '../utils/cn';

const props = defineProps({
  defaultValue: { type: String, default: undefined },
});

const modelValue = defineModel({ type: String, default: undefined });

if (modelValue.value === undefined && props.defaultValue) {
  modelValue.value = props.defaultValue;
}

provide('relayTabsValue', modelValue);
provide('relayTabsSetValue', value => {
  modelValue.value = value;
});
</script>

<template>
  <div :class="cn('flex flex-col gap-2')">
    <slot />
  </div>
</template>
