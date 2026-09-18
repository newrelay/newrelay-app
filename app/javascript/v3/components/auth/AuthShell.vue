<script setup>
defineProps({
  /** Centered icon-card pages use mirrored blob positions (forgot / SSO). */
  centered: { type: Boolean, default: false },
});
</script>

<template>
  <div
    data-relay
    class="min-h-screen w-full flex items-center justify-center p-4 !bg-auth-canvas font-sans text-foreground relative overflow-hidden"
  >
    <div
      v-if="centered"
      class="fixed top-0 right-0 w-[600px] h-[600px] bg-primary/10 rounded-full blur-3xl -translate-y-1/2 translate-x-1/3 pointer-events-none"
    />
    <div
      v-if="centered"
      class="fixed bottom-0 left-0 w-[800px] h-[800px] bg-primary/5 rounded-full blur-3xl translate-y-1/3 -translate-x-1/3 pointer-events-none"
    />
    <template v-else>
      <div
        class="fixed top-0 left-0 w-[800px] h-[800px] bg-primary/5 rounded-full blur-3xl -translate-y-1/2 -translate-x-1/3 pointer-events-none"
      />
      <div
        class="fixed bottom-0 right-0 w-[600px] h-[600px] bg-primary/5 rounded-full blur-3xl translate-y-1/3 translate-x-1/3 pointer-events-none"
      />
    </template>

    <slot />
  </div>
</template>
