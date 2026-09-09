<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import { RELAY_DIALOG_OVERLAY_CLASS } from 'dashboard/components-next/relay/modal/constants';

defineProps({
  open: { type: Boolean, default: false },
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['update:open', 'import']);
const { t } = useI18n();
const fileInput = ref(null);
const selectedFile = ref(null);

const close = () => {
  selectedFile.value = null;
  if (fileInput.value) {
    fileInput.value.value = null;
  }
  emit('update:open', false);
};

const onDropzoneClick = () => fileInput.value?.click();

const onFileChange = () => {
  selectedFile.value = fileInput.value?.files?.[0] || null;
};

const onFileDrop = event => {
  const file = event.dataTransfer?.files?.[0];
  if (file) selectedFile.value = file;
};

const onUploadClick = () => {
  if (!selectedFile.value) return;
  emit('import', selectedFile.value);
};
</script>

<template>
  <TeleportWithDirection to="body">
    <div
      v-if="open"
      class="flex items-center justify-center p-4 transition-all duration-300"
      :class="[RELAY_DIALOG_OVERLAY_CLASS]"
      @click.self="close"
    >
      <div
        data-relay
        class="relative w-full max-w-md overflow-hidden rounded-xl border border-border bg-card shadow-2xl"
        @click.stop
      >
        <div class="p-6">
          <div class="mb-4 flex items-center justify-between">
            <h2 class="text-lg font-semibold tracking-tight text-foreground">
              {{ t('COMPANIES.IMPORT.TITLE') }}
            </h2>
            <button
              type="button"
              class="flex size-8 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
              @click="close"
            >
              <span class="i-lucide-x size-4" />
            </button>
          </div>
          <p class="mb-6 text-sm text-muted-foreground">
            {{ t('COMPANIES.IMPORT.DESCRIPTION') }}
          </p>

          <button
            type="button"
            class="flex w-full cursor-pointer flex-col items-center justify-center rounded-lg border-2 border-dashed border-muted-foreground/20 p-10 text-center transition-colors hover:bg-muted/50"
            @click="onDropzoneClick"
            @dragover.prevent
            @drop.prevent="onFileDrop"
          >
            <span
              :class="
                selectedFile
                  ? 'i-lucide-file-spreadsheet text-primary'
                  : 'i-lucide-upload text-muted-foreground'
              "
              class="mb-3 size-8"
            />
            <p class="mb-1 text-sm font-medium text-foreground">
              {{
                selectedFile
                  ? selectedFile.name
                  : t('COMPANIES.IMPORT.DROPZONE_TITLE')
              }}
            </p>
            <p class="text-xs text-muted-foreground">
              {{ t('COMPANIES.IMPORT.DROPZONE_HINT') }}
            </p>
          </button>
          <input
            ref="fileInput"
            type="file"
            class="hidden"
            accept=".csv,text/csv"
            @change="onFileChange"
          />
        </div>
        <div
          class="flex justify-end gap-2 border-t border-border bg-muted/50 p-4"
        >
          <RelayButton variant="outline" @click="close">
            {{ t('COMPANIES.IMPORT.CANCEL') }}
          </RelayButton>
          <RelayButton
            :disabled="!selectedFile || isLoading"
            @click="onUploadClick"
          >
            {{ t('COMPANIES.IMPORT.UPLOAD') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </TeleportWithDirection>
</template>
