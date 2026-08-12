import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import {
  applyBrandColorVariables,
  clearCustomThemeVariables,
  hasFullThemePreset,
  isDarkBackground,
} from './colorHelper';

// layout / empty brand_name alone must not count as color branding
const brandPalette = colors =>
  colors &&
  (colors.primary ||
    colors.secondary ||
    colors.accent ||
    colors.text ||
    colors.background ||
    colors.theme_preset ||
    colors.sidebar)
    ? colors
    : null;

export const setColorTheme = (isOSOnDarkMode, brandColors) => {
  const selectedColorScheme =
    LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || 'auto';

  // If we are moving away from custom, ensure inline custom backgrounds are cleared.
  // But skip clearing if BRAND_COLORS are injected by the server (custom domain branding).
  const hasDomainBranding = Boolean(
    brandPalette(window.globalConfig && window.globalConfig.BRAND_COLORS)
  );

  const activeBrandColors =
    brandPalette(brandColors) ||
    (hasDomainBranding ? window.globalConfig.BRAND_COLORS : null);

  const hasActiveColors = Boolean(activeBrandColors);
  const isStandardMode =
    selectedColorScheme === 'light' || selectedColorScheme === 'dark';
  const hasPreset = hasFullThemePreset(activeBrandColors);

  // Full theme presets always re-apply light/dark token maps (like new-ui).
  // Custom 4-swatch branding: light/dark clears structural overrides, keeps accents.
  if (isStandardMode && !hasPreset) {
    clearCustomThemeVariables();
    applyBrandColorVariables(activeBrandColors, {
      structural: false,
      dark: selectedColorScheme === 'dark',
    });
  } else if (!hasDomainBranding && !hasActiveColors) {
    clearCustomThemeVariables();
  }

  const isBrandDark =
    activeBrandColors &&
    activeBrandColors.background &&
    isDarkBackground(activeBrandColors.background);

  let isDark =
    (selectedColorScheme === 'auto' && isOSOnDarkMode) ||
    selectedColorScheme === 'dark';

  // For custom theme or auto-theme with active branding, derive dark/light from the brand colors
  // — unless a full theme preset is active (then header light/dark owns mode, like new-ui).
  if (selectedColorScheme === 'custom') {
    isDark = !!isBrandDark;
  } else if (
    selectedColorScheme === 'auto' &&
    (hasDomainBranding || hasActiveColors) &&
    !hasPreset
  ) {
    isDark = !!isBrandDark;
  }

  if (isDark) {
    document.body.classList.add('dark');
    document.documentElement.classList.add('dark');
    document.documentElement.style.setProperty('color-scheme', 'dark');
  } else {
    document.body.classList.remove('dark');
    document.documentElement.classList.remove('dark');
    document.documentElement.style.setProperty('color-scheme', 'light');
  }

  // Apply full preset tokens for the resolved light/dark mode (sidebar, card, muted, …)
  if (hasPreset && activeBrandColors) {
    applyBrandColorVariables(activeBrandColors, {
      structural: true,
      dark: isDark,
    });
  }
};
