<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

defineProps({
  labelMenuItems: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['updateLabel']);

const { t } = useI18n();

const showDropdown = ref(false);
</script>

<template>
  <div class="relative">
    <button
      type="button"
      class="reset-base flex w-fit cursor-pointer items-center gap-1.5 text-[12px] font-medium text-primary transition-colors hover:text-primary/80"
      @click="showDropdown = !showDropdown"
    >
      <span class="i-lucide-plus size-3.5" />
      {{ t('LABEL.TAG_BUTTON') }}
    </button>
    <DropdownMenu
      v-if="showDropdown"
      v-on-clickaway="() => (showDropdown = false)"
      :menu-items="labelMenuItems"
      show-search
      class="z-[100] w-48 mt-2 ltr:left-0 rtl:right-0 top-full max-h-52"
      @action="emit('updateLabel', $event)"
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
