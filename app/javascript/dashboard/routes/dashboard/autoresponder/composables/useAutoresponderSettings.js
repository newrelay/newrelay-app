import { ref, watch } from 'vue';
import CommentAutomationSettingsAPI from 'dashboard/api/commentAutomationSettings';

const settings = ref({
  general: {},
  behavior: {},
  safety: {},
  hours: { weeklySchedule: [] },
  notifications: { preferences: [] },
  advanced: { systemHealth: [] },
});
const loaded = ref(false);
let loadPromise = null;
let persistEnabled = false;

async function fetchSettings() {
  const response = await CommentAutomationSettingsAPI.get();
  settings.value = { ...settings.value, ...response.data };
}

watch(
  settings,
  () => {
    if (persistEnabled) CommentAutomationSettingsAPI.save(settings.value);
  },
  { deep: true }
);

export function useAutoresponderSettings() {
  if (!loaded.value && !loadPromise) {
    loadPromise = fetchSettings()
      .catch(() => {})
      .finally(() => {
        loaded.value = true;
        persistEnabled = true;
        loadPromise = null;
      });
  }

  return { settings, loaded };
}
