<script setup>
import { ref, computed } from 'vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useMapGetter } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useDraggable, useWindowSize } from '@vueuse/core';

const { uiSettings, updateUISettings } = useUISettings();

const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const showCopilotLauncher = computed(() => {
  const isCaptainEnabled = isFeatureEnabledonAccount.value(
    currentAccountId.value,
    FEATURE_FLAGS.CAPTAIN
  );
  return isCaptainEnabled && !uiSettings.value.is_copilot_panel_open;
});

const toggleSidebar = () => {
  updateUISettings({
    is_copilot_panel_open: !uiSettings.value.is_copilot_panel_open,
    is_contact_sidebar_open: false,
  });
};

const el = ref(null);
const { width } = useWindowSize();

// Position bottom-right by default
const { style, x } = useDraggable(el, {
  initialValue: { x: window.innerWidth - 80, y: window.innerHeight - 80 },
  preventDefault: true,
});

const isLeftHalf = computed(() => x.value < width.value / 2);
const isAiMenuOpen = ref(true);

const toggleAiMenu = () => {
  isAiMenuOpen.value = !isAiMenuOpen.value;
};

let startX = 0;
let startY = 0;

const handlePointerDown = e => {
  startX = e.clientX || (e.touches && e.touches[0]?.clientX) || 0;
  startY = e.clientY || (e.touches && e.touches[0]?.clientY) || 0;
};

const handleLauncherClick = e => {
  const endX =
    e.clientX || (e.changedTouches && e.changedTouches[0]?.clientX) || 0;
  const endY =
    e.clientY || (e.changedTouches && e.changedTouches[0]?.clientY) || 0;
  const deltaX = Math.abs(endX - startX);
  const deltaY = Math.abs(endY - startY);

  // If moved by more than 5px, treat it as a drag, not a click
  if (deltaX > 5 || deltaY > 5) {
    return;
  }
  toggleSidebar();
};
</script>

<template>
  <div
    v-if="showCopilotLauncher"
    ref="el"
    :style="style"
    class="fixed z-[9999] touch-none"
  >
    <!-- Quirky Floating Window -->
    <div
      v-if="isAiMenuOpen"
      class="absolute bottom-full mb-4 w-72 rounded-2xl bg-card p-5 shadow-2xl border border-border/50 animate-in zoom-in-95"
      :class="[
        isLeftHalf
          ? 'left-0 origin-bottom-left'
          : 'right-0 origin-bottom-right',
      ]"
    >
      <!-- Small pointer/triangle at the bottom -->
      <div
        class="absolute -bottom-2 size-4 rotate-45 border-b border-r border-border/50 bg-card"
        :class="isLeftHalf ? 'left-6' : 'right-6'"
      />

      <div class="flex items-start gap-4">
        <div
          class="rounded-full bg-primary/10 p-2.5 text-primary shrink-0 ring-4 ring-primary/5"
        >
          <span class="i-lucide-sparkles size-5 block" />
        </div>
        <div class="relative pr-4">
          <button
            class="absolute -top-1 -right-1 text-muted-foreground hover:text-foreground"
            @click.stop="toggleAiMenu"
          >
            <span class="i-lucide-x size-3.5 block" />
          </button>
          <h4
            class="text-[15px] font-semibold text-foreground mb-1.5 flex items-center gap-1.5"
          >
            {{ $t('CAPTAIN.COPILOT.LAUNCHER.TITLE') }}
          </h4>
          <p class="text-[13px] text-muted-foreground leading-relaxed">
            {{ $t('CAPTAIN.COPILOT.LAUNCHER.DESCRIPTION') }}
          </p>
        </div>
      </div>
    </div>

    <!-- The Button -->
    <button
      class="flex h-14 w-14 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-[0_0_20px_-5px_rgba(0,0,0,0.3)] transition-colors duration-300 hover:bg-primary/90 focus:outline-none cursor-move"
      :title="$t('CAPTAIN.COPILOT.LAUNCHER.DRAG_TITLE')"
      @pointerdown="handlePointerDown"
      @click="handleLauncherClick"
    >
      <span class="i-lucide-brain-circuit size-7 block" />
    </button>
  </div>
  <template v-else />
</template>
