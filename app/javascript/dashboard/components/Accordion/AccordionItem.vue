<script setup>
import EmojiOrIcon from 'shared/components/EmojiOrIcon.vue';

defineProps({
  title: {
    type: String,
    required: true,
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
    class="flex flex-col overflow-visible rounded-xl border border-border/60 bg-card shadow-sm"
    :class="isOpen ? 'p-4' : 'px-4 py-2.5'"
  >
    <button
      type="button"
      class="drag-handle group flex min-h-0 w-full cursor-grab select-none items-center justify-between border-0 bg-transparent px-0 py-0 shadow-none focus-visible:outline-none"
      :class="isOpen ? 'mb-3' : ''"
      @click.stop="onToggle"
    >
      <div class="flex min-w-0 items-center gap-2">
        <span
          v-if="icon && icon.startsWith('i-')"
          class="inline-block size-4 shrink-0 text-primary"
          :class="icon"
        />
        <EmojiOrIcon
          v-else-if="icon || emoji"
          class="inline-block size-4 shrink-0 text-primary"
          :icon="icon"
          :emoji="emoji"
        />
        <h3
          class="mb-0 truncate text-[14px] font-medium leading-none text-foreground"
        >
          {{ title }}
        </h3>
      </div>
      <div class="flex shrink-0 flex-row items-center gap-2">
        <slot name="button" />
        <span
          class="size-4 shrink-0 text-primary transition-transform duration-200"
          :class="isOpen ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        />
      </div>
    </button>
    <div v-if="isOpen">
      <slot />
    </div>
  </div>
</template>
