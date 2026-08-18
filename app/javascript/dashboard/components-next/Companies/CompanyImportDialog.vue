<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { RelayButton } from 'dashboard/components-next/relay';
import {
  RELAY_DIALOG_OVERLAY_CLASS,
  RELAY_MODAL_BODY_CLASS,
} from 'dashboard/components-next/relay/modal/constants';
import RelayModalHeader from 'dashboard/components-next/relay/modal/RelayModalHeader.vue';

defineProps({
  open: { type: Boolean, default: false },
});

const emit = defineEmits(['update:open']);
const { t } = useI18n();
const fileInput = ref(null);

const close = () => emit('update:open', false);

const onUploadClick = () => {
  useAlert(t('COMPANIES.IMPORT.UNAVAILABLE'));
};
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      data-relay
      class="flex items-center justify-center transition-all duration-300"
      :class="[RELAY_DIALOG_OVERLAY_CLASS]"
      @click.self="close"
    >
      <div
        class="relative flex w-full max-w-md flex-col overflow-hidden rounded-xl border border-border bg-card shadow-2xl"
      >
        <RelayModalHeader
          :title="t('COMPANIES.IMPORT.TITLE')"
          :description="t('COMPANIES.IMPORT.DESCRIPTION')"
          @close="close"
        />

        <div :class="RELAY_MODAL_BODY_CLASS">
          <button
            type="button"
            class="flex w-full cursor-pointer flex-col items-center justify-center rounded-lg border-2 border-dashed border-muted-foreground/20 p-10 text-center transition-colors hover:bg-muted/50"
            @click="onUploadClick"
          >
            <span class="i-lucide-upload mb-3 size-8 text-muted-foreground" />
            <p class="mb-1 text-sm font-medium text-foreground">
              {{ t('COMPANIES.IMPORT.DROPZONE_TITLE') }}
            </p>
            <p class="text-xs text-muted-foreground">
              {{ t('COMPANIES.IMPORT.DROPZONE_HINT') }}
            </p>
          </button>
          <input
            ref="fileInput"
            type="file"
            class="hidden text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
            accept=".csv,.xlsx,.xls"
          />
        </div>
        <div
          class="flex justify-end gap-2 border-t border-border bg-muted/50 p-4"
        >
          <RelayButton variant="outline" @click="close">
            {{ t('COMPANIES.IMPORT.CANCEL') }}
          </RelayButton>
          <RelayButton disabled>
            {{ t('COMPANIES.IMPORT.UPLOAD') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </Teleport>
</template>
