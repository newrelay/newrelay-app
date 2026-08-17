<script setup>
import { computed } from 'vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  totalLength: {
    type: Number,
    default: 0,
  },
  currentIndex: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['prev', 'next']);

const isUpDisabled = computed(() => props.currentIndex <= 1);
const isDownDisabled = computed(
  () => props.currentIndex >= props.totalLength || props.totalLength <= 1
);

const handleUpClick = () => {
  if (!isUpDisabled.value) emit('prev');
};

const handleDownClick = () => {
  if (!isDownDisabled.value) emit('next');
};
</script>

<template>
  <div class="flex items-center gap-1">
    <span
      class="mr-2 whitespace-nowrap rounded-md bg-muted/30 px-2.5 py-1 text-xs font-semibold tracking-tight text-muted-foreground tabular-nums"
    >
      {{ currentIndex }} / {{ totalLength || 1 }}
    </span>
    <RelayButton
      variant="ghost"
      size="icon"
      class="size-8 border-transparent text-muted-foreground hover:border-transparent hover:text-foreground"
      :disabled="isUpDisabled"
      @click="handleUpClick"
    >
      <span class="i-lucide-chevron-up size-4" />
    </RelayButton>
    <RelayButton
      variant="ghost"
      size="icon"
      class="size-8 border-transparent text-muted-foreground hover:border-transparent hover:text-foreground"
      :disabled="isDownDisabled"
      @click="handleDownClick"
    >
      <span class="i-lucide-chevron-down size-4" />
    </RelayButton>
  </div>
</template>
