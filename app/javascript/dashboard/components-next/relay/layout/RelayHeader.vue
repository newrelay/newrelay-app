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
        class="inline-flex size-10 shrink-0 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring md:hidden"
        @click="$emit('toggleSidebar')"
      >
        <span class="i-lucide-panel-left size-4" />
        <span class="sr-only">{{ t('SIDEBAR.TOGGLE_SIDEBAR') }}</span>
      </button>
      <button
        v-if="showDesktopToggle"
        type="button"
        class="hidden size-10 shrink-0 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring md:inline-flex"
        @click="$emit('toggleCollapse')"
      >
        <span class="i-lucide-panel-left size-4" />
        <span class="sr-only">{{ t('SIDEBAR.COLLAPSE_SIDEBAR') }}</span>
      </button>
      <h1 class="truncate text-base font-medium text-foreground">
        {{ title }}
      </h1>
    </div>

    <div class="hidden flex-1 justify-center px-4 md:flex">
      <button
        type="button"
        class="flex h-10 w-full max-w-md items-center gap-3 rounded-full border border-input bg-background px-4 text-sm text-muted-foreground shadow-xs transition-colors hover:border-transparent hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
        @click="$emit('openSearch')"
      >
        <span class="i-lucide-search size-4 shrink-0" />
        <span class="flex-1 text-left">{{ searchLabel }}</span>
        <kbd
          class="pointer-events-none rounded border border-border bg-muted px-1.5 py-0.5 text-[10px] font-medium text-muted-foreground"
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
        <span
          class="i-lucide-sun size-[1.2rem] scale-100 rotate-0 transition-all dark:scale-0 dark:-rotate-90"
        />
        <span
          class="i-lucide-moon absolute size-[1.2rem] scale-0 rotate-90 transition-all dark:scale-100 dark:rotate-0"
        />
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
