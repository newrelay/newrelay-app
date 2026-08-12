<script setup>
import { useRouter } from 'vue-router';

defineProps({
  controlItem: {
    type: Object,
    default: () => ({}),
  },
});

const router = useRouter();

const onClick = name => {
  router.push({ name });
};
</script>

<template>
  <div
    :key="controlItem.name"
    class="group flex w-full cursor-pointer flex-col gap-2 rounded-2xl border border-border bg-card p-5 transition-all hover:border-primary/40 hover:shadow-sm"
    @click="onClick(controlItem.routeName)"
  >
    <div class="flex h-8 w-full items-center justify-between gap-1">
      <span
        class="line-clamp-1 text-[14.5px] font-semibold text-foreground transition-colors group-hover:text-primary"
      >
        {{ controlItem.name }}
      </span>
      <span
        class="i-lucide-chevron-right size-4 text-muted-foreground transition-transform group-hover:translate-x-0.5"
      />
    </div>
    <span
      class="line-clamp-5 text-[13px] leading-relaxed text-muted-foreground"
    >
      {{ controlItem.description }}
    </span>
  </div>
</template>
