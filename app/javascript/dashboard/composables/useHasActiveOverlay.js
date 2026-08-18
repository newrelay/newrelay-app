import { ref } from 'vue';
import { useMutationObserver } from '@vueuse/core';

const ACTIVE_OVERLAY_SELECTOR = [
  '[data-relay-overlay][data-state="open"]',
  '[data-relay-overlay]:not([data-state])',
  '.modal-mask',
  '.fixed.inset-0[class*="backdrop-blur"]',
].join(', ');

const isOverlayVisible = element => {
  const state = element.getAttribute('data-state');
  if (state === 'closed') return false;

  const style = window.getComputedStyle(element);
  return (
    style.display !== 'none' &&
    style.visibility !== 'hidden' &&
    Number(style.opacity) > 0
  );
};

const detectActiveOverlay = () =>
  [...document.querySelectorAll(ACTIVE_OVERLAY_SELECTOR)].some(
    isOverlayVisible
  );

/**
 * Tracks whether a full-screen modal/dialog overlay is currently visible.
 * Used to hide floating UI (e.g. Relay AI launcher) while overlays are open.
 */
export function useHasActiveOverlay() {
  const hasActiveOverlay = ref(false);

  const sync = () => {
    hasActiveOverlay.value = detectActiveOverlay();
  };

  sync();

  useMutationObserver(document.body, sync, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['data-state', 'class', 'style'],
  });

  return { hasActiveOverlay };
}
