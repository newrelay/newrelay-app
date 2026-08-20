<script setup>
/* eslint-disable */
import { useRoute } from 'vue-router';

const route = useRoute();
</script>

<template>
  <div
    class="flex flex-col h-full w-full bg-background font-sans text-foreground"
  >
    <main class="flex-1 overflow-auto">
      <router-view />
    </main>
  </div>
</template>
