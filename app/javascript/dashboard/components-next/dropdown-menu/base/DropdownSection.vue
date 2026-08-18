<script setup>
defineProps({
  title: {
    type: String,
    default: '',
  },
  height: {
    type: String,
    default: 'max-h-96',
  },
});
</script>

<template>
  <div class="-mx-2 n-dropdown-section">
    <div
      v-if="title"
      class="px-4 mb-3 mt-1 leading-4 font-medium tracking-[0.2px] text-muted-foreground text-xs"
    >
      {{ title }}
    </div>
    <ul
      class="grid list-none gap-2 overflow-y-auto px-2 reset-base no-scrollbar [&::-webkit-scrollbar]:hidden"
      :class="height"
    >
      <slot />
    </ul>
  </div>
</template>
