<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsHeader from './SettingsHeader.vue';
const props = defineProps({
  headerTitle: { type: String, default: '' },
  icon: { type: String, default: '' },
  keepAlive: { type: Boolean, default: true },
  showBackButton: { type: Boolean, default: false },
  backUrl: { type: [String, Object], default: '' },
});

const { t } = useI18n();

const showSettingsHeader = computed(
  () => props.headerTitle || props.icon || props.showBackButton
);
</script>

<template>
  <div class="m-0 flex h-full w-full flex-col bg-background">
    <SettingsHeader
      v-if="showSettingsHeader"
      :icon="icon"
      :header-title="t(headerTitle)"
      :show-back-button="showBackButton"
      :back-url="backUrl"
      class="z-20 mx-auto w-full max-w-7xl"
    />

    <router-view
      v-slot="{ Component }"
      :class="showSettingsHeader ? 'overflow-hidden px-4' : 'overflow-hidden px-0'"
    >
      <component :is="Component" v-if="!keepAlive" :key="$route.fullPath" />
      <keep-alive v-else>
        <component :is="Component" :key="$route.fullPath" />
      </keep-alive>
    </router-view>
  </div>
</template>
