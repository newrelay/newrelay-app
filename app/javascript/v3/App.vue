<script>
import SnackbarContainer from './components/SnackBar/Container.vue';
import { applyBrandColorVariables } from 'dashboard/helper/colorHelper';
import { setColorTheme } from 'dashboard/helper/themeHelper';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { useAlert } from 'dashboard/composables';
import {
  bindStealthHotkeys,
  isStealthMode,
  syncStealthAppearance,
} from 'dashboard/composables/useStealthMode';

export default {
  components: { SnackbarContainer },
  data() {
    return { theme: 'light' };
  },
  mounted() {
    this.applyTheme();
    this.listenToThemeChanges();
    syncStealthAppearance();
    this.unbindStealthHotkeys = bindStealthHotkeys({
      onToggle: enabled => {
        useAlert(
          this.$t(
            enabled ? 'SIDEBAR.STEALTH_MODE_ON' : 'SIDEBAR.STEALTH_MODE_OFF'
          )
        );
      },
    });
    window.addEventListener('theme-changed', this.onThemeChanged);
    this.setLocale(window.newrelayConfig.selectedLocale);
    if (
      !isStealthMode.value &&
      window.globalConfig &&
      window.globalConfig.BRAND_COLORS
    ) {
      this.applyBrandColors(window.globalConfig.BRAND_COLORS);
    }
  },
  beforeUnmount() {
    this.unbindStealthHotkeys?.();
    window.removeEventListener('theme-changed', this.onThemeChanged);
  },
  methods: {
    applyTheme() {
      setColorTheme(
        window.matchMedia('(prefers-color-scheme: dark)').matches,
        window.globalConfig?.BRAND_COLORS
      );
      this.theme = document.documentElement.classList.contains('dark')
        ? 'dark'
        : 'light';
    },
    onThemeChanged() {
      this.applyTheme();
    },
    listenToThemeChanges() {
      const mql = window.matchMedia('(prefers-color-scheme: dark)');

      mql.onchange = () => {
        const scheme =
          LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || 'auto';
        if (scheme !== 'auto') return;
        this.applyTheme();
      };
    },
    setLocale(locale) {
      if (locale) {
        this.$root.$i18n.locale = locale;
      }
    },
    applyBrandColors(colors) {
      if (!colors || isStealthMode.value) return;
      const isDark = document.documentElement.classList.contains('dark');
      applyBrandColorVariables(colors, { structural: true, dark: isDark });
    },
  },
};
</script>

<template>
  <div
    class="h-full min-h-screen w-full antialiased bg-background text-foreground"
    :class="theme"
  >
    <router-view />
    <SnackbarContainer />
  </div>
</template>

<style lang="scss">
@tailwind base;
@tailwind components;
@tailwind utilities;

@import 'shared/assets/fonts/geist';
@import '../dashboard/assets/scss/next-colors';
@import '../dashboard/assets/scss/relay-theme';

html,
body {
  font-family: var(--font-sans);
  @apply h-full w-full bg-background text-foreground;

  input,
  select {
    outline: none;
  }
}

.text-link {
  @apply text-n-brand font-medium hover:text-n-blue-10;
}

.v-popper--theme-tooltip .v-popper__inner {
  background: black !important;
  font-size: 0.75rem;
  padding: 4px 8px !important;
  border-radius: 6px;
  font-weight: 400;
}

.v-popper--theme-tooltip .v-popper__arrow-container {
  display: none;
}
</style>
