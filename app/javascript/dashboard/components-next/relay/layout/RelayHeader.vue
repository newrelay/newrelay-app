<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useKbd } from 'dashboard/composables/utils/useKbd';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { setColorTheme } from 'dashboard/helper/themeHelper';
import RelayNotificationsMenu from './RelayNotificationsMenu.vue';
import RelayWorkspaceMenu from './RelayWorkspaceMenu.vue';

defineProps({
  title: { type: String, default: 'Dashboard' },
  showDesktopToggle: { type: Boolean, default: true },
});

defineEmits([
  'toggleSidebar',
  'openSearch',
  'toggleCollapse',
  'showCreateAccountModal',
  'openKeyShortcutModal',
]);

const { t } = useI18n();
const searchShortcut = useKbd(['$mod', 'k']);

const searchLabel = computed(() => t('COMBOBOX.SEARCH_PLACEHOLDER'));

const toggleTheme = () => {
  const isDark = document.documentElement.classList.contains('dark');
  const nextTheme = isDark ? 'light' : 'dark';
  LocalStorage.set(LOCAL_STORAGE_KEYS.COLOR_SCHEME, nextTheme);
  setColorTheme(window.matchMedia('(prefers-color-scheme: dark)').matches);
  window.dispatchEvent(new CustomEvent('theme-changed'));
};
</script>

<template>
  <header
    class="sticky top-0 z-50 flex h-16 w-full shrink-0 items-center justify-between border-b border-border bg-background px-4 py-3 sm:px-6"
  >
    <div class="flex min-w-0 flex-none items-center gap-3">
      <button
        type="button"
        class="inline-flex size-8 shrink-0 items-center justify-center rounded-md text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring md:hidden"
        @click="$emit('toggleSidebar')"
      >
        <span class="i-lucide-panel-left size-4 shrink-0" />
        <span class="sr-only">{{ t('SIDEBAR.TOGGLE_SIDEBAR') }}</span>
      </button>
      <button
        v-if="showDesktopToggle"
        type="button"
        class="hidden size-8 shrink-0 items-center justify-center rounded-md text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring md:inline-flex"
        @click="$emit('toggleCollapse')"
      >
        <span class="i-lucide-panel-left size-4 shrink-0" />
        <span class="sr-only">{{ t('SIDEBAR.COLLAPSE_SIDEBAR') }}</span>
      </button>
      <h1 class="capitalize truncate text-[16px] font-[500] text-foreground">
        {{ title }}
      </h1>
    </div>

    <div class="hidden flex-1 justify-center px-4 md:flex">
      <button
        type="button"
        class="flex h-10 w-full max-w-md items-center gap-3 rounded-full border border-input bg-background px-4 text-sm text-muted-foreground shadow-xs transition-colors hover:bg-accent/60 hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring cursor-pointer"
        @click="$emit('openSearch')"
      >
        <span class="i-lucide-search size-4 shrink-0 text-muted-foreground" />
        <span class="flex-1 text-left truncate">{{ searchLabel }}</span>
        <kbd
          class="pointer-events-none shrink-0 rounded border border-border bg-muted px-1.5 py-0.5 text-[10px] font-medium text-muted-foreground"
        >
          {{ searchShortcut }}
        </kbd>
      </button>
    </div>

    <div
      class="ml-auto flex shrink-0 flex-none items-center justify-end gap-2 sm:gap-4"
    >
      <slot name="actions" />
      <button
        type="button"
        class="relative inline-flex size-9 scale-100 items-center justify-center rounded-full border border-input bg-background text-muted-foreground shadow-xs transition-colors hover:border-transparent hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
        :aria-label="t('SIDEBAR.TOGGLE_THEME')"
        @click="toggleTheme"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="h-[1.2rem] w-[1.2rem] shrink-0 scale-100 rotate-0 transition-all text-muted-foreground dark:scale-0 dark:-rotate-90"
        >
          <path stroke="none" d="M0 0h24v24H0z" fill="none" />
          <path d="M12 12m-4 0a4 4 0 1 0 8 0a4 4 0 1 0 -8 0" />
          <path
            d="M3 12h1m8 -9v1m8 8h1m-9 8v1m-6.4 -15.4l.7 .7m12.1 -.7l-.7 .7m0 11.4l.7 .7m-12.1 -.7l-.7 .7"
          />
        </svg>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="absolute h-[1.2rem] w-[1.2rem] shrink-0 scale-0 rotate-90 transition-all text-muted-foreground dark:scale-100 dark:rotate-0"
        >
          <path stroke="none" d="M0 0h24v24H0z" fill="none" />
          <path
            d="M12 3c.132 0 .263 0 .393 0a7.5 7.5 0 0 0 7.92 12.446a9 9 0 1 1 -8.313 -12.454z"
          />
        </svg>
        <span class="sr-only">{{ t('SIDEBAR.TOGGLE_THEME') }}</span>
      </button>
      <RelayNotificationsMenu />
      <slot name="profile">
        <RelayWorkspaceMenu
          @show-create-account-modal="$emit('showCreateAccountModal')"
          @open-key-shortcut-modal="$emit('openKeyShortcutModal')"
        />
      </slot>
    </div>
  </header>
</template>
