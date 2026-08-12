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
          class="h-8 w-8 text-muted-foreground"
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
        class="h-8 w-8 text-destructive"
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
          class="h-8 w-8 text-muted-foreground"
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
        class="h-8 w-8 text-destructive"
        @click="emit('deleteFolders')"
      >
        <span class="i-lucide-trash-2 size-4" />
      </RelayButton>
    </template>
    <div v-else class="relative">
      <RelayButton
        v-if="false"
        id="toggleConversationFilterButton"
        variant="outline"
        size="icon"
        class="h-8 w-8 shrink-0"
        :aria-label="$t('FILTER.TOOLTIP_LABEL')"
        @click="showFilterMenu = !showFilterMenu"
      >
        <span class="i-lucide-list-filter size-4" />
      </RelayButton>
      <div
        v-if="showFilterMenu"
        v-on-click-outside="() => (showFilterMenu = false)"
        class="absolute right-0 mt-1.5 z-50 w-48 rounded-md border border-border bg-popover p-1 shadow-md"
      >
        <button
          v-for="tab in statusTabItems"
          :key="tab.key"
          type="button"
          class="w-full flex items-center gap-2 px-2 py-1.5 text-sm rounded-sm hover:bg-muted text-foreground"
          :class="{
            'bg-primary/5 text-primary': activeStatusTab === tab.key,
          }"
          @click="applyStatus(tab.key)"
        >
          <span class="i-lucide-circle size-4 text-muted-foreground" />
          {{ tab.name }}
        </button>
        <div class="my-1 h-px bg-border" />
        <button
          type="button"
          class="w-full flex items-center gap-2 px-2 py-1.5 text-sm rounded-sm hover:bg-muted text-foreground"
          @click="applySort('last_activity_at_asc')"
        >
          <span class="i-lucide-clock size-4 text-muted-foreground" />
          {{ t('CHAT_LIST.FILTER_MENU.OLDEST_FIRST') }}
        </button>
        <div class="my-1 h-px bg-border" />
        <button
          type="button"
          class="w-full flex items-center gap-2 px-2 py-1.5 text-sm rounded-sm hover:bg-muted text-foreground"
          @click="
            showFilterMenu = false;
            emit('filtersModal');
          "
        >
          <span
            class="i-lucide-sliders-horizontal size-4 text-muted-foreground"
          />
          {{ t('FILTER.TITLE') }}
        </button>
      </div>
      <div
        id="conversationFilterTeleportTarget"
        class="absolute z-50 mt-2"
        :class="{ 'ltr:right-0 rtl:left-0': isOnExpandedLayout }"
      />
    </div>
    <SwitchLayout
      v-if="false"
      :is-on-expanded-layout="isOnExpandedLayout"
      @toggle="toggleConversationLayout"
    />
  </div>
</template>
