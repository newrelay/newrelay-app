<script>
export default {
  props: {
    headerTitle: {
      type: String,
      default: '',
    },
    headerContent: {
      type: String,
      default: '',
    },
  },
};
</script>

<template>
  <div class="border-b border-solid border-border/60">
    <div class="max-w-7xl w-full mx-auto pt-4 pb-0 px-6">
      <h2 class="capitalize text-base font-medium text-foreground mb-1">
        {{ headerTitle }}
      </h2>
      <p
        v-if="headerContent"
        class="w-full text-[14px] text-muted-foreground mb-2"
      >
        {{ headerContent }}
      </p>
      <slot />
    </div>
  </div>
</template>
