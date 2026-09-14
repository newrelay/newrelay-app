<script>
import {
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';

export default {
  components: {
    RelayDropdownMenu,
    RelayDropdownMenuTrigger,
    RelayDropdownMenuContent,
    RelayDropdownMenuItem,
  },
  props: {
    selectedValue: {
      type: String,
      required: true,
    },
    items: {
      type: Array,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
    pathPrefix: {
      type: String,
      required: true,
    },
  },
  emits: ['onChangeFilter'],
  data() {
    return {
      activeValue: this.selectedValue,
    };
  },
  methods: {
    onTabChange(value) {
      this.activeValue = value;
      if (this.type === 'status') {
        this.$store.dispatch('setChatStatusFilter', this.activeValue);
      } else {
        this.$store.dispatch('setChatSortFilter', this.activeValue);
      }
      this.$emit('onChangeFilter', this.activeValue, this.type);
    },
  },
};
</script>

<template>
  <RelayDropdownMenu>
    <RelayDropdownMenuTrigger as-child>
      <button
        type="button"
        class="w-32 h-9 mx-1 flex items-center justify-between rounded-md border border-input bg-background px-3 text-xs text-foreground shadow-sm transition-colors hover:bg-accent focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
      >
        <span class="truncate">{{
          $t(`${pathPrefix}.${activeValue}.TEXT`)
        }}</span>
        <span
          class="i-lucide-chevron-down size-3.5 shrink-0 text-muted-foreground"
        />
      </button>
    </RelayDropdownMenuTrigger>
    <RelayDropdownMenuContent
      align="start"
      class="w-[--reka-dropdown-menu-trigger-width]"
    >
      <RelayDropdownMenuItem
        v-for="value in items"
        :key="value"
        class="flex cursor-pointer items-center justify-between"
        @click="onTabChange(value)"
      >
        <span>{{ $t(`${pathPrefix}.${value}.TEXT`) }}</span>
        <span
          v-if="activeValue === value"
          class="i-lucide-check size-3.5 text-primary"
        />
      </RelayDropdownMenuItem>
    </RelayDropdownMenuContent>
  </RelayDropdownMenu>
</template>
