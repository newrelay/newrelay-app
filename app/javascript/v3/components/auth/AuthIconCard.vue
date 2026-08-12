<script setup>
import AuthShell from './AuthShell.vue';

defineProps({
  icon: { type: String, required: true },
});
</script>

<template>
  <AuthShell centered show-theme-toggle>
    <div
      class="w-full max-w-[500px] bg-card rounded-[2rem] shadow-2xl border border-border p-10 relative z-10 flex flex-col items-center text-center"
    >
      <div
        class="size-14 rounded-2xl bg-primary/10 border border-primary/20 flex items-center justify-center mb-6 shadow-sm"
      >
        <span :class="icon" class="size-7 text-primary" />
      </div>
      <slot />
    </div>
  </AuthShell>
</template>
