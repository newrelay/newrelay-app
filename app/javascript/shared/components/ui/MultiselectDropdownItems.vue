<script>
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

export default {
  components: {
    Avatar,
    Icon,
  },

  props: {
    options: {
      type: Array,
      default: () => [],
    },
    selectedItems: {
      type: Array,
      default: () => [],
    },
    hasThumbnail: {
      type: Boolean,
      default: true,
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
      return this.options.filter(option => {
        return option.name.toLowerCase().includes(this.search.toLowerCase());
      });
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
    <div class="flex-auto flex-grow-0 flex-shrink-0 mb-2 max-h-8">
      <input
        ref="searchbar"
        v-model="search"
        type="text"
        class="m-0 w-full h-8 px-2.5 text-[13px] text-foreground rounded-md border border-border/80 bg-background shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
        autofocus="true"
        :placeholder="inputPlaceholder"
      />
    </div>
    <div class="flex items-start justify-start flex-auto overflow-auto mt-2">
      <div class="w-full max-h-[10rem]">
        <ul class="flex flex-col gap-0.5 m-0 p-0 list-none">
          <li v-for="option in filteredOptions" :key="option.id">
            <button
              type="button"
              class="flex items-center justify-between w-full min-w-0 gap-2 px-2 py-1.5 text-[13px] rounded-md text-left transition-colors hover:bg-accent hover:text-accent-foreground"
              :class="isActive(option) ? 'bg-accent/50 text-accent-foreground' : 'text-foreground'"
              @click="() => onclick(option)"
            >
              <span
                class="my-0 overflow-hidden leading-4 whitespace-nowrap text-ellipsis"
                :title="option.name"
              >
                {{ option.name }}
              </span>
              <span class="flex items-center gap-2 shrink-0">
                <Avatar
                  v-if="hasThumbnail && !option.icon"
                  :src="option.thumbnail"
                  :name="option.name"
                  :status="option.availability_status"
                  :size="24"
                  hide-offline-status
                  rounded-full
                />
                <Icon
                  v-if="option.icon"
                  :icon="option.icon"
                  class="size-5 text-muted-foreground"
                />
                <span
                  v-if="isActive(option)"
                  class="i-lucide-check size-4 text-primary shrink-0"
                />
              </span>
            </button>
          </li>
        </ul>
        <p
          v-if="noResult"
          class="w-full justify-center items-center flex text-muted-foreground py-2 px-2.5 overflow-hidden whitespace-nowrap text-ellipsis text-[13px] m-0"
        >
          {{ noSearchResult }}
        </p>
      </div>
    </div>
  </div>
</template>
