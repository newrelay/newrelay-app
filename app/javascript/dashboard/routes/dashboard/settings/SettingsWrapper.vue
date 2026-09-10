<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import SettingsSideMenu from './components/SettingsSideMenu.vue';

const props = defineProps({
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

const isProfileShell = computed(() => props.hideSideMenu && props.fullWidth);

const shellInnerClass = computed(() => {
  if (isProfileShell.value) {
    return 'max-w-7xl px-4 sm:px-6 md:px-8 py-8 md:py-12';
  }
  return [
    props.fullWidth ? 'max-w-none' : 'max-w-7xl',
    'gap-8 p-4 pb-12 sm:p-8 lg:flex-row lg:gap-12 lg:px-10 lg:py-8',
  ];
});

const contentMaxClass = computed(() => {
  if (props.fullWidth) return 'max-w-none';
  return 'min-w-0 w-full';
});
</script>

<template>
  <div
    class="flex h-full min-h-0 w-full flex-col overflow-auto text-foreground"
    :class="isProfileShell ? 'bg-muted/10' : 'bg-background'"
  >
    <div
      class="mx-auto flex w-full flex-1 flex-col items-start"
      :class="shellInnerClass"
    >
      <SettingsSideMenu v-if="!hideSideMenu" />

      <div class="min-w-0 w-full flex-1" :class="contentMaxClass">
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
