<script setup>
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';

import { RelayButton } from 'dashboard/components-next/relay';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';

defineProps({
  placeholder: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
  confirmLabel: {
    type: String,
    default: '',
  },
  cancelLabel: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['add']);

const modelValue = defineModel({
  type: String,
  default: '',
});

const [showPopover, togglePopover] = useToggle();
const onClickAdd = () => {
  if (!modelValue.value?.trim()) return;
  emit('add', modelValue.value.trim());
  modelValue.value = '';
  togglePopover(false);
};

const onClickCancel = () => {
  togglePopover(false);
};
</script>

<template>
  <div
    v-on-click-outside="() => togglePopover(false)"
    class="relative inline-flex"
  >
    <RelayButton
      variant="outline"
      size="sm"
      class="flex-shrink-0"
      @click="togglePopover(!showPopover)"
    >
      {{ buttonLabel }}
    </RelayButton>
    <div
      v-if="showPopover"
      class="absolute top-9 z-50 flex w-[26.5rem] flex-col gap-5 rounded-xl border border-border bg-background p-4 shadow-xl ltr:left-0 rtl:right-0"
    >
      <InlineInput
        v-model="modelValue"
        :placeholder="placeholder"
        @keyup.enter="onClickAdd"
      />
      <div class="flex justify-between gap-2">
        <RelayButton variant="ghost" size="sm" @click="onClickCancel">
          {{ cancelLabel }}
        </RelayButton>
        <RelayButton size="sm" @click="onClickAdd">
          {{ confirmLabel }}
        </RelayButton>
      </div>
    </div>
  </div>
</template>
