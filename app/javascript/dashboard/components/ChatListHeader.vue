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
  'toggleSearch',
]);
</script>

<template>
  <div class="flex items-center gap-1 shrink-0">
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
            class="h-8 w-8 text-muted-foreground border border-border hover:border-transparent"
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
          class="h-8 w-8 text-destructive border border-border hover:border-transparent"
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
            class="h-8 w-8 text-muted-foreground border border-border hover:border-transparent"
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
          class="h-8 w-8 text-destructive border border-border hover:border-transparent"
          @click="emit('deleteFolders')"
        >
          <span class="i-lucide-trash-2 size-4" />
        </RelayButton>
      </RelayTooltip>
    </template>
    <div v-else class="flex items-center gap-0.5">
      <RelayTooltip
        :content="$t('CHAT_LIST.SEARCH.INPUT')"
        side="top"
        align="end"
      >
        <RelayButton
          variant="ghost"
          size="icon"
          class="h-8 w-8 text-muted-foreground hover:text-foreground shrink-0 border border-border hover:border-transparent"
          @click="emit('toggleSearch')"
        >
          <span class="i-lucide-search size-4" />
        </RelayButton>
      </RelayTooltip>
    </div>
  </div>
</template>
