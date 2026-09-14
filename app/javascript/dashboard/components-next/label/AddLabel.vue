<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

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

const showDropdown = ref(false);
const searchQuery = ref('');

const filteredMenuItems = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return [];
  return props.labelMenuItems.filter(item =>
    item.label.toLowerCase().includes(query)
  );
});

const close = () => {
  showDropdown.value = false;
  searchQuery.value = '';
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
</script>

<template>
  <div
    v-on-clickaway="close"
    class="relative"
    :class="{ 'mt-3 w-full basis-full': inline && showDropdown }"
  >
    <div v-if="inline && showDropdown" class="flex w-full items-center gap-3">
      <RelayInput
        v-model="searchQuery"
        autofocus
        :placeholder="t('CONTACTS_LAYOUT.DETAIL.ABOUT.TAG_PLACEHOLDER')"
        class-name="h-9 flex-1 border-primary/30"
        @keyup.enter="selectFirstResult"
      />
      <button
        type="button"
        class="reset-base shrink-0 text-[14px] font-medium text-foreground transition-colors hover:text-primary"
        @click="close"
      >
        {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.CANCEL') }}
      </button>
    </div>
    <button
      v-else
      type="button"
      class="reset-base flex w-fit cursor-pointer items-center gap-1.5 text-[12px] font-medium text-primary transition-colors hover:text-primary/80"
      @click="showDropdown = true"
    >
      <span class="i-lucide-plus size-3.5" />
      {{ t('LABEL.TAG_BUTTON') }}
    </button>
    <DropdownMenu
      v-if="showDropdown && (!inline || filteredMenuItems.length)"
      :menu-items="inline ? filteredMenuItems : labelMenuItems"
      :show-search="!inline"
      :class="
        inline
          ? 'z-[100] mt-2 w-[calc(100%_-_5rem)] ltr:left-0 rtl:right-0 top-full max-h-52'
          : 'z-[100] mt-2 w-48 ltr:left-0 rtl:right-0 top-full max-h-52'
      "
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
