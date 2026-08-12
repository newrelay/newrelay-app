<script>
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    totalLength: {
      type: Number,
      default: 0,
    },
    currentIndex: {
      type: Number,
      default: 0,
    },
  },
  emits: ['prev', 'next'],
  computed: {
    isUpDisabled() {
      return this.currentIndex === 1;
    },
    isDownDisabled() {
      return this.currentIndex === this.totalLength || this.totalLength <= 1;
    },
  },
  methods: {
    handleUpClick() {
      if (this.currentIndex > 1) {
        this.$emit('prev');
      }
    },
    handleDownClick() {
      if (this.currentIndex < this.totalLength) {
        this.$emit('next');
      }
    },
  },
};
</script>

<template>
  <div class="flex gap-1 items-center">
    <span
      class="whitespace-nowrap text-xs font-semibold text-muted-foreground tabular-nums bg-muted/30 px-2.5 py-1 rounded-md tracking-tight mr-1"
    >
      {{ totalLength <= 1 ? '1' : currentIndex }}
      <template v-if="totalLength > 1"> / {{ totalLength }}</template>
    </span>
    <div class="flex gap-0.5 items-center">
      <NextButton
        icon="i-lucide-chevron-up"
        sm
        slate
        ghost
        class="size-8 [&_span]:size-4"
        :disabled="isUpDisabled"
        @click="handleUpClick"
      />
      <NextButton
        icon="i-lucide-chevron-down"
        sm
        slate
        ghost
        class="size-8 [&_span]:size-4"
        :disabled="isDownDisabled"
        @click="handleDownClick"
      />
    </div>
  </div>
</template>
