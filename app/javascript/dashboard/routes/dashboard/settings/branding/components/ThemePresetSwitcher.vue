<script setup>
import { computed, nextTick, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';
import {
  BRAND_THEME_PRESETS,
  DEFAULT_BRAND_PRESET,
  findMatchingPreset,
  findPresetById,
  presetSwatches,
} from '../brandThemePresets';

const props = defineProps({
  themePreset: { type: String, default: '' },
  primary: { type: String, default: '' },
  secondary: { type: String, default: '' },
  accent: { type: String, default: '' },
  background: { type: String, default: '' },
});

const emit = defineEmits(['select']);
const { t } = useI18n();

const isOpen = ref(false);
const query = ref('');
const triggerRef = ref(null);
const menuRef = ref(null);

const { fixedPosition, updatePosition } = useDropdownPosition(
  triggerRef,
  menuRef,
  isOpen,
  { align: 'end' }
);

const activePreset = computed(() => {
  if (props.themePreset) {
    return findPresetById(props.themePreset) || null;
  }
  return (
    findMatchingPreset({
      primary: props.primary,
      secondary: props.secondary,
      accent: props.accent,
      background: props.background,
    }) || null
  );
});

const filteredPresets = computed(() => {
  const q = query.value.trim().toLowerCase();
  if (!q) return BRAND_THEME_PRESETS;
  return BRAND_THEME_PRESETS.filter(preset =>
    preset.name.toLowerCase().includes(q)
  );
});

const currentSwatches = computed(() => {
  if (activePreset.value) return presetSwatches(activePreset.value);
  if (props.primary) {
    return [
      props.primary,
      props.secondary || '#f2f4f9',
      props.accent || '#edf0ff',
      props.background || '#ffffff',
    ];
  }
  return presetSwatches(DEFAULT_BRAND_PRESET);
});

const currentLabel = computed(
  () =>
    activePreset.value?.name ||
    t('BRANDING_SETTINGS.THEME_SETTINGS.CUSTOM.TITLE')
);

const toggle = async () => {
  isOpen.value = !isOpen.value;
  if (isOpen.value) {
    query.value = '';
    await nextTick();
    updatePosition();
  }
};

const close = () => {
  isOpen.value = false;
};

const handleClickOutside = event => {
  if (triggerRef.value?.contains(event.target)) return;
  close();
};

const selectPreset = preset => {
  emit('select', preset);
  close();
};

const shuffle = () => {
  const pick =
    BRAND_THEME_PRESETS[Math.floor(Math.random() * BRAND_THEME_PRESETS.length)];
  if (pick) emit('select', pick);
};
</script>

<template>
  <div class="relative inline-flex max-w-full shrink-0">
    <button
      ref="triggerRef"
      type="button"
      class="inline-flex h-9 max-w-full min-w-0 shrink items-center gap-2 overflow-hidden rounded-lg border border-border bg-background px-2.5 text-xs font-normal whitespace-nowrap shadow-xs transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-hidden focus-visible:ring-1 focus-visible:ring-ring"
      :aria-label="$t('BRANDING_SETTINGS.THEME_SETTINGS.CHOOSE')"
      :aria-expanded="isOpen"
      @click="toggle"
    >
      <span class="inline-flex gap-0.5" aria-hidden="true">
        <span
          v-for="(color, index) in currentSwatches"
          :key="`${color}-${index}`"
          class="size-4 shrink-0 rounded-sm border border-border"
          :class="index > 0 ? 'hidden sm:inline-block' : ''"
          :style="{ backgroundColor: color }"
        />
      </span>
      <span
        class="hidden max-w-[min(11rem,calc(100vw-7rem))] min-w-0 truncate text-sm sm:block"
      >
        {{ currentLabel }}
      </span>
      <span
        class="i-lucide-chevron-down size-4 shrink-0 text-muted-foreground opacity-70"
      />
    </button>

    <TeleportWithDirection to="body">
      <div
        v-if="isOpen"
        ref="menuRef"
        v-on-click-outside="handleClickOutside"
        :class="fixedPosition.class"
        :style="fixedPosition.style"
        class="z-50 w-72 overflow-hidden rounded-lg border border-border bg-popover p-0 text-popover-foreground shadow-md"
      >
        <div class="flex items-center gap-2 border-b border-border px-3">
          <span class="i-lucide-search size-4 shrink-0 text-muted-foreground" />
          <input
            v-model="query"
            type="search"
            :placeholder="$t('BRANDING_SETTINGS.THEME_SETTINGS.SEARCH')"
            class="h-10 w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground"
          />
        </div>
        <div
          class="flex items-center justify-between px-3 py-2 text-xs text-muted-foreground"
        >
          <span>
            {{
              $t('BRANDING_SETTINGS.THEME_SETTINGS.COUNT', {
                count: filteredPresets.length,
              })
            }}
          </span>
          <button
            type="button"
            class="rounded p-1 transition-colors hover:text-foreground"
            :aria-label="$t('BRANDING_SETTINGS.THEME_SETTINGS.SHUFFLE')"
            @click="shuffle"
          >
            <span class="i-lucide-shuffle size-4" />
          </button>
        </div>
        <div class="max-h-72 overflow-y-auto px-1 pb-1">
          <div class="px-2 py-1.5 text-xs font-medium text-muted-foreground">
            {{ $t('BRANDING_SETTINGS.THEME_SETTINGS.BUILT_IN') }}
          </div>
          <button
            v-for="preset in filteredPresets"
            :key="preset.id"
            type="button"
            class="flex w-full items-center justify-between gap-2 rounded-md px-2 py-1.5 text-sm transition-colors hover:bg-accent hover:text-accent-foreground"
            @click="selectPreset(preset)"
          >
            <span class="flex min-w-0 items-center gap-2 truncate">
              <span class="inline-flex gap-0.5">
                <span
                  v-for="(color, index) in presetSwatches(preset)"
                  :key="`${preset.id}-${index}`"
                  class="size-3.5 shrink-0 rounded-[3px] border border-border"
                  :style="{ backgroundColor: color }"
                />
              </span>
              <span class="truncate">{{ preset.name }}</span>
            </span>
            <span
              v-if="activePreset?.id === preset.id"
              class="i-lucide-check size-4 shrink-0"
            />
          </button>
          <p
            v-if="filteredPresets.length === 0"
            class="py-6 text-center text-sm text-muted-foreground"
          >
            {{ $t('BRANDING_SETTINGS.THEME_SETTINGS.EMPTY') }}
          </p>
        </div>
      </div>
    </TeleportWithDirection>
  </div>
</template>
