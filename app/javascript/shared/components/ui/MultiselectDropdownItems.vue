<script>
import { removeEmoji } from 'shared/helpers/emoji';
import {
  DROPDOWN_MENU_SEARCH_HEADER_CLASS,
  DROPDOWN_MENU_SEARCH_WRAPPER_CLASS,
  DROPDOWN_MENU_SEARCH_ICON_CLASS,
  DROPDOWN_MENU_SEARCH_INPUT_CLASS,
} from 'dashboard/components-next/relay/dropdown-menu/constants';

export default {
  props: {
    options: {
      type: Array,
      default: () => [],
    },
    selectedItems: {
      type: Array,
    },
    inputPlaceholder: {
      type: String,
      default: 'Search',
    },
    noSearchResult: {
      type: String,
      default: 'No results found',
    },
  },
  emits: ['select'],
  setup() {
    return {
      DROPDOWN_MENU_SEARCH_HEADER_CLASS,
      DROPDOWN_MENU_SEARCH_WRAPPER_CLASS,
      DROPDOWN_MENU_SEARCH_ICON_CLASS,
      DROPDOWN_MENU_SEARCH_INPUT_CLASS,
    };
  },

  data() {
    return {
      search: '',
    };
  },

  computed: {
    filteredOptions() {
      return this.options
        .map(option => {
          const displayName = removeEmoji(option.name || '') || option.name;
          const hadEmoji =
            displayName !== (option.name || '').trim() && !option.icon;
          return {
            ...option,
            displayName,
            fallbackIcon: hadEmoji ? 'i-lucide-users' : '',
          };
        })
        .filter(option =>
          option.displayName.toLowerCase().includes(this.search.toLowerCase())
        );
    },
    noResult() {
      return this.filteredOptions.length === 0 && this.search !== '';
    },
  },

  mounted() {
    this.focusInput();
  },

  methods: {
    onclick(option) {
      this.$emit('select', option);
    },
    focusInput() {
      this.$refs.searchbar.focus();
    },
    isActive(option) {
      return this.selectedItems.some(item => item && option.id === item.id);
    },
  },
};
</script>

<template>
  <div class="w-full flex flex-col max-h-[12.5rem]">
    <div :class="DROPDOWN_MENU_SEARCH_HEADER_CLASS">
      <div :class="DROPDOWN_MENU_SEARCH_WRAPPER_CLASS">
        <span :class="DROPDOWN_MENU_SEARCH_ICON_CLASS" />
        <input
          ref="searchbar"
          v-model="search"
          type="text"
          data-slot="input"
          :class="DROPDOWN_MENU_SEARCH_INPUT_CLASS"
          autofocus="true"
          :placeholder="inputPlaceholder"
        />
      </div>
    </div>
    <div class="flex items-start justify-start flex-auto overflow-auto">
      <div class="w-full max-h-[10rem]">
        <ul class="flex flex-col gap-0.5 m-0 p-0 list-none">
          <li v-for="option in filteredOptions" :key="option.id">
            <button
              type="button"
              class="flex w-full min-w-0 items-center justify-between gap-2 rounded-sm px-2 py-1.5 text-left text-[14px] transition-colors"
              :class="
                isActive(option)
                  ? 'bg-accent text-accent-foreground'
                  : 'text-foreground hover:bg-accent hover:text-accent-foreground'
              "
              @click="() => onclick(option)"
            >
              <span class="flex min-w-0 items-center gap-1.5">
                <span
                  v-if="option.icon || option.fallbackIcon"
                  class="size-3.5 shrink-0"
                  :class="[
                    option.icon || option.fallbackIcon,
                    option.iconClass || 'text-muted-foreground',
                  ]"
                />
                <span
                  class="my-0 overflow-hidden leading-4 whitespace-nowrap text-ellipsis"
                  :title="option.displayName"
                >
                  {{ option.displayName }}
                </span>
              </span>
              <span
                v-if="isActive(option)"
                class="i-lucide-check size-3 shrink-0 text-foreground"
              />
            </button>
          </li>
        </ul>
        <p
          v-if="noResult"
          class="w-full justify-center items-center flex text-muted-foreground py-2 px-2.5 overflow-hidden whitespace-nowrap text-ellipsis text-sm m-0"
        >
          {{ noSearchResult }}
        </p>
      </div>
    </div>
  </div>
</template>
