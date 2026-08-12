<script setup>
const emit = defineEmits(['back']);
</script>

<template>
  <section
    class="relative flex h-full w-full flex-col overflow-hidden bg-background animate-in fade-in zoom-in-95 duration-200"
  >
    <slot name="header" :on-back="() => emit('back')" />
    <div class="flex-1 overflow-y-auto">
      <slot />
    </div>
  </section>
</template>
