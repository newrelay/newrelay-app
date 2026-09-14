<script setup>
import { computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import {
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';
import { RELAY_FILTER_CLASS } from 'dashboard/components-next/relay/chrome/constants';

const props = defineProps({
  options: {
    type: Array,
    required: true,
  },
  modelValue: {
    type: String,
    required: true,
  },
  label: {
    type: String,
    required: true,
  },
  subMenuPosition: {
    type: String,
    default: 'right',
    validator: value => {
      return ['right', 'left', 'bottom'].includes(value);
    },
  },
});

const emit = defineEmits(['update:modelValue']);

const labelValue = computed(() => props.label);

const contentSide = computed(() => {
  if (props.subMenuPosition === 'left') return 'left';
  if (props.subMenuPosition === 'bottom') return 'bottom';
  return 'right';
});

const handleSelect = value => {
  emit('update:modelValue', value);
};
</script>

<template>
  <RelayDropdownMenu>
    <RelayDropdownMenuTrigger as-child>
      <Button
        icon="i-lucide-chevron-down"
        size="sm"
        trailing-icon
        color="slate"
        variant="faded"
        class="!w-fit max-w-40"
        :class="RELAY_FILTER_CLASS"
        :label="labelValue"
      />
    </RelayDropdownMenuTrigger>
    <RelayDropdownMenuContent
      :side="contentSide"
      align="start"
      class="min-w-40 max-w-64"
    >
      <RelayDropdownMenuItem
        v-for="option in options"
        :key="option.value"
        class="justify-end px-2.5"
        @click="handleSelect(option.value)"
      >
        {{ option.label }}
        <span
          v-if="option.value === modelValue"
          class="i-lucide-check ml-auto size-3.5 shrink-0"
        />
      </RelayDropdownMenuItem>
    </RelayDropdownMenuContent>
  </RelayDropdownMenu>
</template>
