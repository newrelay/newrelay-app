import { lighten, darken, getLuminance, toRgba, transparentize } from 'color2k';
import {
  THEME_TOKEN_KEYS,
  findMatchingPreset,
  findPresetById,
} from 'dashboard/routes/dashboard/settings/branding/brandThemePresets';

export const hexToRgbSpace = color => {
  if (!color) return null;
  try {
    const rgba = toRgba(color);
    const result = /^rgba\((\d+),\s*(\d+),\s*(\d+),\s*[^)]+\)$/.exec(rgba);
    if (!result) return null;
    return `${result[1]} ${result[2]} ${result[3]}`;
  } catch {
    return null;
  }
};

export const normalizeCssColorToken = color => {
  if (!color || typeof color !== 'string') return color;
  const trimmed = color.trim();
  if (/^#[0-9a-fA-F]{8}$/.test(trimmed)) return trimmed;
  if (/^\d{1,3} \d{1,3} \d{1,3}$/.test(trimmed)) return trimmed;
  if (/^#[0-9a-fA-F]{6}$/.test(trimmed)) {
    return hexToRgbSpace(trimmed) ?? trimmed;
  }
  return trimmed;
};

const HEX_BORDER_THEME_KEYS = new Set(['border', 'input', 'sidebar-border']);

const setThemeCssVariable = (root, key, value) => {
  if (!value) return;
  const token = HEX_BORDER_THEME_KEYS.has(key)
    ? value
    : normalizeCssColorToken(value);
  root.style.setProperty(`--${key}`, token ?? value);
};

export const generateThemeVariables = backgroundHex => {
  if (!backgroundHex) return null;
  const isDark = getLuminance(backgroundHex) < 0.5;
  const vars = {};

  if (isDark) {
    vars['--background-color'] = hexToRgbSpace(backgroundHex);
    vars['--surface-1'] = hexToRgbSpace(lighten(backgroundHex, 0.03));
    vars['--surface-2'] = hexToRgbSpace(lighten(backgroundHex, 0.05));
    vars['--surface-active'] = hexToRgbSpace(lighten(backgroundHex, 0.1));
    vars['--solid-1'] = hexToRgbSpace(lighten(backgroundHex, 0.02));
    vars['--solid-2'] = hexToRgbSpace(lighten(backgroundHex, 0.04));
    vars['--solid-3'] = hexToRgbSpace(lighten(backgroundHex, 0.08));
    vars['--card-color'] = hexToRgbSpace(backgroundHex);
    vars['--border-strong'] = hexToRgbSpace(lighten(backgroundHex, 0.15));
    vars['--border-weak'] = hexToRgbSpace(lighten(backgroundHex, 0.08));
    vars['--label-background'] = hexToRgbSpace(lighten(backgroundHex, 0.04));
  } else {
    vars['--background-color'] = hexToRgbSpace(backgroundHex);
    vars['--surface-1'] = hexToRgbSpace(lighten(backgroundHex, 0.03));
    vars['--surface-2'] = hexToRgbSpace(lighten(backgroundHex, 0.04));
    vars['--surface-active'] = hexToRgbSpace(lighten(backgroundHex, 0.05));
    vars['--solid-1'] = hexToRgbSpace(lighten(backgroundHex, 0.05));
    vars['--solid-2'] = hexToRgbSpace(lighten(backgroundHex, 0.05));
    vars['--solid-3'] = hexToRgbSpace(lighten(backgroundHex, 0.05));
    vars['--card-color'] = hexToRgbSpace(lighten(backgroundHex, 0.03));
    vars['--border-strong'] = hexToRgbSpace(darken(backgroundHex, 0.08));
    vars['--border-weak'] = hexToRgbSpace(darken(backgroundHex, 0.04));
    vars['--label-background'] = hexToRgbSpace(backgroundHex);
  }

  return vars;
};

export const generatePrimaryColorVariables = primaryHex => {
  if (!primaryHex) return null;
  const isDark = getLuminance(primaryHex) < 0.5;
  const vars = {};

  // Base is step 9
  vars['--blue-9'] = hexToRgbSpace(primaryHex);
  vars['--woot-brand'] = hexToRgbSpace(primaryHex);

  // Generate 12 steps
  // (We overwrite --blue-1 to --blue-12 to hijack the primary color scale)
  vars['--blue-1'] = hexToRgbSpace(lighten(primaryHex, 0.45));
  vars['--blue-2'] = hexToRgbSpace(lighten(primaryHex, 0.4));
  vars['--blue-3'] = hexToRgbSpace(lighten(primaryHex, 0.35));
  vars['--blue-4'] = hexToRgbSpace(lighten(primaryHex, 0.3));
  vars['--blue-5'] = hexToRgbSpace(lighten(primaryHex, 0.25));
  vars['--blue-6'] = hexToRgbSpace(lighten(primaryHex, 0.15));
  vars['--blue-7'] = hexToRgbSpace(lighten(primaryHex, 0.1));
  vars['--blue-8'] = hexToRgbSpace(lighten(primaryHex, 0.05));
  vars['--blue-10'] = hexToRgbSpace(darken(primaryHex, 0.05));
  vars['--blue-11'] = hexToRgbSpace(darken(primaryHex, 0.1));
  vars['--blue-12'] = hexToRgbSpace(darken(primaryHex, 0.15));

  // Some specific variables in _next-colors.scss:
  vars['--text-blue'] = isDark ? vars['--blue-1'] : vars['--blue-12'];
  vars['--border-blue-strong'] = vars['--blue-7'];
  vars['--solid-blue'] = vars['--blue-9'];
  vars['--solid-blue-2'] = vars['--blue-10'];
  vars['--border-blue'] = hexToRgbSpace(transparentize(primaryHex, 0.5));

  return vars;
};

const LEGACY_THEME_KEYS = [
  '--background-color',
  '--surface-1',
  '--surface-2',
  '--surface-active',
  '--solid-1',
  '--solid-2',
  '--solid-3',
  '--card-color',
  '--border-strong',
  '--border-weak',
  '--label-background',
  '--slate-12',
  '--woot-brand',
  '--text-blue',
  '--border-blue-strong',
  '--solid-blue',
  '--solid-blue-2',
  '--border-blue',
  ...Array.from({ length: 12 }, (_, i) => `--blue-${i + 1}`),
];

const clearManagedThemeTokens = () => {
  const root = document.documentElement;
  THEME_TOKEN_KEYS.forEach(key => root.style.removeProperty(`--${key}`));
};

const removeServerBrandStyle = () => {
  const styleNode = document.getElementById('brand-colors');
  if (styleNode) styleNode.remove();
};

const applyLegacyPrimary = primary => {
  if (!primary) return;
  const root = document.documentElement;
  const primaryVars = generatePrimaryColorVariables(primary);
  if (primaryVars) {
    Object.entries(primaryVars).forEach(([key, value]) => {
      if (value) root.style.setProperty(key, value);
    });
  }
  const primaryToken = normalizeCssColorToken(primary);
  root.style.setProperty('--primary', primaryToken);
  root.style.setProperty('--ring', primaryToken);
  root.style.setProperty('--sidebar-primary', primaryToken);
};

/**
 * Apply full new-ui preset token map (sidebar, card, muted, border, …).
 * Mirrors new-ui stores/theme.ts applyAppearance.
 */
const applyPresetTokenMap = (preset, { dark = false } = {}) => {
  const root = document.documentElement;
  removeServerBrandStyle();
  clearManagedThemeTokens();

  if (!preset?.light) {
    // Default / no token map — fall back to swatch accents only
    applyLegacyPrimary(preset?.primary);
    if (preset?.secondary) {
      const secondaryToken = normalizeCssColorToken(preset.secondary);
      root.style.setProperty('--secondary', secondaryToken);
      root.style.setProperty('--muted', secondaryToken);
    }
    if (preset?.accent) {
      const accentToken = normalizeCssColorToken(preset.accent);
      root.style.setProperty('--accent', accentToken);
      root.style.setProperty('--sidebar-accent', accentToken);
    }
    return;
  }

  const light = preset.light;
  const darkVars = preset.dark || light;
  const vars = dark ? darkVars : light;

  Object.entries(vars).forEach(([key, value]) => {
    // Identical dark≈light (broken generator): only brand accents in dark mode
    // so structural surfaces fall back to .dark in _relay-theme.scss
    if (dark && value === light[key]) {
      const isCoreBrand =
        key.includes('primary') ||
        key.includes('ring') ||
        key.includes('chart');
      if (!isCoreBrand) return;
    }
    setThemeCssVariable(root, key, value);
  });

  // Keep legacy blue scale / woot-brand in sync with primary
  applyLegacyPrimary(vars.primary || light.primary);

  const bg = vars.background || light.background;
  if (bg) {
    const themeVars = generateThemeVariables(bg);
    if (themeVars) {
      Object.entries(themeVars).forEach(([key, value]) => {
        if (value) root.style.setProperty(key, value);
      });
    }
  }

  const fg = vars.foreground || light.foreground;
  if (fg) {
    const textRgb = hexToRgbSpace(fg);
    if (textRgb) root.style.setProperty('--slate-12', textRgb);
  }
};

const resolvePreset = colors => {
  if (!colors) return null;
  if (colors.theme_preset) {
    const byId = findPresetById(colors.theme_preset);
    if (byId) return byId;
  }
  return findMatchingPreset(colors);
};

/**
 * Apply account brand_colors to CSS variables.
 * Full theme presets set every new-ui token (incl. --sidebar*).
 * Legacy 4-swatch branding still uses --woot-brand / --blue-* / surfaces.
 * @param {object} colors
 * @param {{ structural?: boolean, dark?: boolean }} options
 *   structural=false keeps light/dark surfaces for custom swatches;
 *   full presets always apply the light/dark token map for `dark`.
 */
export const applyBrandColorVariables = (
  colors,
  { structural = true, dark = false } = {}
) => {
  if (!colors) return;

  const preset = resolvePreset(colors);
  if (preset && (preset.light || preset.id === 'default')) {
    applyPresetTokenMap(preset, { dark });
    return;
  }

  // Stored flat token map (sidebar etc.) from a previous save — apply directly
  if (colors.sidebar || colors['sidebar-foreground']) {
    const root = document.documentElement;
    removeServerBrandStyle();
    clearManagedThemeTokens();
    THEME_TOKEN_KEYS.forEach(key => {
      setThemeCssVariable(root, key, colors[key]);
    });
    applyLegacyPrimary(colors.primary || colors['sidebar-primary']);
    if (colors.background || colors.foreground) {
      if (colors.background) {
        const themeVars = generateThemeVariables(colors.background);
        if (themeVars) {
          Object.entries(themeVars).forEach(([key, value]) => {
            if (value) root.style.setProperty(key, value);
          });
        }
      }
      if (colors.foreground || colors.text) {
        const textRgb = hexToRgbSpace(colors.foreground || colors.text);
        if (textRgb) root.style.setProperty('--slate-12', textRgb);
      }
    }
    return;
  }

  const root = document.documentElement;
  const { primary, secondary, accent, background, text } = colors;

  if (primary) applyLegacyPrimary(primary);

  if (secondary) {
    const secondaryToken = normalizeCssColorToken(secondary);
    root.style.setProperty('--secondary', secondaryToken);
    root.style.setProperty('--muted', secondaryToken);
  }

  if (accent) {
    const accentToken = normalizeCssColorToken(accent);
    root.style.setProperty('--accent', accentToken);
    root.style.setProperty('--sidebar-accent', accentToken);
  }

  if (!structural) return;

  if (text) {
    const textRgb = hexToRgbSpace(text);
    if (textRgb) root.style.setProperty('--slate-12', textRgb);
    root.style.setProperty('--foreground', normalizeCssColorToken(text));
  }

  if (background) {
    const themeVars = generateThemeVariables(background);
    if (themeVars) {
      Object.entries(themeVars).forEach(([key, value]) => {
        if (value) root.style.setProperty(key, value);
      });
    }
    const backgroundToken = normalizeCssColorToken(background);
    root.style.setProperty('--background', backgroundToken);
    root.style.setProperty('--card', backgroundToken);
    root.style.setProperty('--popover', backgroundToken);
  }
};

export const clearCustomThemeVariables = () => {
  clearManagedThemeTokens();
  LEGACY_THEME_KEYS.forEach(key =>
    document.documentElement.style.removeProperty(key)
  );

  const styleNode = document.getElementById('brand-colors');
  if (styleNode) {
    styleNode.remove();
  }
};

export const isDarkBackground = backgroundHex => {
  if (!backgroundHex) return false;
  try {
    return getLuminance(backgroundHex) < 0.5;
  } catch {
    return false;
  }
};

export const hasFullThemePreset = colors => {
  if (!colors) return false;
  if (colors.sidebar || colors['sidebar-foreground']) return true;
  const preset = resolvePreset(colors);
  return Boolean(preset && (preset.light || preset.id === 'default'));
};
