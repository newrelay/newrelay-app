<script setup>
import { computed } from 'vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import { RelayLabel } from 'dashboard/components-next/relay';

const props = defineProps({
  label: { type: String, default: '' },
  options: { type: Array, default: () => [] },
  selected: { type: String, default: '' },
  action: { type: Function, default: () => {} },
});

const comboOptions = computed(() =>
  props.options.map(option => ({ value: option.value, label: option.value }))
);
</script>

<template>
  <div class="flex flex-col gap-1.5">
    <RelayLabel v-if="label" class="text-[13.5px] font-medium text-foreground">
      {{ label }}
    </RelayLabel>
    <ComboBox
      :model-value="selected"
      :options="comboOptions"
      @update:model-value="action"
    />
  </div>
</template>
