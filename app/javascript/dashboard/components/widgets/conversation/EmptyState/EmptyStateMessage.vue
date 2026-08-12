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
  },
};
</script>

<template>
  <div
    v-if="variant === 'select'"
    class="flex flex-1 flex-col items-center justify-center text-center p-8 bg-muted/10 h-full w-full"
  >
    <div
      class="size-16 rounded-full bg-muted flex items-center justify-center mb-4"
    >
      <span class="i-lucide-message-square size-6 text-muted-foreground" />
    </div>
    <h3 class="text-lg font-medium text-foreground">
      {{ message }}
    </h3>
    <p
      v-if="description"
      class="text-sm text-muted-foreground max-w-sm mt-1"
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
    <span class="text-sm text-n-slate-12 font-medium text-center">
      {{ message }}
      <br />
    </span>
    <FeaturePlaceholder />
  </div>
</template>
