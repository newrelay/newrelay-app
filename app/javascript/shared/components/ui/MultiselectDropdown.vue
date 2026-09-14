<script setup>
import { computed, ref } from 'vue';
import {
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
} from 'dashboard/components-next/relay';
import {
  DROPDOWN_MENU_MODAL_SEARCHABLE_CONTENT_CLASS,
  DROPDOWN_MENU_MODAL_SEARCHABLE_LIST_CLASS,
} from 'dashboard/components-next/relay/dropdown-menu/constants';
import { removeEmoji } from 'shared/helpers/emoji';
import Avatar from 'next/avatar/Avatar.vue';
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

const isOpen = ref(false);

const onClickSelectItem = value => {
  emit('select', value);
  isOpen.value = false;
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

const selectedFallbackIcon = computed(() => {
  const name = props.selectedItem?.name || '';
  const stripped = removeEmoji(name);
  if (stripped && stripped !== name.trim() && !props.selectedItem?.icon) {
    return 'i-lucide-users';
  }
  return '';
});

const selectedIconClass = computed(() => {
  return props.selectedItem?.iconClass || 'text-muted-foreground';
});

const displayLabel = computed(() => {
  if (hasValue.value) {
    return removeEmoji(props.selectedItem.name) || props.selectedItem.name;
  }
  return props.multiselectorPlaceholder;
});
</script>

<template>
  <div class="w-full">
    <RelayDropdownMenu v-model:open="isOpen">
      <RelayDropdownMenuTrigger as-child>
        <button
          type="button"
          class="box-border flex w-full min-w-0 items-center justify-between rounded-lg border border-border/60 bg-transparent px-2.5 py-1.5 text-left transition-colors hover:bg-accent focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary"
          :aria-label="multiselectorTitle || undefined"
        >
          <div class="flex min-w-0 flex-1 items-center gap-2">
            <Avatar
              v-if="
                hasValue && hasThumbnail && !hasIcon && !selectedFallbackIcon
              "
              :src="selectedItem.thumbnail"
              :status="selectedItem.availability_status"
              :name="displayLabel"
              :size="16"
              rounded-full
            />
            <span
              v-if="hasValue && (hasIcon || selectedFallbackIcon)"
              class="size-3.5 shrink-0"
              :class="[
                selectedItem.icon || selectedFallbackIcon,
                selectedIconClass,
              ]"
            />
            <span
              class="truncate text-[13px]"
              :class="hasValue ? 'text-foreground' : 'text-muted-foreground'"
              :title="displayLabel"
            >
              {{ displayLabel }}
            </span>
          </div>
          <span
            class="size-3 shrink-0 text-muted-foreground"
            :class="isOpen ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
          />
        </button>
      </RelayDropdownMenuTrigger>
      <RelayDropdownMenuContent
        align="start"
        :side-offset="4"
        :class="DROPDOWN_MENU_MODAL_SEARCHABLE_CONTENT_CLASS"
      >
        <div :class="DROPDOWN_MENU_MODAL_SEARCHABLE_LIST_CLASS">
          <MultiselectDropdownItems
            :options="options"
            :selected-items="[selectedItem]"
            :input-placeholder="inputPlaceholder"
            :no-search-result="noSearchResult"
            @select="onClickSelectItem"
          />
        </div>
      </RelayDropdownMenuContent>
    </RelayDropdownMenu>
  </div>
</template>
