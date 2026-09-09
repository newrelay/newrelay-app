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
    <div class="flex min-h-0 flex-1 flex-col overflow-y-auto px-8 py-8">
      <div
        class="relative z-10 mx-auto flex min-h-0 w-full max-w-7xl flex-1 flex-col gap-8"
      >
        <!-- Header -->
        <div
          class="flex flex-col sm:flex-row sm:items-center justify-between gap-4"
        >
          <h1 class="text-[20px] font-medium tracking-tight text-foreground">
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
              class="h-10 px-4 text-[13.5px] font-medium gap-2 shadow-sm"
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
