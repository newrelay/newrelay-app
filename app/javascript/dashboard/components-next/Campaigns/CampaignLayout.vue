<script setup>
import { vOnClickOutside } from '@vueuse/components';
import { RelayButton } from 'dashboard/components-next/relay';

defineProps({
  headerTitle: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['click', 'close']);

const handleButtonClick = () => {
  emit('click');
};
</script>

<template>
  <section
    class="flex flex-col w-full h-full overflow-hidden bg-background/50 animate-in fade-in duration-300"
  >
    <div class="flex-1 overflow-y-auto p-6 lg:px-10">
      <div class="w-full max-w-7xl mx-auto flex flex-col gap-6">
        <!-- Header -->
        <div
          class="flex flex-col sm:flex-row sm:items-center justify-between gap-4"
        >
          <h1 class="text-base font-medium tracking-tight text-foreground">
            {{ headerTitle }}
          </h1>
          <div
            v-on-click-outside="[
              () => emit('close'),
              { ignore: ['dialog.ProseMirror-prompt-backdrop'] },
            ]"
            class="relative group/campaign-button"
          >
            <RelayButton
              variant="default"
              class="h-9 px-4 text-[13.5px] font-medium gap-2 shadow-sm"
              @click="handleButtonClick"
            >
              <span class="i-lucide-plus size-4" />
              {{ buttonLabel }}
            </RelayButton>
            <slot name="action" />
          </div>
        </div>

        <!-- Content -->
        <slot name="default" />
      </div>
    </div>
  </section>
</template>
