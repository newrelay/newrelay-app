<script setup>
import { computed } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useToggle } from '@vueuse/core';

import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import MultiselectDropdownItems from 'shared/components/ui/MultiselectDropdownItems.vue';

const props = defineProps({
  options: {
    type: Array,
    default: () => [],
  },
  selectedItem: {
    type: Object,
    default: () => ({}),
  },
  hasThumbnail: {
    type: Boolean,
    default: true,
  },
  multiselectorTitle: {
    type: String,
    default: '',
  },
  multiselectorPlaceholder: {
    type: String,
    default: 'None',
  },
  noSearchResult: {
    type: String,
    default: 'No results found',
  },
  inputPlaceholder: {
    type: String,
    default: 'Search',
  },
});

const emit = defineEmits(['select']);
const [showSearchDropdown, toggleDropdown] = useToggle(false);

const onCloseDropdown = () => toggleDropdown(false);
const onClickSelectItem = value => {
  emit('select', value);
  onCloseDropdown();
};

const hasValue = computed(() => {
  if (props.selectedItem && props.selectedItem.id) {
    return true;
  }
  return false;
});

const hasIcon = computed(() => {
  return props.selectedItem?.icon || false;
});

const displayLabel = computed(() => {
  if (hasValue.value) {
    return props.selectedItem.name;
  }
  return props.multiselectorPlaceholder;
});
</script>

<template>
  <OnClickOutside @trigger="onCloseDropdown">
    <div class="relative w-full" @keyup.esc="onCloseDropdown">
      <button
        type="button"
        class="flex items-center justify-between w-full border border-border/60 rounded-lg px-2.5 py-1.5 bg-transparent hover:bg-muted/40 transition-colors text-left focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary"
        @click="toggleDropdown()"
      >
        <div class="flex items-center gap-2 min-w-0 flex-1">
          <Avatar
            v-if="hasValue && hasThumbnail && !hasIcon"
            :src="selectedItem.thumbnail"
            :status="selectedItem.availability_status"
            :name="selectedItem.name"
            :size="16"
            rounded-full
          />
          <Icon
            v-if="hasValue && hasIcon"
            :icon="selectedItem.icon"
            class="size-3.5 shrink-0 text-muted-foreground"
          />
          <span
            class="text-[13px] truncate"
            :class="hasValue ? 'text-foreground' : 'text-muted-foreground'"
            :title="displayLabel"
          >
            {{ displayLabel }}
          </span>
        </div>
        <span
          class="size-3 shrink-0 text-muted-foreground"
          :class="
            showSearchDropdown ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'
          "
        />
      </button>
      <div
        :class="{
          'block visible': showSearchDropdown,
          'hidden invisible': !showSearchDropdown,
        }"
        class="absolute top-[calc(100%+0.25rem)] left-0 w-full rounded-md border border-border bg-popover text-popover-foreground shadow-md p-2 z-[9999]"
      >
        <div class="flex items-center justify-between mb-1">
          <h4
            class="m-0 overflow-hidden text-sm text-muted-foreground whitespace-nowrap text-ellipsis"
          >
            {{ multiselectorTitle }}
          </h4>
          <Button ghost slate xs icon="i-lucide-x" @click="onCloseDropdown" />
        </div>
        <MultiselectDropdownItems
          v-if="showSearchDropdown"
          :options="options"
          :selected-items="[selectedItem]"
          :has-thumbnail="hasThumbnail"
          :input-placeholder="inputPlaceholder"
          :no-search-result="noSearchResult"
          @select="onClickSelectItem"
        />
      </div>
    </div>
  </OnClickOutside>
</template>
