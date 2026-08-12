<script setup>
import { computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { ATTRIBUTE_TYPES } from './constants';

const props = defineProps({
  attribute: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['delete']);

const iconByType = {
  [ATTRIBUTE_TYPES.TEXT]: 'i-lucide-align-justify',
  [ATTRIBUTE_TYPES.CHECKBOX]: 'i-lucide-circle-check-big',
  [ATTRIBUTE_TYPES.LIST]: 'i-lucide-list',
  [ATTRIBUTE_TYPES.DATE]: 'i-lucide-calendar',
  [ATTRIBUTE_TYPES.LINK]: 'i-lucide-link',
  [ATTRIBUTE_TYPES.NUMBER]: 'i-lucide-hash',
};

const attributeIcon = computed(() => {
  const typeKey = props.attribute.type?.toLowerCase();
  return iconByType[typeKey] || 'i-lucide-align-justify';
});

const handleDelete = () => {
  emit('delete', props.attribute);
};
</script>

<template>
  <div class="flex w-full items-center justify-between px-4 py-3">
    <div class="flex items-center gap-3">
      <h5 class="text-foreground line-clamp-1 text-sm font-medium">
        {{ attribute.label }}
      </h5>
      <div class="bg-border h-2.5 w-px" />
      <div class="text-muted-foreground flex items-center gap-1.5">
        <Icon :icon="attributeIcon" class="size-4" />
        <span class="text-[13px]">{{ attribute.type }}</span>
      </div>
      <div class="bg-border h-2.5 w-px" />
      <div class="text-muted-foreground flex items-center gap-1.5">
        <Icon icon="i-lucide-key-round" class="size-4" />
        <span class="text-[13px]">{{ attribute.value }}</span>
      </div>
    </div>
    <div class="flex items-center gap-2">
      <Button icon="i-lucide-trash" sm slate ghost @click.stop="handleDelete" />
    </div>
  </div>
</template>
