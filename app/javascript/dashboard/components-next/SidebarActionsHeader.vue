<script setup>
import { RelayTooltip } from 'dashboard/components-next/relay';
import { RELAY_MODAL_CLOSE_BUTTON_CLASS } from 'dashboard/components-next/relay/modal/constants';
import Button from './button/Button.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  buttons: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['click', 'close']);

const handleButtonClick = button => {
  emit('click', button.key);
};
</script>

<template>
  <div
    class="flex h-14 items-center justify-between border-b border-border px-4 shrink-0"
  >
    <div class="flex flex-1 items-center justify-between gap-2">
      <span class="text-sm font-medium text-foreground">{{ title }}</span>
      <div class="flex items-center">
        <RelayTooltip
          v-for="button in buttons"
          :key="button.key"
          :content="button.tooltip"
        >
          <Button
            :icon="button.icon"
            ghost
            sm
            @click="handleButtonClick(button)"
          />
        </RelayTooltip>
        <RelayTooltip :content="$t('GENERAL.CLOSE')">
          <button
            type="button"
            :class="RELAY_MODAL_CLOSE_BUTTON_CLASS"
            @click="$emit('close')"
          >
            <span class="i-lucide-x size-4" />
          </button>
        </RelayTooltip>
      </div>
    </div>
  </div>
</template>
