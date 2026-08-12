<script setup>
import Policy from 'dashboard/components/policy.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  subtitle: {
    type: String,
    required: true,
  },
  actionPerms: {
    type: Array,
    default: () => [],
  },
  showBackdrop: {
    type: Boolean,
    default: true,
  },
});

defineOptions({
  inheritAttrs: false,
});
</script>

<template>
  <section
    class="relative flex min-h-[420px] h-full w-full flex-1 flex-col items-center justify-center overflow-hidden rounded-xl py-12 text-center my-auto"
  >
    <div
      v-if="showBackdrop"
      class="pointer-events-none absolute inset-0 z-0 flex select-none flex-col gap-3 overflow-hidden opacity-30"
      aria-hidden="true"
    >
      <div
        class="absolute inset-0 z-10 bg-gradient-to-t from-background via-background/60 to-transparent"
      />
      <div class="relative z-0 flex w-full flex-col gap-3">
        <slot name="empty-state-item" />
      </div>
    </div>

    <div
      class="relative z-20 flex flex-col items-center justify-center px-4 max-w-lg mx-auto"
    >
      <h2
        class="mb-2.5 text-[20px] font-semibold tracking-tight text-foreground"
      >
        {{ title }}
      </h2>
      <div v-if="subtitle" class="relative mx-auto mb-6 max-w-md">
        <p class="text-[14.5px] leading-relaxed text-muted-foreground">
          {{ subtitle }}
        </p>
      </div>
      <Policy :permissions="actionPerms">
        <slot name="actions" />
      </Policy>
    </div>
  </section>
</template>
