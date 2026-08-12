<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import AccountAPI from 'dashboard/api/account';
import { setColorTheme } from 'dashboard/helper/themeHelper';
import ColorPicker from 'dashboard/components-next/colorpicker/ColorPicker.vue';
import { applyBrandColorVariables } from 'dashboard/helper/colorHelper';
import SettingsLayout from '../SettingsLayout.vue';
import SectionLayout from '../account/components/SectionLayout.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';
import MagicBrandingModal from './components/MagicBrandingModal.vue';
import ThemePresetSwitcher from './components/ThemePresetSwitcher.vue';
import {
  DEFAULT_BRAND_PRESET,
  brandColorsFromPreset,
  findPresetById,
} from './brandThemePresets';

const DEFAULT_PRIMARY = DEFAULT_BRAND_PRESET.primary;
const DEFAULT_SECONDARY = DEFAULT_BRAND_PRESET.secondary;
const DEFAULT_ACCENT = DEFAULT_BRAND_PRESET.accent;
const DEFAULT_BACKGROUND = DEFAULT_BRAND_PRESET.background;
const DEFAULT_TEXT = DEFAULT_BRAND_PRESET.text;

const store = useStore();
const { t } = useI18n();
const { accountId } = useAccount();

const getAccount = useMapGetter('accounts/getAccount');
const uiFlags = useMapGetter('accounts/getUIFlags');
const isUpdating = computed(() => uiFlags.value.isUpdating);
const isFetchingItem = computed(() => uiFlags.value.isFetchingItem);

const companyName = ref('');
const brandName = ref('');
const primaryColor = ref(DEFAULT_PRIMARY);
const secondaryColor = ref(DEFAULT_SECONDARY);
const accentColor = ref(DEFAULT_ACCENT);
const backgroundColor = ref(DEFAULT_BACKGROUND);
const textColor = ref(DEFAULT_TEXT);
const themePresetId = ref(DEFAULT_BRAND_PRESET.id);
const activeLayout = ref('classic');
/** Full light token map for the active preset (sidebar, card, muted, …) */
const themeTokenMap = ref(null);

const lightLogoInput = ref(null);
const darkLogoInput = ref(null);
const faviconInput = ref(null);

const lightLogoFile = ref(null);
const darkLogoFile = ref(null);
const faviconFile = ref(null);
const isMagicModalOpen = ref(false);

const lightLogoPreview = computed(() => {
  if (lightLogoFile.value)
    return window.URL.createObjectURL(lightLogoFile.value);
  const account = getAccount.value(accountId.value);
  return account?.logo_url || null;
});

const darkLogoPreview = computed(() => {
  if (darkLogoFile.value) return window.URL.createObjectURL(darkLogoFile.value);
  const account = getAccount.value(accountId.value);
  return account?.dark_logo_url || null;
});

const faviconPreview = computed(() => {
  if (faviconFile.value) return window.URL.createObjectURL(faviconFile.value);
  const account = getAccount.value(accountId.value);
  return account?.favicon_url || null;
});

const activeAccount = computed(() => getAccount.value(accountId.value));

let isWatcherEnabled = false;

function currentBrandColors() {
  const base = {
    primary: primaryColor.value,
    secondary: secondaryColor.value,
    accent: accentColor.value,
    background: backgroundColor.value,
    text: textColor.value,
    theme_preset: themePresetId.value || undefined,
  };
  if (themeTokenMap.value) {
    return { ...themeTokenMap.value, ...base };
  }
  return base;
}

function applyLivePreview() {
  const styleNode = document.getElementById('brand-colors');
  if (styleNode) {
    styleNode.remove();
  }
  const isDark = document.documentElement.classList.contains('dark');
  applyBrandColorVariables(currentBrandColors(), {
    structural: true,
    dark: isDark,
  });
}

function applyBrandColorsToDocument() {
  applyLivePreview();
  setColorTheme(
    window.matchMedia('(prefers-color-scheme: dark)').matches,
    currentBrandColors()
  );
}

