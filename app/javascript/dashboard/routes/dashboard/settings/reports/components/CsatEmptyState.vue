<script setup>
defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  icon: {
    type: String,
    default: 'i-lucide-file-text',
  },
});
</script>

<template>
  <div
    class="flex flex-col items-center justify-center min-h-[350px] p-6 text-center"
  >
    <div class="relative mb-6">
      <div
        class="size-20 rounded-full bg-primary/10 flex items-center justify-center"
      >
        <i :class="icon" class="size-9 text-primary/50" />
      </div>
      <div
        class="absolute -bottom-1 -right-1 size-7 rounded-full bg-primary border-[3px] border-card flex items-center justify-center"
      >
        <i class="i-lucide-x size-3 text-white" />
      </div>
    </div>
    <h3 class="text-[16px] font-semibold text-foreground tracking-tight">
      {{ title }}
    </h3>
    <p
      v-if="description"
      class="text-[14px] text-muted-foreground mt-2 max-w-[400px]"
    >
      {{ description }}
    </p>
  </div>
</template>
