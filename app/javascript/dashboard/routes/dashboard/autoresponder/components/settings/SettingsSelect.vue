<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
  DROPDOWN_MENU_SEARCH_HEADER_CLASS,
  DROPDOWN_MENU_SEARCH_WRAPPER_CLASS,
  DROPDOWN_MENU_SEARCH_ICON_CLASS,
  DROPDOWN_MENU_SEARCH_INPUT_CLASS,
} from 'dashboard/components-next/relay';

const props = defineProps({
  modelValue: { type: String, default: '' },
  options: { type: Array, default: () => [] },
  searchable: { type: Boolean, default: false },
  searchPlaceholder: { type: String, default: '' },
});

const emit = defineEmits(['update:modelValue']);
const { t } = useI18n();

const open = ref(false);
const searchQuery = ref('');

function optionValue(opt) {
  return opt && typeof opt === 'object' ? opt.value : opt;
}

function optionLabel(opt) {
  return opt && typeof opt === 'object' ? opt.label : opt;
}

function optionSearchText(opt) {
  if (opt && typeof opt === 'object') {
    return `${opt.label || ''} ${opt.searchText || ''}`.trim();
  }
  return String(opt || '');
}

const selectedLabel = computed(() => {
  const match = props.options.find(
    opt => optionValue(opt) === props.modelValue
  );
  return match ? optionLabel(match) : props.modelValue;
});

const filteredOptions = computed(() => {
  if (!props.searchable || !searchQuery.value.trim()) return props.options;
  const query = searchQuery.value.toLowerCase();
  return props.options.filter(opt =>
    optionSearchText(opt).toLowerCase().includes(query)
  );
});

watch(open, isOpen => {
  if (!isOpen) searchQuery.value = '';
});
</script>

<template>
  <RelayDropdownMenu v-model:open="open">
    <RelayDropdownMenuTrigger as-child>
      <button
        type="button"
        class="w-full h-9 rounded-md border border-input bg-background px-3 text-[14px] shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 text-left flex items-center justify-between transition-colors hover:bg-accent cursor-pointer text-foreground"
      >
        <span class="truncate">{{ selectedLabel }}</span>
        <span
          class="i-lucide-chevron-down size-4 text-muted-foreground shrink-0"
        />
      </button>
    </RelayDropdownMenuTrigger>
    <RelayDropdownMenuContent
      align="start"
      :class="
        searchable
          ? 'flex max-h-72 w-[--reka-dropdown-menu-trigger-width] flex-col overflow-hidden p-0'
          : 'w-[--reka-dropdown-menu-trigger-width]'
      "
    >
      <div v-if="searchable" :class="DROPDOWN_MENU_SEARCH_HEADER_CLASS">
        <div :class="DROPDOWN_MENU_SEARCH_WRAPPER_CLASS">
          <span :class="DROPDOWN_MENU_SEARCH_ICON_CLASS" />
          <input
            v-model="searchQuery"
            type="search"
            :placeholder="
              searchPlaceholder || t('DROPDOWN_MENU.SEARCH_PLACEHOLDER')
            "
            :class="DROPDOWN_MENU_SEARCH_INPUT_CLASS"
            @keydown.stop
            @click.stop
          />
        </div>
      </div>
      <div :class="searchable ? 'min-h-0 flex-1 overflow-y-auto p-1' : ''">
        <RelayDropdownMenuItem
          v-for="opt in filteredOptions"
          :key="optionValue(opt)"
          class="flex items-center justify-between cursor-pointer"
          @click="emit('update:modelValue', optionValue(opt))"
        >
          <span>{{ optionLabel(opt) }}</span>
          <span
            v-if="modelValue === optionValue(opt)"
            class="i-lucide-check size-3.5 text-primary"
          />
        </RelayDropdownMenuItem>
        <div
          v-if="searchable && !filteredOptions.length"
          class="px-2 py-1.5 text-sm text-muted-foreground"
        >
          {{ t('DROPDOWN_MENU.EMPTY_STATE') }}
        </div>
      </div>
    </RelayDropdownMenuContent>
  </RelayDropdownMenu>
</template>
