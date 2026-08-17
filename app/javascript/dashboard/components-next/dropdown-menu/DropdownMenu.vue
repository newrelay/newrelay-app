<script setup>
import { cn } from '../relay/utils/cn';
import { DROPDOWN_MENU_CONTENT_CLASS } from '../relay/dropdown-menu/constants';
import DropdownMenuList from '../relay/dropdown-menu/DropdownMenuList.vue';

defineProps({
  menuItems: {
    type: Array,
    default: () => [],
  },
  menuSections: {
    type: Array,
    default: () => [],
  },
  thumbnailSize: {
    type: Number,
    default: 20,
  },
  roundedThumbnail: {
    type: Boolean,
    default: true,
  },
  showSearch: {
    type: Boolean,
    default: false,
  },
  searchPlaceholder: {
    type: String,
    default: '',
  },
  isSearching: {
    type: Boolean,
    default: false,
  },
  labelClass: {
    type: String,
    default: '',
  },
  disableLocalFiltering: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  emptyStateMessage: {
    type: String,
    default: 'DROPDOWN_MENU.EMPTY_STATE',
  },
});

defineEmits(['action', 'search', 'empty']);

defineOptions({ inheritAttrs: false });
</script>

<template>
  <div :class="cn('absolute', DROPDOWN_MENU_CONTENT_CLASS, $attrs.class)">
    <DropdownMenuList
      :menu-items="menuItems"
      :menu-sections="menuSections"
      :thumbnail-size="thumbnailSize"
      :rounded-thumbnail="roundedThumbnail"
      :show-search="showSearch"
      :search-placeholder="searchPlaceholder"
      :is-searching="isSearching"
      :label-class="labelClass"
      :disable-local-filtering="disableLocalFiltering"
      :is-loading="isLoading"
      :empty-state-message="emptyStateMessage"
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
  </div>
</template>
