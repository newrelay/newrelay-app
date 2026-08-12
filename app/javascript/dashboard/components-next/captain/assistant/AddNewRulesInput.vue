<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';

defineProps({
  placeholder: {
    type: String,
    default: '',
  },
  label: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['add']);

const modelValue = defineModel({
  type: String,
  default: '',
});

const onClickAdd = () => {
  if (!modelValue.value?.trim()) return;
  emit('add', modelValue.value.trim());
  modelValue.value = '';
};
</script>

<template>
  <div
    class="flex h-16 items-center gap-3 rounded-xl border border-border bg-card py-3 ltr:pl-3 ltr:pr-4 rtl:pl-4 rtl:pr-3"
  >
    <Icon
      icon="i-lucide-plus"
      class="size-5 flex-shrink-0 text-muted-foreground"
    />

    <InlineInput
      v-model="modelValue"
      :placeholder="placeholder"
      @keyup.enter="onClickAdd"
    />
    <RelayButton
      size="sm"
      class="flex-shrink-0"
      :disabled="!modelValue?.trim()"
      @click="onClickAdd"
    >
      {{ label }}
    </RelayButton>
  </div>
</template>
