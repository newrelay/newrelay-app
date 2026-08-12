<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDetectKeyboardLayout } from 'dashboard/composables/useDetectKeyboardLayout';
import { SHORTCUT_KEYS, KEYS } from './constants';
import {
  LAYOUT_QWERTZ,
  keysToModifyInQWERTZ,
} from 'shared/helpers/KeyboardHelpers';

defineProps({ show: Boolean });
defineEmits(['close']);

const { t } = useI18n();
const currentLayout = ref(null);

const kbdClass =
  'h-7 min-w-7 px-2 inline-flex items-center justify-center rounded-md border border-primary/20 bg-primary/5 text-primary text-[12px] font-medium';

const title = computed(
  () => item => t(`KEYBOARD_SHORTCUTS.TITLE.${item.label}`)
);

// Added this function to check if the keySet needs a shift key
// This is used to display the shift key in the modal
// If the current layout is QWERTZ and the keySet contains a key that needs a shift key
// If layout is QWERTZ then we add the Shift+keysToModify to fix an known issue
// https://github.com/chatwoot/chatwoot/issues/9492
const needsShiftKey = computed(
  () => keySet =>
    currentLayout.value === LAYOUT_QWERTZ &&
    keySet.some(key => keysToModifyInQWERTZ.has(key))
);

onMounted(async () => {
  currentLayout.value = await useDetectKeyboardLayout();
});
</script>

<template>
  <woot-modal :show="show" size="medium" :on-close="() => $emit('close')">
    <div class="flex flex-col h-auto overflow-auto">
      <div
        class="flex items-center justify-between px-6 py-5 border-b border-border/40"
      >
        <h2 class="text-base font-medium text-foreground">
          {{ $t('SIDEBAR_ITEMS.KEYBOARD_SHORTCUTS') }}
        </h2>
      </div>

      <div class="grid grid-cols-1 xl:grid-cols-2 gap-x-16 gap-y-0 px-8 py-2">
        <div
          class="flex items-center justify-between py-3.5 border-b border-border/40"
        >
          <span class="text-[14px] font-medium text-foreground">
            {{ $t('KEYBOARD_SHORTCUTS.TOGGLE_MODAL') }}
          </span>
          <div class="flex items-center gap-2">
            <kbd :class="kbdClass">{{ KEYS.WIN }}</kbd>
            <kbd :class="kbdClass">{{ KEYS.SLASH }}</kbd>
          </div>
        </div>

        <div
          v-for="shortcut in SHORTCUT_KEYS"
          :key="shortcut.id"
          class="flex items-center justify-between py-3.5 border-b border-border/40"
        >
          <span class="text-[14px] font-medium text-foreground">
            {{ title(shortcut) }}
          </span>
          <div class="flex items-center gap-2">
            <kbd v-if="needsShiftKey(shortcut.keySet)" :class="kbdClass">
              {{ KEYS.SHIFT }}
            </kbd>
            <template v-for="(key, index) in shortcut.displayKeys" :key="index">
              <kbd v-if="key !== KEYS.SLASH" :class="kbdClass">{{ key }}</kbd>
              <span
                v-else
                class="text-[13px] font-medium text-muted-foreground"
              >
                {{ key }}
              </span>
            </template>
          </div>
        </div>
      </div>
    </div>
  </woot-modal>
</template>
