<script setup>
import { computed, ref } from 'vue';
import { useMapGetter } from 'dashboard/composables/store.js';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import LocaleList from 'dashboard/components-next/HelpCenter/Pages/LocalePage/LocaleList.vue';
import AddLocaleDialog from 'dashboard/components-next/HelpCenter/Pages/LocalePage/AddLocaleDialog.vue';

const props = defineProps({
  locales: {
    type: Array,
    required: true,
  },
  portal: {
    type: Object,
    default: () => ({}),
  },
});

const addLocaleDialogRef = ref(null);

const isSwitchingPortal = useMapGetter('portals/isSwitchingPortal');

const openAddLocaleDialog = () => {
  addLocaleDialogRef.value.dialogRef.open();
};

const localeCount = computed(() => props.locales?.length);
</script>

<template>
  <HelpCenterLayout :show-pagination-footer="false">
    <template #header-actions>
      <div class="flex items-center justify-between gap-4">
        <span class="text-[13px] text-muted-foreground">
          {{ $t('HELP_CENTER.LOCALES_PAGE.LOCALES_COUNT', localeCount) }}
        </span>
        <RelayButton
          class="h-9 shrink-0 shadow-xs"
          @click="openAddLocaleDialog"
        >
          <span class="i-lucide-plus size-4" aria-hidden="true" />
          {{ $t('HELP_CENTER.LOCALES_PAGE.NEW_LOCALE_BUTTON_TEXT') }}
        </RelayButton>
      </div>
    </template>
    <template #content>
      <div
        v-if="isSwitchingPortal"
        class="flex items-center justify-center py-10 text-muted-foreground"
      >
        <Spinner />
      </div>
      <LocaleList v-else :locales="locales" :portal="portal" />
    </template>
    <AddLocaleDialog ref="addLocaleDialogRef" :portal="portal" />
  </HelpCenterLayout>
</template>
