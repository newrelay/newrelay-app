<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  DROPDOWN_MENU_SEARCH_HEADER_CLASS,
  DROPDOWN_MENU_SEARCH_ICON_CLASS,
  DROPDOWN_MENU_SEARCH_INPUT_CLASS,
  DROPDOWN_MENU_SEARCH_WRAPPER_CLASS,
} from 'dashboard/components-next/relay/dropdown-menu/constants';

const props = defineProps({
  open: {
    type: Boolean,
    required: true,
  },
  options: {
    type: Array,
    required: true,
  },
  searchPlaceholder: {
    type: String,
    default: '',
  },
  emptyState: {
    type: String,
    default: '',
  },
  multiple: {
    type: Boolean,
    default: false,
  },
  selectedValues: {
    type: [String, Number, Array],
    default: () => [],
  },
});

const emit = defineEmits(['select', 'search']);

const { t } = useI18n();

const searchValue = defineModel('searchValue', {
  type: String,
  default: '',
});

const searchInput = ref(null);

const isSelected = option => {
  if (Array.isArray(props.selectedValues)) {
    return props.selectedValues.includes(option.value);
  }
  return option.value === props.selectedValues;
};

const onInputSearch = event => {
  searchValue.value = event.target.value;
  emit('search', event.target.value);
};

defineExpose({
  focus: () => searchInput.value?.focus(),
});
</script>

<template>
  <div
    v-show="open"
    class="absolute z-50 mt-1 w-full overflow-hidden rounded-md border border-border bg-popover text-popover-foreground shadow-md"
  >
    <div :class="DROPDOWN_MENU_SEARCH_HEADER_CLASS">
      <div :class="DROPDOWN_MENU_SEARCH_WRAPPER_CLASS">
        <span :class="DROPDOWN_MENU_SEARCH_ICON_CLASS" />
        <input
          ref="searchInput"
          :value="searchValue"
          type="search"
          :placeholder="searchPlaceholder || t('COMBOBOX.SEARCH_PLACEHOLDER')"
          :class="DROPDOWN_MENU_SEARCH_INPUT_CLASS"
          @input="onInputSearch"
        />
      </div>
    </div>
    <ul
      class="py-1 mb-0 overflow-auto max-h-60"
      role="listbox"
      :aria-multiselectable="multiple"
    >
      <li
        v-for="(option, index) in options"
        :key="`${option.value}-${index}`"
        class="flex w-full cursor-pointer items-center justify-between gap-2 px-3 py-2 text-[14px] transition-colors duration-150 hover:bg-accent"
        :class="{
          'bg-accent': isSelected(option),
        }"
        role="option"
        :aria-selected="isSelected(option)"
        @click="emit('select', option)"
      >
        <span
          :class="{
            'font-medium': isSelected(option),
          }"
          class="text-foreground"
        >
          {{ option.label }}
        </span>
        <span
          v-if="isSelected(option)"
          class="flex-shrink-0 i-lucide-check size-4 text-muted-foreground"
        />
      </li>
      <li
        v-if="options.length === 0"
        class="px-3 py-2 text-[14px] text-muted-foreground"
      >
        {{ emptyState || t('COMBOBOX.EMPTY_STATE') }}
      </li>
    </ul>
  </div>
</template>
