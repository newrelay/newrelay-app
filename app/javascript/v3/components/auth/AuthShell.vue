<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { setColorTheme } from 'dashboard/helper/themeHelper';

defineProps({
  /** Centered icon-card pages use mirrored blob positions (forgot / SSO). */
  centered: { type: Boolean, default: false },
  showThemeToggle: { type: Boolean, default: true },
});

const { t } = useI18n();
const isDark = ref(false);

const syncFromDom = () => {
  isDark.value = document.documentElement.classList.contains('dark');
};

const toggleTheme = () => {
  const nextTheme = isDark.value ? 'light' : 'dark';
  LocalStorage.set(LOCAL_STORAGE_KEYS.COLOR_SCHEME, nextTheme);
  setColorTheme(
    window.matchMedia('(prefers-color-scheme: dark)').matches,
    window.globalConfig?.BRAND_COLORS
  );
  isDark.value = nextTheme === 'dark';
  window.dispatchEvent(new CustomEvent('theme-changed'));
};

onMounted(syncFromDom);
</script>

<template>
  <div
    data-relay
    class="min-h-screen w-full flex items-center justify-center p-4 !bg-auth-canvas font-sans text-foreground relative overflow-hidden"
  >
    <div v-if="showThemeToggle" class="absolute top-6 right-6 z-50">
      <button
        type="button"
        class="size-9 rounded-full border border-border bg-background hover:bg-muted/50 transition-colors shadow-sm flex items-center justify-center text-muted-foreground hover:text-foreground outline-none cursor-pointer"
        :aria-label="isDark ? t('AUTH.THEME.LIGHT') : t('AUTH.THEME.DARK')"
        @click="toggleTheme"
      >
        <span v-if="!isDark" class="i-lucide-sun size-[18px]" />
        <span v-else class="i-lucide-moon size-[18px]" />
      </button>
    </div>

    <div
      v-if="centered"
      class="fixed top-0 right-0 w-[600px] h-[600px] bg-primary/10 rounded-full blur-3xl -translate-y-1/2 translate-x-1/3 pointer-events-none"
    />
    <div
      v-if="centered"
      class="fixed bottom-0 left-0 w-[800px] h-[800px] bg-primary/5 rounded-full blur-3xl translate-y-1/3 -translate-x-1/3 pointer-events-none"
    />
    <template v-else>
      <div
        class="fixed top-0 left-0 w-[800px] h-[800px] bg-primary/5 rounded-full blur-3xl -translate-y-1/2 -translate-x-1/3 pointer-events-none"
      />
      <div
        class="fixed bottom-0 right-0 w-[600px] h-[600px] bg-primary/5 rounded-full blur-3xl translate-y-1/3 translate-x-1/3 pointer-events-none"
      />
    </template>

    <slot />
  </div>
</template>
