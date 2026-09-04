<script setup>
import { RelayCheckbox } from 'dashboard/components-next/relay';
import { RELAY_FORM_LABEL_CLASS } from 'dashboard/components-next/relay/form/constants';

defineProps({
  label: {
    type: String,
    required: true,
  },
  items: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['change']);
const onChange = (id, value) => {
  emit('change', id, value);
};
</script>

<template>
  <div>
    <label class="block pb-1" :class="[RELAY_FORM_LABEL_CLASS]">
      {{ label }}
    </label>
    <div class="mt-2.5 flex flex-col gap-3">
      <div v-for="item in items" :key="item.id" class="flex items-center gap-3">
        <RelayCheckbox
          :id="`checkbox-condition-${item.value}`"
          :model-value="item.model"
          @update:model-value="val => onChange(item.value, val)"
        />
        <label
          class="cursor-pointer text-xs font-medium text-foreground"
          :for="`checkbox-condition-${item.value}`"
        >
          {{ item.label }}
        </label>
      </div>
    </div>
  </div>
</template>
