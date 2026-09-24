<script setup>
import { nextTick, ref } from 'vue';
import { Chrome } from '@lk77/vue3-color';
import { onClickOutside } from '@vueuse/core';

import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  modelValue: {
    type: String,
    default: '',
  },
  variant: {
    type: String,
    default: 'default',
    validator: value => ['default', 'swatch'].includes(value),
  },
});

const emit = defineEmits(['update:modelValue']);

const isPickerOpen = ref(false);
const triggerRef = ref(null);
const pickerEl = ref(null);
const pickerStyle = ref({});

const placePicker = () => {
  const trigger = triggerRef.value;
  if (!trigger) return;
  const rect = trigger.getBoundingClientRect();
  const width = 225;
  const height = pickerEl.value?.offsetHeight || 240;
  const gap = 8;
  const spaceBelow = window.innerHeight - rect.bottom;
  const openUp = spaceBelow < height + gap && rect.top > spaceBelow;
  const top = openUp ? rect.top - height - gap : rect.bottom + gap;
  const left = Math.min(Math.max(8, rect.left), window.innerWidth - width - 8);
  pickerStyle.value = {
    top: `${Math.max(8, top)}px`,
    left: `${left}px`,
  };
};

const toggleColorPicker = async () => {
  isPickerOpen.value = !isPickerOpen.value;
  if (!isPickerOpen.value) return;
  await nextTick();
  placePicker();
};

const closeTogglePicker = () => {
  isPickerOpen.value = false;
};

onClickOutside(triggerRef, closeTogglePicker, { ignore: [pickerEl] });

const updateColor = e => {
  emit('update:modelValue', e.hex);
};
</script>

<template>
  <div ref="triggerRef" class="relative w-fit">
    <Button
      v-if="variant === 'default'"
      color="slate"
      icon="i-lucide-pipette"
      trailing-icon
      class="!px-3 !py-3 [&>svg]:w-4 [&>svg]:h-4"
      @click="toggleColorPicker"
    >
      <div class="flex items-center flex-grow gap-2">
        <span
          class="rounded-md size-4"
          :style="{ backgroundColor: modelValue }"
        />
        <span class="min-w-0 truncate">{{ modelValue }}</span>
      </div>
    </Button>
    <button
      v-else
      type="button"
      class="relative size-9 shrink-0 overflow-hidden rounded-[4px] border border-border/80 bg-background p-0.5 shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
      @click="toggleColorPicker"
    >
      <div
        class="size-full rounded-[2px]"
        :style="{ backgroundColor: modelValue }"
      />
    </button>
  </div>
  <Teleport to="body">
    <div
      v-if="isPickerOpen"
      ref="pickerEl"
      class="fixed z-[9999]"
      :style="pickerStyle"
    >
      <Chrome
        disable-alpha
        :model-value="modelValue"
        class="colorpicker--chrome !static"
        @update:model-value="updateColor"
      />
    </div>
  </Teleport>
</template>

<style scoped lang="scss">
.colorpicker--chrome.vc-chrome {
  @apply shadow-lg bg-background border border-border dark:border-border rounded-[8px];

  :deep() {
    .vc-chrome-saturation-wrap {
      @apply rounded-t-[7px];

      .vc-saturation {
        @apply rounded-t-[8px];
      }
    }

    .vc-chrome-body {
      @apply rounded-b-[7px] bg-accent;

      .vc-chrome-toggle-btn {
        .vc-chrome-toggle-icon svg {
          @apply [&>path]:fill-muted-foreground dark:[&>path]:fill-muted-foreground left-3 relative;
        }
        .vc-chrome-toggle-icon-highlight {
          @apply bg-background;
        }
      }
    }

    input,
    .vc-input__input {
      @apply bg-background text-foreground rounded-md shadow-none;
    }

    .vc-input__label {
      @apply text-muted-foreground dark:text-muted-foreground;
    }
  }
}
</style>
