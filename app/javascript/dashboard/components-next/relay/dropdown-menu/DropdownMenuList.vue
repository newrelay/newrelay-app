<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { cn } from '../utils/cn';
import {
  DROPDOWN_MENU_ITEM_BASE_CLASS,
  DROPDOWN_MENU_LABEL_CLASS,
  DROPDOWN_MENU_SEPARATOR_CLASS,
  DROPDOWN_MENU_SEARCH_HEADER_CLASS,
  DROPDOWN_MENU_SEARCH_WRAPPER_CLASS,
  DROPDOWN_MENU_SEARCH_ICON_CLASS,
  DROPDOWN_MENU_SEARCH_INPUT_CLASS,
  getDropdownItemInteractionClass,
  isDestructiveDropdownItem,
} from './constants';

const props = defineProps({
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

const emit = defineEmits(['action', 'search', 'empty']);

const { t } = useI18n();

const searchInput = ref(null);
const searchQuery = ref('');

const hasSections = computed(() => props.menuSections.length > 0);

const flattenedMenuItems = computed(() => {
  if (!hasSections.value) {
    return props.menuItems;
  }

  return props.menuSections.flatMap(section => section.items || []);
});

const filteredMenuItems = computed(() => {
  if (props.disableLocalFiltering) return props.menuItems;
  if (!searchQuery.value) return flattenedMenuItems.value;

  return flattenedMenuItems.value.filter(item =>
    item.label.toLowerCase().includes(searchQuery.value.toLowerCase())
  );
});

const filteredMenuSections = computed(() => {
  if (!hasSections.value) {
    return [];
  }

  if (props.disableLocalFiltering || !searchQuery.value) {
    return props.menuSections;
  }

  const query = searchQuery.value.toLowerCase();

  return props.menuSections
    .map(section => {
      const filteredItems = (section.items || []).filter(item =>
        item.label.toLowerCase().includes(query)
      );

      return {
        ...section,
        items: filteredItems,
      };
    })
    .filter(section => section.items.length > 0);
});

const handleSearchInput = event => {
  emit('search', event.target.value);

  const isEmpty = hasSections.value
    ? filteredMenuSections.value.length === 0
    : filteredMenuItems.value.length === 0;

  if (isEmpty) emit('empty');
};

const handleAction = item => {
  const { action, value, ...rest } = item;
  emit('action', { action, value, ...rest });
};

const itemClass = item =>
  cn(
    DROPDOWN_MENU_ITEM_BASE_CLASS,
    getDropdownItemInteractionClass(item),
    item.isSelected && 'bg-accent/50'
  );

const iconClass = item =>
  cn(
    item.icon,
    'size-4 shrink-0',
    isDestructiveDropdownItem(item)
      ? 'text-destructive'
      : 'text-muted-foreground'
  );

const shouldShowEmptyState = computed(() => {
  if (hasSections.value) {
    return filteredMenuSections.value.length === 0;
  }

  return filteredMenuItems.value.length === 0;
});

onMounted(() => {
  if (searchInput.value && props.showSearch) {
    searchInput.value.focus();
  }
});
</script>

<template>
  <div v-if="showSearch" :class="DROPDOWN_MENU_SEARCH_HEADER_CLASS">
    <div :class="DROPDOWN_MENU_SEARCH_WRAPPER_CLASS">
      <span :class="DROPDOWN_MENU_SEARCH_ICON_CLASS" />
      <input
        ref="searchInput"
        v-model="searchQuery"
        type="text"
        data-slot="input"
        :placeholder="
          searchPlaceholder || t('DROPDOWN_MENU.SEARCH_PLACEHOLDER')
        "
        :class="DROPDOWN_MENU_SEARCH_INPUT_CLASS"
        @input="handleSearchInput"
      />
    </div>
  </div>

  <template v-if="hasSections">
    <template
      v-for="(section, sectionIndex) in filteredMenuSections"
      :key="section.title || sectionIndex"
    >
      <p v-if="section.title" :class="DROPDOWN_MENU_LABEL_CLASS">
        {{ section.title }}
      </p>
      <div
        v-if="section.isLoading"
        class="flex items-center justify-center py-2"
      >
        <Spinner :size="24" />
      </div>
      <div
        v-else-if="!section.items.length && section.emptyState"
        class="px-2 py-1.5 text-sm text-muted-foreground"
      >
        {{ section.emptyState }}
      </div>
      <button
        v-for="(item, itemIndex) in section.items"
        :key="item.value || itemIndex"
        type="button"
        :class="itemClass(item)"
        :disabled="item.disabled"
        @click="handleAction(item)"
      >
        <slot name="thumbnail" :item="item">
          <Avatar
            v-if="item.thumbnail"
            :name="item.thumbnail.name"
            :src="item.thumbnail.src"
            :size="thumbnailSize"
            :rounded-full="roundedThumbnail"
          />
        </slot>
        <slot name="icon" :item="item">
          <span v-if="item.icon" :class="iconClass(item)" />
        </slot>
        <span v-if="item.emoji" class="flex-shrink-0">{{ item.emoji }}</span>
        <slot name="label" :item="item">
          <span
            v-if="item.label"
            class="min-w-0 truncate font-normal"
            :class="labelClass"
          >
            {{ item.label }}
          </span>
        </slot>
        <slot name="trailing-icon" :item="item" />
      </button>
      <div
        v-if="sectionIndex < filteredMenuSections.length - 1"
        :class="DROPDOWN_MENU_SEPARATOR_CLASS"
      />
    </template>
  </template>
  <template v-else>
    <div v-if="isLoading" class="flex items-center justify-center py-2">
      <Spinner :size="24" />
    </div>
    <button
      v-for="(item, index) in filteredMenuItems"
      :key="index"
      type="button"
      :class="itemClass(item)"
      :disabled="item.disabled"
      @click="handleAction(item)"
    >
      <slot name="thumbnail" :item="item">
        <Avatar
          v-if="item.thumbnail"
          :name="item.thumbnail.name"
          :src="item.thumbnail.src"
          :size="thumbnailSize"
          :rounded-full="roundedThumbnail"
        />
      </slot>
      <slot name="icon" :item="item">
        <span v-if="item.icon" :class="iconClass(item)" />
      </slot>
      <span v-if="item.emoji" class="flex-shrink-0">{{ item.emoji }}</span>
      <slot name="label" :item="item">
        <span
          v-if="item.label"
          class="min-w-0 truncate font-normal"
          :class="labelClass"
        >
          {{ item.label }}
        </span>
      </slot>
      <slot name="trailing-icon" :item="item" />
    </button>
  </template>

  <div
    v-if="shouldShowEmptyState"
    class="px-2 py-1.5 text-sm text-muted-foreground"
  >
    {{
      isSearching
        ? t('DROPDOWN_MENU.SEARCHING')
        : searchQuery
          ? t('DROPDOWN_MENU.EMPTY_STATE')
          : t(emptyStateMessage)
    }}
  </div>

  <div v-if="$slots.footer" class="border-t border-border pt-1">
    <slot name="footer" />
  </div>
</template>
