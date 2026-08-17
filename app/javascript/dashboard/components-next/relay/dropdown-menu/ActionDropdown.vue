<script setup>
import { cn } from '../utils/cn';
import RelayDropdownMenu from './DropdownMenu.vue';
import RelayDropdownMenuTrigger from './DropdownMenuTrigger.vue';
import RelayDropdownMenuContent from './DropdownMenuContent.vue';
import DropdownMenuList from './DropdownMenuList.vue';

defineProps({
  menuItems: {
    type: Array,
    default: () => [],
  },
  menuSections: {
    type: Array,
    default: () => [],
  },
  align: {
    type: String,
    default: 'end',
  },
  side: {
    type: String,
    default: 'bottom',
  },
  contentClass: {
    type: String,
    default: '',
  },
  thumbnailSize: { type: Number, default: 20 },
  roundedThumbnail: { type: Boolean, default: true },
  showSearch: { type: Boolean, default: false },
  searchPlaceholder: { type: String, default: '' },
  isSearching: { type: Boolean, default: false },
  labelClass: { type: String, default: '' },
  disableLocalFiltering: { type: Boolean, default: false },
  isLoading: { type: Boolean, default: false },
  emptyStateMessage: {
    type: String,
    default: 'DROPDOWN_MENU.EMPTY_STATE',
  },
});

defineEmits(['action', 'search', 'empty']);
</script>

<template>
  <RelayDropdownMenu>
    <RelayDropdownMenuTrigger as-child>
      <slot name="trigger" />
    </RelayDropdownMenuTrigger>
    <RelayDropdownMenuContent
      :align="align"
      :side="side"
      :class="cn('w-48', contentClass)"
    >
      <DropdownMenuList
        v-bind="$props"
        @action="$emit('action', $event)"
        @search="$emit('search', $event)"
        @empty="$emit('empty', $event)"
      >
        <template v-if="$slots.footer" #footer>
          <slot name="footer" />
        </template>
        <template v-if="$slots.thumbnail" #thumbnail="slotProps">
          <slot name="thumbnail" v-bind="slotProps" />
        </template>
        <template v-if="$slots.icon" #icon="slotProps">
          <slot name="icon" v-bind="slotProps" />
        </template>
        <template v-if="$slots.label" #label="slotProps">
          <slot name="label" v-bind="slotProps" />
        </template>
        <template v-if="$slots['trailing-icon']" #trailing-icon="slotProps">
          <slot name="trailing-icon" v-bind="slotProps" />
        </template>
      </DropdownMenuList>
    </RelayDropdownMenuContent>
  </RelayDropdownMenu>
</template>
