<script setup>
import { useRoute } from 'vue-router';
import SettingsSideMenu from './components/SettingsSideMenu.vue';

defineProps({
  keepAlive: {
    type: Boolean,
    default: true,
  },
  hideSideMenu: {
    type: Boolean,
    default: false,
  },
  fullWidth: {
    type: Boolean,
    default: false,
  },
});

const route = useRoute();
</script>

<template>
  <div
    class="flex h-full min-h-0 w-full flex-col overflow-auto bg-background text-foreground"
  >
    <div
      class="mx-auto flex w-full flex-1 flex-col items-start gap-8 p-4 pb-12 sm:p-6 lg:flex-row lg:gap-12 lg:px-10 lg:py-8"
      :class="fullWidth ? 'max-w-none' : 'max-w-7xl'"
    >
      <SettingsSideMenu v-if="!hideSideMenu" />

      <div
        class="min-w-0 w-full flex-1"
        :class="
          fullWidth ? 'max-w-none' : hideSideMenu ? 'max-w-5xl' : 'max-w-4xl'
        "
      >
        <router-view v-slot="{ Component }">
          <keep-alive v-if="keepAlive">
            <component :is="Component" :key="route.fullPath" />
          </keep-alive>
          <component :is="Component" v-else :key="route.fullPath" />
        </router-view>
      </div>
    </div>
  </div>
</template>
