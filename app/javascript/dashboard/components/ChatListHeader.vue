<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { vOnClickOutside } from '@vueuse/components';
import wootConstants from 'dashboard/constants/globals';

import SwitchLayout from 'dashboard/routes/dashboard/conversation/search/SwitchLayout.vue';
import { RelayButton } from 'dashboard/components-next/relay';

defineProps({
  hasAppliedFilters: { type: Boolean, required: true },
  hasActiveFolders: { type: Boolean, required: true },
  activeStatusTab: { type: String, default: 'new' },
  statusTabItems: { type: Array, default: () => [] },
  isOnExpandedLayout: { type: Boolean, required: true },
});

const emit = defineEmits([
  'addFolders',
  'deleteFolders',
  'resetFilters',
  'basicFilterChange',
  'filtersModal',
  'statusChange',
  'toggleSearch',
]);

const { t } = useI18n();
const { uiSettings, updateUISettings } = useUISettings();
const showFilterMenu = ref(false);

const toggleConversationLayout = () => {
  const { LAYOUT_TYPES } = wootConstants;
  const {
    conversation_display_type: conversationDisplayType = LAYOUT_TYPES.CONDENSED,
  } = uiSettings.value;
  const newViewType =
    conversationDisplayType === LAYOUT_TYPES.CONDENSED
      ? LAYOUT_TYPES.EXPANDED
      : LAYOUT_TYPES.CONDENSED;
  updateUISettings({
    conversation_display_type: newViewType,
    previously_used_conversation_display_type: newViewType,
  });
};

const applyStatus = key => {
  showFilterMenu.value = false;
  emit('statusChange', key);
};

const applySort = value => {
  showFilterMenu.value = false;
  emit('basicFilterChange', value, 'sort');
};
</script>

<template>
  <div class="flex items-center gap-1 shrink-0">
    <template v-if="hasAppliedFilters && !hasActiveFolders">
      <div class="relative">
        <RelayButton
          v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.ADD.SAVE_BUTTON')"
          variant="ghost"
          size="icon"
          class="h-8 w-8 text-muted-foreground border border-border hover:border-transparent"
          @click="emit('addFolders')"
        >
          <span class="i-lucide-save size-4" />
        </RelayButton>
        <div
          id="saveFilterTeleportTarget"
          class="absolute z-50 mt-2"
          :class="{ 'ltr:right-0 rtl:left-0': isOnExpandedLayout }"
        />
      </div>
      <RelayButton
        v-tooltip.top-end="$t('FILTER.CLEAR_BUTTON_LABEL')"
        variant="ghost"
        size="icon"
        class="h-8 w-8 text-destructive border border-border hover:border-transparent"
        @click="emit('resetFilters')"
      >
        <span class="i-lucide-circle-x size-4" />
      </RelayButton>
    </template>
    <template v-else-if="hasActiveFolders">
      <div class="relative">
        <RelayButton
          id="toggleConversationFilterButton"
          v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.EDIT.EDIT_BUTTON')"
          variant="ghost"
          size="icon"
          class="h-8 w-8 text-muted-foreground border border-border hover:border-transparent"
          @click="emit('filtersModal')"
        >
          <span class="i-lucide-pen-line size-4" />
        </RelayButton>
        <div
          id="conversationFilterTeleportTarget"
          class="absolute z-50 mt-2"
          :class="{ 'ltr:right-0 rtl:left-0': isOnExpandedLayout }"
        />
      </div>
      <RelayButton
        v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.DELETE.DELETE_BUTTON')"
        variant="ghost"
        size="icon"
        class="h-8 w-8 text-destructive border border-border hover:border-transparent"
        @click="emit('deleteFolders')"
      >
        <span class="i-lucide-trash-2 size-4" />
      </RelayButton>
    </template>
    <div v-else class="flex items-center gap-0.5">
      <RelayButton
        v-tooltip.top-end="$t('CHAT_LIST.SEARCH.INPUT')"
        variant="ghost"
        size="icon"
        class="h-8 w-8 text-muted-foreground hover:text-foreground shrink-0 border border-border hover:border-transparent"
        @click="emit('toggleSearch')"
      >
        <span class="i-lucide-search size-4" />
      </RelayButton>
    </div>
  </div>
</template>
