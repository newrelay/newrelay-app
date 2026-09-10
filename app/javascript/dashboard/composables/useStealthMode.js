import { ref } from 'vue';

const STEALTH_KEY = 'newrelay-stealth-mode';
const STEALTH_TITLE = 'Cloud Workspace — Dashboard';
const STEALTH_FAVICON = `data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect width="32" height="32" rx="8" fill="%23ff7e5f"/><path d="M16 7L24 12L16 17L8 12L16 7Z" fill="white"/><path d="M8 16L16 21L24 16" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M8 20L16 25L24 20" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`;

const readStoredStealth = () => {
  if (typeof window === 'undefined') return false;
  if (process.env.NODE_ENV === 'test') return false;
  // Match NewRelay-UI: default on unless explicitly disabled.
  return window.localStorage.getItem(STEALTH_KEY) !== 'false';
};

export const isStealthMode = ref(readStoredStealth());

const applyDocumentTitle = () => {
  if (typeof document === 'undefined' || !isStealthMode.value) return;
  document.title = STEALTH_TITLE;
};

const applyFavicon = () => {
  if (typeof document === 'undefined') return;

  const links = document.querySelectorAll(
    "link[rel*='icon'], link[rel='apple-touch-icon']"
  );

  if (isStealthMode.value) {
    if (links.length === 0) {
      const link = document.createElement('link');
      link.rel = 'icon';
      link.href = STEALTH_FAVICON;
      document.head.appendChild(link);
      return;
    }
    links.forEach(link => {
      if (!link.dataset.originalHref) {
        link.dataset.originalHref = link.getAttribute('href') || '';
      }
      link.href = STEALTH_FAVICON;
    });
    return;
  }

  links.forEach(link => {
    if (link.dataset.originalHref) {
      link.href = link.dataset.originalHref;
    }
  });
};

export const syncStealthAppearance = () => {
  applyDocumentTitle();
  applyFavicon();
};

const persistAndSync = () => {
  if (typeof window !== 'undefined') {
    window.localStorage.setItem(STEALTH_KEY, String(isStealthMode.value));
  }
  syncStealthAppearance();
  window.dispatchEvent(new CustomEvent('theme-changed'));
};

export const setStealthMode = value => {
  isStealthMode.value = Boolean(value);
  persistAndSync();
  return isStealthMode.value;
};

export const toggleStealthMode = () => setStealthMode(!isStealthMode.value);

export const isStealthHotkey = event => {
  const isAltShiftD =
    event.altKey &&
    event.shiftKey &&
    (event.key === 'D' || event.key === 'd' || event.code === 'KeyD');
  const isCtrlShiftS =
    (event.ctrlKey || event.metaKey) &&
    event.shiftKey &&
    (event.key === 'S' || event.key === 's' || event.code === 'KeyS');
  return isAltShiftD || isCtrlShiftS;
};

export const bindStealthHotkeys = ({ onToggle } = {}) => {
  const handler = event => {
    if (!isStealthHotkey(event)) return;
    event.preventDefault();
    const enabled = toggleStealthMode();
    onToggle?.(enabled);
  };
  window.addEventListener('keydown', handler);
  return () => window.removeEventListener('keydown', handler);
};

export function useStealthMode() {
  return {
    isStealthMode,
    toggleStealthMode,
    setStealthMode,
    syncStealthAppearance,
    bindStealthHotkeys,
  };
}
