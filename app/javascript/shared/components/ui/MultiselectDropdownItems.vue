<script>
import { removeEmoji } from 'shared/helpers/emoji';

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
    <div class="mb-1 px-0.5">
      <input
        ref="searchbar"
        v-model="search"
        type="search"
        class="reset-base no-margin m-0 box-border h-8 w-full max-w-full rounded-md border border-border/80 bg-background px-2.5 py-0 text-[13px] leading-none text-foreground shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
        autofocus="true"
        :placeholder="inputPlaceholder"
      />
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
