<script setup>
import { RelaySwitch } from 'dashboard/components-next/relay';

defineProps({
  title: { type: String, required: true },
  description: { type: String, default: '' },
  modelValue: { type: Boolean, default: false },
});

defineEmits(['update:modelValue']);
</script>

<template>
  <div class="flex items-center justify-between gap-4">
    <div class="max-w-[380px]">
      <div class="text-[13.5px] font-medium text-foreground">{{ title }}</div>
      <p v-if="description" class="text-xs text-muted-foreground mt-0.5">
        {{ description }}
      </p>
    </div>
    <RelaySwitch
      :model-value="modelValue"
      @update:model-value="$emit('update:modelValue', $event)"
    />
  </div>
</template>
