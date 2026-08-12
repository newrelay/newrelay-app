<script setup>
import EmojiOrIcon from 'shared/components/EmojiOrIcon.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  compact: {
    type: Boolean,
    default: false,
  },
  icon: {
    type: String,
    default: '',
  },
  emoji: {
    type: String,
    default: '',
  },
  isOpen: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['toggle']);

const onToggle = () => {
  emit('toggle');
};
</script>

<template>
  <div
    class="text-sm bg-card border border-border/60 rounded-xl shadow-sm flex flex-col overflow-hidden"
  >
    <button
      class="flex items-center select-none w-full m-0 cursor-grab justify-between py-4 px-5 drag-handle hover:opacity-80 transition-opacity"
      @click.stop="onToggle"
    >
      <div class="flex items-center gap-2">
        <span
          v-if="icon && icon.startsWith('i-')"
          class="inline-block size-4 shrink-0 text-primary"
          :class="icon"
        />
        <EmojiOrIcon
          v-else-if="icon || emoji"
          class="inline-block w-5"
          :icon="icon"
          :emoji="emoji"
        />
        <h5
          class="text-foreground text-[15px] font-semibold mb-0 py-0 pr-2 pl-0"
        >
          {{ title }}
        </h5>
      </div>
      <div class="flex flex-row items-center gap-2">
        <slot name="button" />
        <span
          class="size-[18px] text-primary transition-transform duration-200"
          :class="isOpen ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        />
      </div>
    </button>
    <div v-if="isOpen" :class="compact ? 'p-0 px-5 pb-5' : 'px-5 pb-5'">
      <slot />
    </div>
  </div>
</template>
