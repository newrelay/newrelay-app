<script setup>
import { RelayTooltip, RelayButton } from 'dashboard/components-next/relay';

/* eslint-disable vue/no-unused-properties -- status props kept for ChatList API compatibility */
defineProps({
  hasAppliedFilters: { type: Boolean, required: true },
  hasActiveFolders: { type: Boolean, required: true },
  isOnExpandedLayout: { type: Boolean, required: true },
  activeStatusTab: { type: String, default: 'new' },
  statusTabItems: { type: Array, default: () => [] },
});
/* eslint-enable vue/no-unused-properties */

const emit = defineEmits([
  'addFolders',
  'deleteFolders',
  'resetFilters',
  'filtersModal',
  'openSearch',
]);
</script>

<template>
  <div class="flex shrink-0 items-center gap-1">
    <template v-if="hasAppliedFilters && !hasActiveFolders">
      <div class="relative">
        <RelayTooltip
          :content="$t('FILTER.CUSTOM_VIEWS.ADD.SAVE_BUTTON')"
          side="top"
          align="end"
        >
          <RelayButton
            variant="ghost"
            size="icon"
            class="h-8 w-8 border border-border text-muted-foreground hover:border-transparent"
            @click="emit('addFolders')"
          >
            <span class="i-lucide-save size-4" />
          </RelayButton>
        </RelayTooltip>
        <div
          id="saveFilterTeleportTarget"
          class="absolute z-50 mt-2"
          :class="{ 'ltr:right-0 rtl:left-0': isOnExpandedLayout }"
        />
      </div>
      <RelayTooltip
        :content="$t('FILTER.CLEAR_BUTTON_LABEL')"
        side="top"
        align="end"
      >
        <RelayButton
          variant="ghost"
          size="icon"
          class="h-8 w-8 border border-border text-destructive hover:border-transparent"
          @click="emit('resetFilters')"
        >
          <span class="i-lucide-circle-x size-4" />
        </RelayButton>
      </RelayTooltip>
    </template>
    <template v-else-if="hasActiveFolders">
      <div class="relative">
        <RelayTooltip
          :content="$t('FILTER.CUSTOM_VIEWS.EDIT.EDIT_BUTTON')"
          side="top"
          align="end"
        >
          <RelayButton
            id="toggleConversationFilterButton"
            variant="ghost"
            size="icon"
            class="h-8 w-8 border border-border text-muted-foreground hover:border-transparent"
            @click="emit('filtersModal')"
          >
            <span class="i-lucide-pen-line size-4" />
          </RelayButton>
        </RelayTooltip>
        <div
          id="conversationFilterTeleportTarget"
          class="absolute z-50 mt-2"
          :class="{ 'ltr:right-0 rtl:left-0': isOnExpandedLayout }"
        />
      </div>
      <RelayTooltip
        :content="$t('FILTER.CUSTOM_VIEWS.DELETE.DELETE_BUTTON')"
        side="top"
        align="end"
      >
        <RelayButton
          variant="ghost"
          size="icon"
          class="h-8 w-8 border border-border text-destructive hover:border-transparent"
          @click="emit('deleteFolders')"
        >
          <span class="i-lucide-trash-2 size-4" />
        </RelayButton>
      </RelayTooltip>
    </template>
    <button
      v-else
      type="button"
      class="inline-flex size-8 shrink-0 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
      :aria-label="$t('CHAT_LIST.SEARCH.INPUT')"
      @click="emit('openSearch')"
    >
      <span class="i-lucide-search size-4 shrink-0" />
    </button>
  </div>
</template>