let skipNextAccountSync = false;
const initFromAccount = () => {
  if (skipNextAccountSync) {
    skipNextAccountSync = false;
    return;
  }
  if (!activeAccount.value) return;
  isWatcherEnabled = false;

  companyName.value = activeAccount.value.name || '';
  const colors = activeAccount.value.custom_attributes?.brand_colors || {};
  primaryColor.value = colors.primary || DEFAULT_PRIMARY;
  secondaryColor.value = colors.secondary || DEFAULT_SECONDARY;
  accentColor.value = colors.accent || DEFAULT_ACCENT;
  backgroundColor.value = colors.background || DEFAULT_BACKGROUND;
  textColor.value = colors.text || DEFAULT_TEXT;
  themePresetId.value = colors.theme_preset || '';
  const preset = colors.theme_preset
    ? findPresetById(colors.theme_preset)
    : null;
  themeTokenMap.value = preset?.light || (colors.sidebar ? colors : null);
  activeLayout.value = colors.layout || 'classic';
  brandName.value = activeAccount.value.brand_name || colors.brand_name || '';

  nextTick(() => {
    isWatcherEnabled = true;
  });
};

watch(activeAccount, initFromAccount, { immediate: true });

const handleCancel = () => {
  initFromAccount();
  lightLogoFile.value = null;
  darkLogoFile.value = null;
  faviconFile.value = null;
};

const handleResetColors = () => {
  primaryColor.value = DEFAULT_PRIMARY;
  secondaryColor.value = DEFAULT_SECONDARY;
  accentColor.value = DEFAULT_ACCENT;
  backgroundColor.value = DEFAULT_BACKGROUND;
  textColor.value = DEFAULT_TEXT;
  themePresetId.value = DEFAULT_BRAND_PRESET.id;
  themeTokenMap.value = null;
};

const applyPreset = preset => {
  isWatcherEnabled = false;
  primaryColor.value = preset.primary;
  secondaryColor.value = preset.secondary;
  accentColor.value = preset.accent;
  backgroundColor.value = preset.background;
  textColor.value = preset.text;
  themePresetId.value = preset.id;
  themeTokenMap.value = preset.light || null;
  nextTick(() => {
    isWatcherEnabled = true;
    applyLivePreview();
  });
};

const handleSave = async (shouldReload = true) => {
  try {
    const formData = new FormData();
    formData.append('name', companyName.value || '');
    if (lightLogoFile.value) formData.append('logo', lightLogoFile.value);
    if (darkLogoFile.value) formData.append('dark_logo', darkLogoFile.value);
    if (faviconFile.value) formData.append('favicon', faviconFile.value);

    const colorsToSave = themePresetId.value
      ? brandColorsFromPreset(
          findPresetById(themePresetId.value) || {
            id: themePresetId.value,
            primary: primaryColor.value,
            secondary: secondaryColor.value,
            accent: accentColor.value,
            background: backgroundColor.value,
            text: textColor.value,
            light: themeTokenMap.value,
          },
          {
            layout: activeLayout.value,
            brand_name: brandName.value,
            primary: primaryColor.value,
            secondary: secondaryColor.value,
            accent: accentColor.value,
            background: backgroundColor.value,
            text: textColor.value,
          }
        )
      : {
          primary: primaryColor.value,
          secondary: secondaryColor.value,
          accent: accentColor.value,
          background: backgroundColor.value,
          text: textColor.value,
          layout: activeLayout.value,
          brand_name: brandName.value,
        };

    Object.entries(colorsToSave).forEach(([key, value]) => {
      if (value == null || value === '') return;
      // Skip nested maps — only flat scalars (Rails brand_colors: {})
      if (typeof value === 'object') return;
      formData.append(`brand_colors[${key}]`, value);
    });
    formData.append('brand_name', brandName.value);

    store.commit('accounts/SET_ACCOUNT_UI_FLAG', { isUpdating: true });
    const response = await AccountAPI.update(formData);

    skipNextAccountSync = true;
    store.commit('accounts/EDIT_ACCOUNT', response.data);
    lightLogoFile.value = null;
    darkLogoFile.value = null;
    faviconFile.value = null;
    store.commit('accounts/SET_ACCOUNT_UI_FLAG', { isUpdating: false });

    applyBrandColorsToDocument();
    useAlert(t('BRANDING_SETTINGS.SAVE_SUCCESS'));

    if (shouldReload) {
      setTimeout(() => {
        window.location.reload();
      }, 500);
    }
  } catch {
    store.commit('accounts/SET_ACCOUNT_UI_FLAG', { isUpdating: false });
    useAlert(t('BRANDING_SETTINGS.SAVE_ERROR'));
  }
};

