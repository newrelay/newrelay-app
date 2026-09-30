<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { onClickOutside } from '@vueuse/core';

import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { RelayInput } from 'dashboard/components-next/relay';

const props = defineProps({
  labelMenuItems: {
    type: Array,
    default: () => [],
  },
  inline: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['updateLabel']);

const { t } = useI18n();

const rootRef = ref(null);
const showDropdown = ref(false);
const searchQuery = ref('');

const filteredMenuItems = computed(() => {
  const items = props.labelMenuItems || [];
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return items;
  return items.filter(item => item.label.toLowerCase().includes(query));
});

const close = () => {
  showDropdown.value = false;
  searchQuery.value = '';
};

const toggle = () => {
  if (showDropdown.value) close();
  else showDropdown.value = true;
};

const selectLabel = item => {
  emit('updateLabel', item);
  close();
};

const selectFirstResult = () => {
  if (filteredMenuItems.value.length) {
    selectLabel(filteredMenuItems.value[0]);
  }
};

onClickOutside(rootRef, () => {
  if (showDropdown.value) close();
});
</script>

<template>
  <div
    ref="rootRef"
    class="relative"
    :class="{ 'mt-3 w-full basis-full': inline && showDropdown }"
  >
    <button
      type="button"
      class="reset-base flex w-fit cursor-pointer items-center gap-1.5 text-[12px] font-medium text-primary transition-colors hover:text-primary/80"
      @click.stop="toggle"
    >
      <span class="i-lucide-plus size-3.5" />
      {{
        inline
          ? t('CONTACTS_LAYOUT.DETAIL.ABOUT.ADD_TAG')
          : t('LABEL.TAG_BUTTON')
      }}
    </button>
    <div v-if="inline && showDropdown" class="mt-2 flex w-full flex-col gap-2">
      <RelayInput
        v-model="searchQuery"
        autofocus
        :placeholder="t('CONTACTS_LAYOUT.DETAIL.ABOUT.TAG_PLACEHOLDER')"
        class-name="h-9 border-primary/30"
        @keyup.enter="selectFirstResult"
        @click.stop
      />
      <div
        class="max-h-52 overflow-y-auto rounded-md border border-border bg-popover p-1 shadow-md"
      >
        <button
          v-for="item in filteredMenuItems"
          :key="item.value"
          type="button"
          class="flex w-full items-center gap-2 rounded-sm px-2 py-1.5 text-left text-sm text-foreground hover:bg-accent"
          @click.stop="selectLabel(item)"
        >
          <span
            class="size-2 shrink-0 rounded-sm"
            :style="{ backgroundColor: item.thumbnail?.color }"
          />
          <span class="min-w-0 truncate">{{ item.label }}</span>
        </button>
        <p
          v-if="!filteredMenuItems.length"
          class="px-2 py-1.5 text-sm text-muted-foreground"
        >
          {{ t('DROPDOWN_MENU.EMPTY_STATE') }}
        </p>
      </div>
    </div>
    <DropdownMenu
      v-else-if="showDropdown"
      :menu-items="labelMenuItems"
      show-search
      class="z-[100] mt-2 w-48 ltr:left-0 rtl:right-0 top-full max-h-52"
      @action="selectLabel"
    >
      <template #thumbnail="{ item }">
        <div
          class="rounded-sm size-2"
          :style="{ backgroundColor: item.thumbnail.color }"
        />
      </template>
    </DropdownMenu>
  </div>
</template>
