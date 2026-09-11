<script>
import { removeEmoji } from 'shared/helpers/emoji';

export default {
  props: {
    title: {
      type: String,
      default: '',
    },
    color: {
      type: String,
      default: '',
    },
    selected: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['selectLabel'],

  computed: {
    displayTitle() {
      return removeEmoji(this.title) || this.title;
    },
  },

  methods: {
    onClick() {
      this.$emit('selectLabel', this.title);
    },
  },
};
</script>

<template>
  <button
    type="button"
    class="flex w-full min-w-0 items-center justify-between gap-2 rounded-sm px-2 py-1.5 text-left text-[13px] transition-colors"
    :class="
      selected
        ? 'bg-accent text-accent-foreground'
        : 'text-foreground hover:bg-accent hover:text-accent-foreground'
    "
    @click="onClick"
  >
    <span class="flex min-w-0 items-center gap-1.5">
      <span
        v-if="color"
        class="size-3 shrink-0 rounded-full border border-border/60"
        :style="{ backgroundColor: color }"
      />
      <span
        class="overflow-hidden text-ellipsis whitespace-nowrap leading-4"
        :title="displayTitle"
      >
        {{ displayTitle }}
      </span>
    </span>
    <span
      v-if="selected"
      class="i-lucide-check size-3 shrink-0 text-foreground"
    />
  </button>
</template>
