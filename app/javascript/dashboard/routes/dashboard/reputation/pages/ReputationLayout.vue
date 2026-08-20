<script setup>
/* eslint-disable */
import { useRoute } from 'vue-router';

const route = useRoute();
</script>

<template>
  <div
    class="flex flex-col h-full w-full bg-background font-sans text-foreground"
  >
    <!-- eslint-disable -->
    <!-- Main content view -->
    <main class="flex-1 overflow-auto">
      <router-view v-slot="{ Component }">
        <transition name="fade" mode="out-in">
          <component :is="Component" :key="route.fullPath" />
        </transition>
      </router-view>
    </main>
  </div>
</template>

<style>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.15s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
