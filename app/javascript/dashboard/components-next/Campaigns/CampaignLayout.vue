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
  <section class="flex flex-col w-full h-full overflow-hidden bg-background">
    <header
      class="sticky top-0 z-10 px-8 border-b border-border/60 bg-background/80 backdrop-blur-md shrink-0"
    >
      <div class="w-full max-w-7xl mx-auto">
        <div class="flex items-center justify-between w-full h-16 gap-4">
          <h1 class="text-xl font-semibold tracking-tight text-foreground">
            {{ headerTitle }}
          </h1>
          <div
            v-on-click-outside="[
              () => emit('close'),
              // This will prevent closing the modal when the editor Create link popup is open
              { ignore: ['dialog.ProseMirror-prompt-backdrop'] },
            ]"
            class="relative group/campaign-button"
          >
            <RelayButton
              variant="default"
              size="sm"
              class="h-9 gap-2 font-medium shadow-xs"
              @click="handleButtonClick"
            >
              <span class="i-lucide-plus size-4" />
              {{ buttonLabel }}
            </RelayButton>
            <slot name="action" />
          </div>
        </div>
      </div>
    </header>

    <main
      class="flex-1 flex flex-col min-h-0 px-8 py-8 overflow-y-auto bg-background/50"
    >
      <div class="w-full max-w-7xl mx-auto flex-1 flex flex-col">
        <slot name="default" />
      </div>
    </main>
  </section>
</template>