const onLightLogoChange = event => {
  const [file] = event.target.files;
  if (file) lightLogoFile.value = file;
};

const onDarkLogoChange = event => {
  const [file] = event.target.files;
  if (file) darkLogoFile.value = file;
};

const onFaviconChange = event => {
  const [file] = event.target.files;
  if (file) faviconFile.value = file;
};

watch(
  [primaryColor, secondaryColor, accentColor, backgroundColor, textColor],
  () => {
    if (!isWatcherEnabled) return;
    // Manual swatch edits leave the full preset catalog — treat as custom branding
    themePresetId.value = '';
    themeTokenMap.value = null;
    applyLivePreview();
  }
);

const handleMagicPaletteApplied = palette => {
  themePresetId.value = '';
  themeTokenMap.value = null;
  if (palette.primary) primaryColor.value = palette.primary;
  if (palette.secondary) secondaryColor.value = palette.secondary;
  if (palette.accent) accentColor.value = palette.accent;
  if (palette.background) backgroundColor.value = palette.background;
  if (palette.text) textColor.value = palette.text;
};
</script>

<template>
  <SettingsLayout :is-loading="isFetchingItem">
    <template #body>
      <div class="flex w-full max-w-3xl flex-col gap-8 ltr:mr-auto rtl:ml-auto">
        <!-- Brand Identity -->
        <SectionLayout
          as-card
          :title="$t('BRANDING_SETTINGS.BRAND_IDENTITY.TITLE')"
          :description="$t('BRANDING_SETTINGS.BRAND_IDENTITY.DESCRIPTION')"
        >
          <div class="space-y-8">
            <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
              <div class="flex flex-col gap-2">
                <RelayLabel html-for="company-name">
                  {{ $t('BRANDING_SETTINGS.COMPANY_NAME.LABEL') }}
                </RelayLabel>
                <RelayInput
                  id="company-name"
                  v-model="companyName"
                  class-name="h-10 shadow-xs bg-background transition-colors hover:bg-accent/30 focus:bg-background"
                  :placeholder="
                    $t('BRANDING_SETTINGS.COMPANY_NAME.PLACEHOLDER')
                  "
                />
              </div>
              <div class="flex flex-col gap-2">
                <RelayLabel html-for="brand-name">
                  {{ $t('BRANDING_SETTINGS.BRAND_NAME.LABEL') }}
                </RelayLabel>
                <RelayInput
                  id="brand-name"
                  v-model="brandName"
                  class-name="h-10 shadow-xs bg-background transition-colors hover:bg-accent/30 focus:bg-background"
                  :placeholder="$t('BRANDING_SETTINGS.BRAND_NAME.PLACEHOLDER')"
                />
              </div>
            </div>

            <div>
              <RelayLabel class="mb-4 block">
                {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.TITLE') }}
              </RelayLabel>
              <div class="grid grid-cols-1 gap-6 md:grid-cols-3">
                <!-- Light Logo -->
                <div
                  class="group flex cursor-pointer flex-col items-center rounded-xl border border-border/60 bg-card p-5 text-center shadow-sm transition-all duration-300 hover:border-primary/30 hover:bg-accent/50 hover:shadow-md"
                  @click="lightLogoInput?.click()"
                >
                  <div
                    class="my-3 flex size-16 items-center justify-center overflow-hidden rounded-2xl border border-dashed border-border/80 bg-muted/40 transition-all duration-300 group-hover:scale-105 group-hover:border-primary/40 group-hover:bg-primary/5"
                  >
                    <img
                      v-if="lightLogoPreview"
                      :src="lightLogoPreview"
                      class="size-full object-contain"
                      :alt="
                        $t('BRANDING_SETTINGS.LOGO_SETTINGS.LIGHT_LOGO.TITLE')
                      "
                    />
                    <span
                      v-else
                      class="i-lucide-sun size-6 text-muted-foreground/60 transition-colors group-hover:text-primary/80"
                    />
                  </div>
                  <h4 class="text-sm font-medium text-foreground">
                    {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.LIGHT_LOGO.TITLE') }}
                  </h4>
                  <p
                    class="mt-1 text-[11px] leading-relaxed text-muted-foreground"
                  >
                    {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.LIGHT_LOGO.NOTE') }}
                  </p>
                  <input
                    ref="lightLogoInput"
                    type="file"
                    accept="image/*"
                    class="hidden"
                    @change="onLightLogoChange"
                    @click.stop
                  />
                  <RelayButton
                    variant="outline"
                    size="sm"
                    class="mt-5 h-8 w-full bg-background text-xs font-medium shadow-none transition-colors group-hover:border-transparent group-hover:bg-primary group-hover:text-primary-foreground"
                    type="button"
                    @click.stop="lightLogoInput?.click()"
                  >
                    {{
                      lightLogoFile
                        ? lightLogoFile.name
                        : $t('BRANDING_SETTINGS.LOGO_SETTINGS.CHOOSE_FILE')
                    }}
                  </RelayButton>
                </div>

                <!-- Dark Logo -->
                <div
                  class="group flex cursor-pointer flex-col items-center rounded-xl border border-border/60 bg-card p-5 text-center shadow-sm transition-all duration-300 hover:border-primary/30 hover:bg-accent/50 hover:shadow-md"
                  @click="darkLogoInput?.click()"
                >
                  <div
                    class="my-3 flex size-16 items-center justify-center overflow-hidden rounded-2xl border border-dashed border-border/80 bg-muted/40 transition-all duration-300 group-hover:scale-105 group-hover:border-primary/40 group-hover:bg-primary/5"
                  >
                    <img
                      v-if="darkLogoPreview"
                      :src="darkLogoPreview"
                      class="size-full object-contain"
                      :alt="
                        $t('BRANDING_SETTINGS.LOGO_SETTINGS.DARK_LOGO.TITLE')
                      "
                    />
                    <span
                      v-else
                      class="i-lucide-moon size-6 text-muted-foreground/60 transition-colors group-hover:text-primary/80"
                    />
                  </div>
                  <h4 class="text-sm font-medium text-foreground">
                    {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.DARK_LOGO.TITLE') }}
                  </h4>
                  <p
                    class="mt-1 text-[11px] leading-relaxed text-muted-foreground"
                  >
                    {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.DARK_LOGO.NOTE') }}
                  </p>
                  <input
                    ref="darkLogoInput"
                    type="file"
                    accept="image/*"
                    class="hidden"
                    @change="onDarkLogoChange"
                    @click.stop
                  />
                  <RelayButton
                    variant="outline"
                    size="sm"
                    class="mt-5 h-8 w-full bg-background text-xs font-medium shadow-none transition-colors group-hover:border-transparent group-hover:bg-primary group-hover:text-primary-foreground"
                    type="button"
                    @click.stop="darkLogoInput?.click()"
                  >
                    {{
                      darkLogoFile
                        ? darkLogoFile.name
                        : $t('BRANDING_SETTINGS.LOGO_SETTINGS.CHOOSE_FILE')
                    }}
                  </RelayButton>
                </div>

                <!-- Favicon -->
                <div
                  class="group flex cursor-pointer flex-col items-center rounded-xl border border-border/60 bg-card p-5 text-center shadow-sm transition-all duration-300 hover:border-primary/30 hover:bg-accent/50 hover:shadow-md"
                  @click="faviconInput?.click()"
                >
                  <div
                    class="my-5 flex size-12 items-center justify-center overflow-hidden rounded-xl border border-dashed border-border/80 bg-muted/40 transition-all duration-300 group-hover:scale-105 group-hover:border-primary/40 group-hover:bg-primary/5"
                  >
                    <img
                      v-if="faviconPreview"
                      :src="faviconPreview"
                      class="size-full object-contain"
                      :alt="$t('BRANDING_SETTINGS.LOGO_SETTINGS.FAVICON.TITLE')"
                    />
                    <span
                      v-else
                      class="i-lucide-globe size-5 text-muted-foreground/60 transition-colors group-hover:text-primary/80"
                    />
                  </div>
                  <h4 class="text-sm font-medium text-foreground">
                    {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.FAVICON.TITLE') }}
                  </h4>
                  <p
                    class="mt-1 text-[11px] leading-relaxed text-muted-foreground"
                  >
                    {{ $t('BRANDING_SETTINGS.LOGO_SETTINGS.FAVICON.NOTE') }}
                  </p>
                  <input
                    ref="faviconInput"
                    type="file"
                    accept="image/x-icon,image/png,image/svg+xml"
                    class="hidden"
                    @change="onFaviconChange"
                    @click.stop
                  />
                  <RelayButton
                    variant="outline"
                    size="sm"
                    class="mt-5 h-8 w-full bg-background text-xs font-medium shadow-none transition-colors group-hover:border-transparent group-hover:bg-primary group-hover:text-primary-foreground"
                    type="button"
                    @click.stop="faviconInput?.click()"
                  >
                    {{
                      faviconFile
                        ? faviconFile.name
                        : $t('BRANDING_SETTINGS.LOGO_SETTINGS.CHOOSE_FILE')
                    }}
                  </RelayButton>
                </div>
              </div>
            </div>

            <!-- Theme Preset (brand colors — light/dark stays in header) -->
            <div
              class="flex flex-col justify-between gap-4 border-t border-border/40 pt-6 md:flex-row md:items-center"
            >
              <div>
                <label
                  class="flex items-center gap-2 text-sm font-medium text-foreground"
                >
                  <span class="i-lucide-palette size-4 text-muted-foreground" />
                  {{ $t('BRANDING_SETTINGS.THEME_SETTINGS.TITLE') }}
                </label>
                <p class="mt-1 text-sm text-muted-foreground">
                  {{ $t('BRANDING_SETTINGS.THEME_SETTINGS.DESCRIPTION') }}
                </p>
              </div>
              <ThemePresetSwitcher
                :theme-preset="themePresetId"
                :primary="primaryColor"
                :secondary="secondaryColor"
                :accent="accentColor"
                :background="backgroundColor"
                @select="applyPreset"
              />
            </div>
          </div>
        </SectionLayout>

        <!-- Brand Colors -->
        <SectionLayout
          as-card
          :title="$t('BRANDING_SETTINGS.COLOR_SETTINGS.TITLE')"
          inline-header
          :description="$t('BRANDING_SETTINGS.COLOR_SETTINGS.DESCRIPTION')"
        >
          <template #headerActions>
            <div class="flex flex-wrap gap-2">
              <RelayButton
                variant="outline"
                class="h-9 gap-2 text-[13px] shadow-none"
                type="button"
                @click="isMagicModalOpen = true"
              >
                <span class="i-lucide-globe size-3.5" />
                {{ $t('BRANDING_SETTINGS.MAGIC_AI.GENERATE_FROM_WEBSITE') }}
              </RelayButton>
              <RelayButton
                variant="outline"
                class="h-9 text-[13px] shadow-none"
                type="button"
                @click="handleResetColors"
              >
                {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.RESET') }}
              </RelayButton>
            </div>
          </template>

          <div class="border-t border-border/40 p-4 sm:p-6">
            <div class="flex flex-wrap items-center gap-8">
              <div>
                <span
                  class="mb-3 block text-xs font-medium text-muted-foreground"
                >
                  {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.PRIMARY') }}
                </span>
                <ColorPicker v-model="primaryColor" />
              </div>
              <div>
                <span
                  class="mb-3 block text-xs font-medium text-muted-foreground"
                >
                  {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.SECONDARY') }}
                </span>
                <ColorPicker v-model="secondaryColor" />
              </div>
              <div>
                <span
                  class="mb-3 block text-xs font-medium text-muted-foreground"
                >
                  {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.ACCENT') }}
                </span>
                <ColorPicker v-model="accentColor" />
              </div>
              <div>
                <span
                  class="mb-3 block text-xs font-medium text-muted-foreground"
                >
                  {{ $t('BRANDING_SETTINGS.COLOR_SETTINGS.TEXT') }}
                </span>
                <ColorPicker v-model="textColor" />
              </div>
            </div>
          </div>
        </SectionLayout>

        <div class="flex justify-end gap-3 border-t border-border/40 pb-2 pt-8">
          <RelayButton variant="outline" type="button" @click="handleCancel">
            {{ $t('BRANDING_SETTINGS.CANCEL') }}
          </RelayButton>
          <RelayButton
            type="button"
            class="shadow-sm"
            :disabled="isUpdating"
            @click="handleSave"
          >
            {{ $t('BRANDING_SETTINGS.SAVE') }}
          </RelayButton>
        </div>

        <MagicBrandingModal
          :show="isMagicModalOpen"
          @close="isMagicModalOpen = false"
          @apply="handleMagicPaletteApplied"
        />
      </div>
    </template>
  </SettingsLayout>
</template>
