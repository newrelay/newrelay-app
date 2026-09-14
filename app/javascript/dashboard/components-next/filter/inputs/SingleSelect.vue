<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { picoSearch } from '@scmmishra/pico-search';
import Icon from 'next/icon/Icon.vue';
import Button from 'next/button/Button.vue';
import DropdownContainer from 'next/dropdown-menu/base/DropdownContainer.vue';
import DropdownSection from 'next/dropdown-menu/base/DropdownSection.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';
import { RELAY_FILTER_CLASS } from 'dashboard/components-next/relay/chrome/constants';

const {
  options,
  disableSearch,
  disableDeselect,
  placeholderIcon,
  placeholder,
  placeholderTrailingIcon,
  searchPlaceholder,
  dropdownMaxHeight,
  appearance,
} = defineProps({
  options: {
    type: Array,
    required: true,
  },
  disableSearch: {
    type: Boolean,
    default: false,
  },
  placeholderIcon: {
    type: String,
    default: 'i-lucide-plus',
  },
  placeholder: {
    type: String,
    default: '',
  },
  placeholderTrailingIcon: {
    type: Boolean,
    default: false,
  },
  searchPlaceholder: {
    type: String,
    default: '',
  },
  dropdownMaxHeight: {
    type: String,
    default: 'max-h-80',
  },
  disableDeselect: {
    type: Boolean,
    default: false,
  },
  appearance: {
    type: String,
    default: 'default',
    validator: value => ['default', 'field', 'fieldMuted'].includes(value),
  },
});

const isFieldAppearance = computed(() =>
  ['field', 'fieldMuted'].includes(appearance)
);

const fieldTriggerClass = computed(() =>
  appearance === 'fieldMuted'
    ? 'flex h-9 w-full items-center justify-between rounded-lg border border-border/50 bg-muted/40 px-3 text-[13px] font-normal outline-none transition-all hover:border-border hover:bg-accent focus:ring-1 focus:ring-primary/30'
    : 'flex h-9 w-full items-center justify-between rounded-lg border border-border/70 bg-background px-3 text-[13px] font-normal text-foreground shadow-xs outline-none transition-colors hover:bg-accent focus:ring-1 focus:ring-primary/30'
);

const { t } = useI18n();
const selected = defineModel({
  type: Object,
  required: true,
});

const searchTerm = ref('');
const searchResults = computed(() => {
  if (!options) return [];
  return picoSearch(options, searchTerm.value, ['name']);
});

const selectedItem = computed(() => {
  if (!options) return null;
  if (!selected.value) return null;

  // there are cases where the selected value is an array
  const optionToSearch = Array.isArray(selected.value)
    ? selected.value[0]
    : selected.value;

  if (!optionToSearch) return null;
  // extract the selected item from the options array
  // this ensures that options like icon is also included
  return options.find(option => option.id === optionToSearch.id);
});

const toggleSelected = option => {
  // Ensure that the `icon` prop is not included, icon is a VNode which has circular references
  // This causes an error when creating a clone using JSON.parse(JSON.stringify())
  const optionToToggle = {
    id: option.id,
    name: option.name,
  };

  if (selected.value && selected.value.id === optionToToggle.id) {
    if (!disableDeselect) selected.value = null;
  } else {
    selected.value = optionToToggle;
  }
};
</script>

<template>
  <DropdownContainer>
    <template #trigger="{ toggle }">
      <button
        v-if="isFieldAppearance"
        type="button"
        :class="fieldTriggerClass"
        @click="toggle"
      >
        <span
          class="truncate"
          :class="selectedItem ? 'text-foreground' : 'text-muted-foreground'"
        >
          {{ selectedItem?.name || placeholder || t('COMBOBOX.PLACEHOLDER') }}
        </span>
        <span
          class="i-lucide-chevron-down ml-2 size-3.5 shrink-0 text-muted-foreground"
          :class="appearance === 'fieldMuted' ? 'opacity-50' : 'opacity-60'"
        />
      </button>
      <Button
        v-else-if="selectedItem"
        sm
        slate
        faded
        type="button"
        :class="RELAY_FILTER_CLASS"
        :icon="selectedItem.icon"
        :label="selectedItem.name"
        @click="toggle"
      />
      <Button
        v-else
        sm
        slate
        faded
        type="button"
        :class="RELAY_FILTER_CLASS"
        :trailing-icon="placeholderTrailingIcon"
        @click="toggle"
      >
        <template #icon>
          <Icon :icon="placeholderIcon" class="text-muted-foreground" />
        </template>
        <span class="text-muted-foreground">{{
          placeholder || t('COMBOBOX.PLACEHOLDER')
        }}</span>
      </Button>
    </template>
    <DropdownBody
      class="z-50"
      :class="isFieldAppearance ? 'top-0 min-w-[320px]' : 'top-0 min-w-56'"
      :content-class="
        isFieldAppearance
          ? 'min-w-[320px] rounded-xl border-border/80 p-0 shadow-xl'
          : ''
      "
      strong
    >
      <div
        v-if="!disableSearch"
        class="relative"
        :class="
          isFieldAppearance ? 'border-b border-border/40 bg-muted/20 p-2' : ''
        "
      >
        <Icon
          :class="
            isFieldAppearance
              ? 'absolute left-4 top-1/2 size-3.5 -translate-y-1/2 text-muted-foreground'
              : 'absolute left-2 top-2 size-4'
          "
          icon="i-lucide-search"
        />
        <input
          v-model="searchTerm"
          autofocus
          :class="
            isFieldAppearance
              ? 'h-8 w-full border-none bg-transparent pl-8 pr-3 text-[13px] text-foreground outline-none placeholder:text-muted-foreground'
              : 'w-full rounded-md border-border/80 bg-muted bg-background p-1.5 pl-8 text-[14px] text-muted-foreground shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30'
          "
          :placeholder="searchPlaceholder || t('COMBOBOX.SEARCH_PLACEHOLDER')"
        />
      </div>
      <div :class="isFieldAppearance ? 'p-1.5' : ''">
        <DropdownSection :height="dropdownMaxHeight">
          <template v-if="searchResults.length">
            <DropdownItem
              v-for="option in searchResults"
              :key="option.id"
              :icon="option.icon"
              @click="toggleSelected(option)"
            >
              <template #label>
                {{ option.name }}
                <Icon
                  v-if="selectedItem && selectedItem.id === option.id"
                  icon="i-lucide-check"
                  class="bg-primary pointer-events-none"
                />
              </template>
            </DropdownItem>
          </template>
          <template v-else-if="searchTerm">
            <DropdownItem disabled>
              {{
                t('COMBOBOX.EMPTY_SEARCH_RESULTS', { searchTerm: searchTerm })
              }}
            </DropdownItem>
          </template>
          <template v-else>
            <DropdownItem disabled>
              {{ t('COMBOBOX.EMPTY_STATE') }}
            </DropdownItem>
          </template>
        </DropdownSection>
      </div>
    </DropdownBody>
  </DropdownContainer>
</template>
