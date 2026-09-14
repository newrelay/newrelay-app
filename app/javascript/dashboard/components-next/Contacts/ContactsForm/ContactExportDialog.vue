<script setup>
import { ref, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';

import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import { RELAY_DIALOG_OVERLAY_CLASS } from 'dashboard/components-next/relay/modal/constants';

const emit = defineEmits(['export']);

const { t } = useI18n();
const route = useRoute();

const isOpen = ref(false);

const dialogRef = {
  open: () => {
    isOpen.value = true;
  },
  close: () => {
    isOpen.value = false;
  },
};

const segments = useMapGetter('customViews/getContactCustomViews');
const appliedFilters = useMapGetter('contacts/getAppliedContactFilters');
const uiFlags = useMapGetter('contacts/getUIFlags');
const isExportingContact = computed(() => uiFlags.value.isExporting);

const activeSegmentId = computed(() => route.params.segmentId);
const activeSegment = computed(() =>
  activeSegmentId.value
    ? segments.value.find(view => view.id === Number(activeSegmentId.value))
    : undefined
);

const exportContacts = async () => {
  let query = { payload: [] };

  if (activeSegmentId.value && activeSegment.value) {
    query = activeSegment.value.query;
  } else if (Object.keys(appliedFilters.value).length > 0) {
    query = filterQueryGenerator(appliedFilters.value);
  }

  emit('export', {
    ...query,
    label: route.params.label || '',
  });
};

const handleExport = async () => {
  await exportContacts();
  dialogRef.close();
};

defineExpose({ dialogRef });
</script>

<template>
  <TeleportWithDirection to="body">
    <div
      v-if="isOpen"
      class="flex items-center justify-center p-4"
      :class="[RELAY_DIALOG_OVERLAY_CLASS]"
      @click.self="dialogRef.close()"
    >
      <div
        data-relay
        class="mx-4 flex w-full max-w-[400px] flex-col rounded-xl border border-border/80 bg-background p-6 shadow-xl"
        @click.stop
      >
        <div class="flex flex-col">
          <h2 class="text-[18px] font-semibold tracking-tight text-foreground">
            {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.TITLE') }}
          </h2>
          <p
            class="mb-6 mt-1.5 text-[14px] font-normal leading-relaxed text-muted-foreground"
          >
            {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.DESCRIPTION') }}
          </p>
        </div>

        <div class="flex gap-3">
          <RelayButton
            type="button"
            variant="outline"
            class="h-10 flex-1 rounded-[10px] border border-border bg-background text-[14px] font-medium shadow-sm hover:border-transparent"
            @click="dialogRef.close()"
          >
            {{ t('DIALOG.BUTTONS.CANCEL') }}
          </RelayButton>
          <RelayButton
            type="button"
            class="h-10 flex-1 rounded-[10px] bg-primary text-[14px] font-medium text-primary-foreground shadow-sm hover:bg-primary/90"
            :disabled="isExportingContact"
            @click="handleExport"
          >
            {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.CONFIRM') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </TeleportWithDirection>
</template>
