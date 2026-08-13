<script>
import FeaturePlaceholder from './FeaturePlaceholder.vue';

export default {
  components: { FeaturePlaceholder },
  props: {
    message: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      default: '',
    },
    variant: {
      type: String,
      default: 'legacy',
      validator: value => ['legacy', 'select'].includes(value),
    },
    icon: {
      type: String,
      default: 'i-lucide-rocket',
    },
  },
};
</script>

<template>
  <div
    v-if="variant === 'select'"
    class="flex flex-1 flex-col items-center justify-center text-center p-8 bg-background h-full w-full"
  >
    <div
      class="size-[72px] rounded-2xl bg-primary/10 ring-1 ring-inset ring-primary/5 shadow-sm flex items-center justify-center mb-6"
    >
      <span :class="icon" class="size-8 text-primary" />
    </div>
    <h3 class="text-xl font-semibold text-foreground mb-3">
      {{ message }}
    </h3>
    <p
      v-if="description"
      class="text-sm text-muted-foreground max-w-[280px] leading-relaxed"
    >
      {{ description }}
    </p>
  </div>

  <div v-else class="flex flex-col items-center justify-center h-full">
    <img
      class="m-4 w-32 hidden dark:block"
      src="dashboard/assets/images/no-chat-dark.svg"
      alt="No Chat dark"
    />
    <img
      class="m-4 w-32 block dark:hidden"
      src="dashboard/assets/images/no-chat.svg"
      alt="No Chat"
    />
    <span class="text-sm text-foreground font-medium text-center">
      {{ message }}
      <br />
    </span>
    <FeaturePlaceholder />
  </div>
</template>
