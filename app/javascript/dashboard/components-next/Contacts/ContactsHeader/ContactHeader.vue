<script setup>
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

defineProps({
  showSearch: { type: Boolean, default: true },
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, required: true },
  isSegmentsView: { type: Boolean, default: false },
  hasActiveFilters: { type: Boolean, default: false },
  isLabelView: { type: Boolean, default: false },
  isActiveView: { type: Boolean, default: false },
});

const emit = defineEmits([
  'search',
  'filter',
  'createSegment',
  'deleteSegment',
]);
</script>

<template>
  <div class="flex flex-col gap-0 border-b border-border/40 bg-background">
    <template v-if="showSearch">
      <div
        class="flex flex-col gap-3 px-4 py-3 sm:flex-row sm:items-center sm:justify-between sm:px-6"
      >
        <div class="relative min-w-0 w-full sm:max-w-sm">
          <span
            class="i-lucide-search pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
          />
          <RelayInput
            type="search"
            class-name="h-9 w-full rounded-md border border-border/80 bg-background pl-9 text-[13px] placeholder:text-muted-foreground/60 focus-visible:ring-1 focus-visible:ring-primary/30"
            :model-value="searchValue"
            :placeholder="$t('CONTACTS_LAYOUT.HEADER.SEARCH_PLACEHOLDER')"
            @update:model-value="emit('search', $event)"
          />
        </div>
        <div class="flex shrink-0 items-center gap-2">
          <RelayButton
            v-if="
              hasActiveFilters &&
              !isSegmentsView &&
              !isLabelView &&
              !isActiveView
            "
            variant="outline"
            size="icon"
            class="size-9 rounded-lg shadow-sm"
            @click="emit('createSegment')"
          >
            <span class="i-lucide-save size-4" />
          </RelayButton>
          <slot name="columns" />
          <RelayButton
            v-if="!isLabelView && !isActiveView"
            id="toggleContactsFilterButton"
            variant="outline"
            class="flex h-9 items-center gap-2 rounded-lg border border-border bg-background px-3 text-[13px] font-normal shadow-sm transition-all hover:border-transparent hover:bg-muted"
            @click="emit('filter')"
          >
            <span class="i-lucide-list-filter size-4" />
            {{ $t('CONTACTS_LAYOUT.HEADER.FILTERS_BUTTON') }}
            <span
              v-if="hasActiveFilters"
              class="size-1.5 rounded-full bg-primary"
            />
          </RelayButton>
        </div>
      </div>
    </template>

    <template v-else>
      <div class="flex items-center justify-between px-6 py-4">
        <span class="truncate text-base font-medium text-foreground">
          {{ headerTitle }}
        </span>
        <div class="flex shrink-0 items-center gap-2">
          <RelayButton
            v-if="!isLabelView && !isActiveView"
            id="toggleContactsFilterButton"
            variant="outline"
            class="h-9 gap-2 rounded-lg px-3 text-[13px] font-normal shadow-sm"
            @click="emit('filter')"
          >
            <span
              :class="
                isSegmentsView ? 'i-lucide-pen-line' : 'i-lucide-list-filter'
              "
              class="size-4"
            />
            {{
              isSegmentsView
                ? $t('CONTACTS_LAYOUT.FILTER.EDIT_SEGMENT')
                : $t('CONTACTS_LAYOUT.HEADER.FILTERS_BUTTON')
            }}
            <span
              v-if="hasActiveFilters && !isSegmentsView"
              class="size-1.5 rounded-full bg-primary"
            />
          </RelayButton>

          <RelayButton
            v-if="isSegmentsView && !isLabelView && !isActiveView"
            variant="outline"
            size="icon"
            class="size-10 rounded-lg shadow-sm"
            @click="emit('deleteSegment')"
          >
            <span class="i-lucide-trash size-4" />
          </RelayButton>
        </div>
      </div>
    </template>
  </div>
</template>
